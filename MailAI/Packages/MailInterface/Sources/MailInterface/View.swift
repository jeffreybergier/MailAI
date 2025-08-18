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
  @State private var selection: Message?
  
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

