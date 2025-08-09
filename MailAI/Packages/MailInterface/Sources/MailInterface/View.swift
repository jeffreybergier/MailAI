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

public struct ContentView: View {
  
  public init() {}
  
  public var body: some View {
    TabView {
      DumbMailInterfaceView()
        .tabItem { Text("MessagesForAnalysis") }
      MailInterfaceView()
        .tabItem { Text("MessagesForLoading") }
    }
  }
}

internal struct MailInterfaceView: View {
  
  @State private var mail = MailInterface2()
  @State private var selection: String?
  
  internal init() { }
  
  internal var body: some View {
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
          // TODO: Load Messages
        }
      }
    }
  }
}

internal struct DumbMailInterfaceView: View {
  
  @State private var mail = MailInterface()
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
      }
      .safeAreaInset(edge: .top) {
        Button("Load Selected") {
          self.mail.getSelected()
        }
      }
    } detail: {
      if let selection {
        ScrollView {
          Form {
            Section("Mail ID") {
              Button {
                NSWorkspace.shared.open(selection.url)
              } label: {
                Text(selection.id)
                  .lineLimit(1)
              }
              .buttonStyle(.link)
            }
            Section("Mail") {
              Text(selection.subject)
                .font(.headline)
              Text(selection.content)
            }
            Section("Headers") {
              Text(selection.headers)
            }
          }
          .padding()
          .font(.body)
        }
      }
    }
  }
}
