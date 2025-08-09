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

public struct MailOnlyAppContentView: View {
  
  public init() {}
  
  public var body: some View {
    TabView {
      MailInterfaceView_Try1()
        .tabItem { Text("MessagesForAnalysis") }
      MailInterfaceView_Try2()
        .tabItem { Text("MessagesForLoading") }
    }
  }
}


internal struct MailInterfaceView_Try1: View {
  
  @State private var mail = MailInterface_Try1()
  @State private var selection: MessageForAnalysis?
  
  internal init() {}
  
  internal var body: some View {
    NavigationSplitView {
      List(self.mail.messages,
           selection:self.$selection)
      { message in
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
        VStack {
          if let error = self.mail.error {
            Text(String(describing: error))
          }
          if self.mail.isUpdating {
            ProgressView()
          } else {
            Button("Load Selected") {
              self.mail.getSelected()
            }
          }
        }
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
public class MailInterface_Try1 {
  
  public var isUpdating: Bool = false
  public var messages: [MessageForAnalysis] = []
  public var error: AppleScriptError?
  
  public init() { }
  
  public func getSelected() {
    self.isUpdating = true
    Task {
      let task = Task.detached(priority: .userInitiated) {
        try NSAppleScript.try1_getSelectedMessagesForAnalysis()
      }
      do {
        let messages = try await task.value
        self.messages += messages
        self.isUpdating = false
      } catch let error as AppleScriptError {
        NSLog(error.localizedDescription)
        self.error = error
        self.isUpdating = false
      }
    }
  }
}

extension NSAppleScript {
  internal static func try1_getSelectedMessagesForAnalysis() throws(AppleScriptError) -> [MessageForAnalysis] {
    let kScriptString =
      """
      set output to {}
      tell application "Mail"
        set selectedMessages to selection
        repeat with msg in selectedMessages
          set theUniqueID to message id of msg
          set theMailbox to name of mailbox of msg
          set theAccount to name of account of mailbox of msg
          set theSubject to subject of msg
          set theContent to content of msg
          set theHeaders to all headers of msg
          set end of output to {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount, kSubject:theSubject, kContent:theContent, kHeaders:theHeaders}
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
    return try MessageForAnalysis.messages(fromArray: descriptor)
  }
}
