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

internal struct MailInterfaceView_Try3: View {
  
  @State private var mail = MailInterface_Try3()
  
  internal init() { }
  
  internal var body: some View {
    NavigationStack {
      switch self.mail.status {
      case .notStarted:
        Button("Count") { self.mail.step1_count() }
      case .counted(let messages):
        Button("Import: \(messages) messages") {
          
        }
      case .importing(let completed, let total):
        ProgressView("Importing Messages", value: completed, total: total)
      case .imported(let messages):
        List(messages) { message in
          VStack(alignment: .leading) {
            Text(message.subject)
              .font(.headline)
            Text(message.account + " • " + message.mailbox)
              .font(.subheadline)
          }
          .lineLimit(1)
          .tag(message.id)
        }
      case .error(let error):
        VStack {
          Text(String(describing: error))
          Button("Reset") { self.mail.status = .notStarted }
        }
      }
    }
  }
}

// MARK: Controller

@MainActor
@Observable
public class MailInterface_Try3 {
  
  public enum Status: Sendable {
    case notStarted
    case counted(messages: Int)
    case importing(completed: Double, total: Double)
    case imported(messages: [MessageForAnalysis])
    case error(AppleScriptError)
  }
  
  public var status = Status.notStarted
  
  public func step1_count() {
    do {
      let count = try NSAppleScript.try3_countSelectedMessages()
      self.status = .counted(messages: count)
    } catch {
      self.status = .error(error)
    }
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
}
