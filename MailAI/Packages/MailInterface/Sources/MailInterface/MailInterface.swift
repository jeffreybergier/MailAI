//
// GPLv3 License Notice
//
// Copyright (c) 2025 Jeffrey Bergier
//
// This file is part of MailAI.
// MailAI is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
// MailAI is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with MailAI. If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI

// MARK: View

public struct MailInterfaceView: View {
  
  @State private var mail = MailInterface()
  @State private var selection: MessageForAnalysis?
  
  public init() { }
  
  public var body: some View {
    NavigationSplitView {
      List(self.mail.messages, selection:self.$selection) { message in
        VStack(alignment: .leading) {
          Text(message.subject)
            .font(.headline)
          Text(message.account + " • " + message.mailbox)
            .font(.subheadline)
        }
        .lineLimit(1)
        .tag(message)
      }
      .safeAreaInset(edge: .top) {
        HStack {
          switch self.mail.status {
          case .notStarted:
            Button("Count Selected Messages") {
              self.mail.step1_count()
            }
          case .counted(let messages):
            if messages == 0 {
              Text("No Messages Selected")
            } else {
              Button("Import: \(messages) messages") {
                self.mail.step2_import()
              }
            }
          case .importing(let completed, let total):
            ProgressView("Importing Messages", value: completed, total: total)
          case .imported(let count):
            Text("Imported: \(count) messages")
          case .error(let error):
            Text(String(describing: error))
          }
          Spacer()
          Button("Reset") {
            self.mail.reset()
          }
          .disabled(self.mail.status.isImporting)
        }
        .padding([.leading, .trailing])
      }
    } detail: {
      if let selection {
        ScrollView {
          Form {
            Button {
              NSWorkspace.shared.open(selection.url)
            } label: {
              Text(selection.subject)
                .font(.headline)
                .lineLimit(1)
            }
            .buttonStyle(.link)
            Divider()
            Text(selection.content)
            Divider()
            Text(selection.headers)
          }
          .padding()
          .font(.body)
        }
      }
    }
  }
}

// MARK: Controller

@MainActor
@Observable
public class MailInterface {
  
  public enum Status: Sendable {
    case notStarted
    case counted(Int)
    case importing(complete: Double, total: Double)
    case imported(Int)
    case error(AppleScriptError)
    public var isImporting: Bool {
      switch self {
      case .importing:
        return true
      default:
        return false
      }
    }
  }
  
  public var status = Status.notStarted
  public var messages = [MessageForAnalysis]()
  private var counterFilePresenter: CounterFilePresenter?
  
  public func step1_count() {
    do {
      let count = try NSAppleScript.try3_countSelectedMessages()
      self.status = .counted(count)
    } catch {
      self.status = .error(error)
    }
  }
  
  public func step2_import() {
    guard case .counted(let count) = self.status else { fatalError("Function used in wrong order") }
    self.prepareFilePresenter()
    self.status = .importing(complete: 0, total: Double(count))
    let scratchFile = self.counterFilePresenter!.presentedItemURL!
    Task {
      let task = Task.detached(priority: .userInitiated) {
        try NSAppleScript.try3_importSelectedMessages(updating: scratchFile)
      }
      do {
        let messages = try await task.value
        self.messages = messages
        self.status = .imported(messages.count)
      } catch let error as AppleScriptError {
        self.status = .error(error)
      }
      self.removeFilePresenter()
    }
  }
  
  public func reset() {
    self.messages = []
    self.status = .notStarted
    self.removeFilePresenter()
  }
  
  private func prepareFilePresenter() {
    let presenter = CounterFilePresenter() { [weak self] newValue in
      guard case .importing(_, let total) = self?.status else { return }
      self?.status = .importing(complete: Double(newValue), total: total)
    }
    self.counterFilePresenter = presenter
    NSFileCoordinator.addFilePresenter(presenter)
  }
  
  private func removeFilePresenter() {
    self.counterFilePresenter.map { NSFileCoordinator.removeFilePresenter($0) }
    self.counterFilePresenter = nil
  }
}

internal class CounterFilePresenter: NSObject, NSFilePresenter {
  
  internal var presentedItemOperationQueue = OperationQueue.main
  private let onUpdate: (Int) -> Void
  
  internal var presentedItemURL: URL? = {
    let fm = FileManager.default
    let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "com.saturdayapps.MailAI", directoryHint: .isDirectory)
    let file = folder.appending(path: UUID().uuidString + ".txt", directoryHint: .notDirectory)
    try! fm.createDirectory(at: folder, withIntermediateDirectories: true)
    fm.createFile(atPath: file.path, contents: nil)
    // #if DEBUG
    // NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: folder.path)
    // #endif
    return file
  }()
  
  internal init(onUpdate: @escaping (Int) -> Void) {
    self.onUpdate = onUpdate
    super.init()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.applicationWillTerminate(_:)),
                                           name: NSApplication.willTerminateNotification,
                                           object: nil)
  }
  
  func presentedItemDidChange() {
    NSFileCoordinator().coordinate(readingItemAt: self.presentedItemURL!, error: nil) { url in
      guard let data = try? Data(contentsOf: url) else {
        NSLog("[ERROR] No Data!")
        return
      }
      guard let string = String(data: data, encoding: .utf8) else {
        NSLog("[ERROR] No String!")
        return
      }
      guard let int = Int(string) else {
        NSLog("[ERROR] No Number!")
        return
      }
      self.onUpdate(int)
    }
  }
  
  @objc private func applicationWillTerminate(_ aNotification: NSNotification) {
    NotificationCenter.default.removeObserver(self)
    try? FileManager.default.removeItem(at: self.presentedItemURL!)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    try? FileManager.default.removeItem(at: self.presentedItemURL!)
  }
}

extension NSAppleScript {
  internal static func try3_countSelectedMessages() throws(AppleScriptError) -> Int {
    let kScriptString =
      """
      set output to {}
      tell application "Mail"
        set selectedMessages to selection
        return count of selectedMessages
      end tell
      return output
      """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return Int(descriptor.doubleValue)
  }
  
  internal static func try3_importSelectedMessages(updating file: URL) throws(AppleScriptError) -> [MessageForAnalysis] {
    let kScriptString =
      """
      set progressFile to (POSIX file "\(file.path)") as alias
      
      tell application "Mail"
        set selectedMessages to selection
        set output to {}
        set totalCount to count of selectedMessages
        
        repeat with i from 1 to totalCount
          set msg to item i of selectedMessages
          
          -- Grab message data
          set theUniqueID to message id of msg
          set theMailbox to name of mailbox of msg
          set theAccount to name of account of mailbox of msg
          set theSubject to subject of msg
          set theContent to content of msg
          set theHeaders to all headers of msg
          
          -- Append to output
          set end of output to {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount, kSubject:theSubject, kContent:theContent, kHeaders:theHeaders}
          
          -- Write progress index to the temp file
          my writeToFile(i as string, progressFile, false)
        end repeat
        return output
      end tell
      
      -- Handler to write to file
      on writeToFile(this_data, target_file, append_data)
        try
          set the target_file to the target_file as text
          set the open_target_file to open for access file target_file with write permission
          if append_data is false then set eof of the open_target_file to 0
          write this_data to the open_target_file starting at eof
          close access the open_target_file
          return true
        on error errMsg
          try
            close access file target_file
          end try
          error errMsg
          return false
        end try
      end writeToFile
      """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return try MessageForAnalysis.messages(fromArray: descriptor)
  }
}
