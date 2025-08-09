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

internal struct MailInterfaceView_Try2: View {
  
  @State private var mail = MailInterface_Try2()
  @State private var selection: String?
  
  internal init() { }
  
  internal var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if let error = self.mail.error {
          Text(String(describing: error))
        } else {
          ProgressView(self.mail.progress)
        }
        HStack {
          List(self.mail.selection, selection: self.$selection) { message in
            VStack(alignment: .leading) {
              Text(message.id)
                .font(.headline)
              Text(message.account + " • " + message.mailbox)
                .font(.subheadline)
            }
            .lineLimit(1)
            .tag(message.id)
          }
          .safeAreaInset(edge: .top) {
            Button("Find Selected") {
              self.mail.getSelected()
            }
          }
          List(self.mail.messages, selection:self.$selection) { message in
            VStack(alignment: .leading) {
              Text(message.subject)
                .font(.headline)
              Text(message.account + " • " + message.mailbox)
                .font(.subheadline)
            }
            .lineLimit(1)
            .tag(message.id)
          }
          .safeAreaInset(edge: .top) {
            Button("Load Messages") {
              self.mail.loadSelected()
            }
          }
        }
      }
    }
  }
}

// MARK: Controller

@MainActor
@Observable
public class MailInterface_Try2 {
  
  public let progress = Progress()
  public var isUpdating: Bool { self.progress.completedUnitCount != self.progress.totalUnitCount }
  public var selection: [MessageForLoading] = []
  public var messages: [MessageForAnalysis] = []
  public var error: AppleScriptError?
  
  public init() { }
  
  public func getSelected() {
    self.progress.totalUnitCount = 1
    self.progress.completedUnitCount = 0
    Task {
      do {
        self.selection = try NSAppleScript.try2_getSelectedMessagesForLoading()
      } catch let error as AppleScriptError {
        NSLog(error.localizedDescription)
        self.error = error
      }
      self.progress.completedUnitCount = 1
    }
  }
  
  public func loadSelected() {
    self.progress.totalUnitCount = Int64(self.selection.count)
    self.progress.completedUnitCount = 0
    Task {
      for forLoading in self.selection.chunked(into: 10) {
        let task = Task.detached(priority: .userInitiated) {
          try NSAppleScript.try2_lookupMessagesForLoading(with: forLoading)
        }
        do {
          let messages = try await task.value
          self.messages += messages
          self.progress.completedUnitCount += Int64(messages.count)
        } catch let error as AppleScriptError {
          NSLog(error.localizedDescription)
          self.error = error
          self.progress.completedUnitCount = self.progress.totalUnitCount
        }
      }
    }
  }
}

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}

extension NSAppleScript {
  
  internal static func try2_getSelectedMessagesForLoading() throws(AppleScriptError) -> [MessageForLoading] {
    let kScriptString =
      """
      set output to {}
      tell application "Mail"
        set selectedMessages to selection
        repeat with msg in selectedMessages
          set theUniqueID to message id of msg
          set theMailbox to name of mailbox of msg
          set theAccount to name of account of mailbox of msg
          set end of output to {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount}
        end repeat
      end tell
      return output
      """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return try MessageForLoading.messages(fromArray: descriptor)
  }
  
  internal static func try2_lookupMessagesForLoading(with messagesForLoading: [MessageForLoading]) throws(AppleScriptError) -> [MessageForAnalysis] {
    let input: String = messagesForLoading
                       .map { "{ kUniqueID:\"\($0.id)\", kMailbox:\"\($0.mailbox)\", kAccount:\"\($0.account)\" }" }
                       .joined(separator: ",")
    let kScriptString = """
    set output to {}
    set input to {\(input)}
    tell application "Mail"
      repeat with dict in input
        set inUniqueID to kUniqueID of dict
        set inMailbox to kMailbox of dict
        set inAccount to kAccount of dict
        set msg to (first message of mailbox inMailbox of account inAccount whose message id is inUniqueID)
        set theUniqueID to message id of msg
        set theMailbox to name of mailbox of msg
        set theAccount to name of account of mailbox of msg
        set theSubject to subject of msg
        set theContent to content of msg
        set theHeaders to all headers of msg
        set end of output to {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount, kSubject:theSubject, kContent:theContent, kHeaders:theHeaders}
      end repeat
    end tell
    log output
    return output
    """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return try MessageForAnalysis.messages(fromArray: descriptor)
  }
  
  internal static func try2_lookupMessagesForLoading(with messageForLoading: MessageForLoading) throws(AppleScriptError) -> MessageForAnalysis {
    let mailbox = messageForLoading.mailbox
    let account = messageForLoading.account
    let messageID = messageForLoading.id
    let kScriptString = """
    tell application "Mail"
        set msg to first message of mailbox "\(mailbox)" of account "\(account)" whose message id is "\(messageID)"
        set theUniqueID to message id of msg
        set theMailbox to name of mailbox of msg
        set theAccount to name of account of mailbox of msg
        set theSubject to subject of msg
        set theContent to content of msg
        set theHeaders to all headers of msg
        return {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount, kSubject:theSubject, kContent:theContent, kHeaders:theHeaders}
    end tell
    """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return try MessageForAnalysis(fromDictionary: descriptor)
  }
}
