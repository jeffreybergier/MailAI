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
import MailInterface
import AIInterface

public struct AppView: View {
  
  @State private var messages = [Message]()
  @State private var analyses = [String: MessageAnalysis]()
  
  public init() {}
  public var body: some View {
    HStack {
      MailImportView(importedMessages: self.$messages)
      AIAnalyzeView(messagesForAnalysis: self.$messages,
                    analyzedMessages: self.$analyses)
      AnalysisStoreView()
    }
  }
}

internal struct MailImportView: View {
  
  @Binding internal var importedMessages: [Message]
  @State private var mail = MailInterface()
  
  internal var body: some View {
    HStack {
      Spacer()
      VStack {
        self.actionButton
        self.resetButton
      }
      Spacer()
    }
    .onChange(of: self.mail.messages) { _, newValue in
      self.importedMessages = newValue
    }
  }
  
  @ViewBuilder private var actionButton: some View {
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
  }
  
  private var resetButton: some View {
    Button("Reset") {
      self.mail.reset()
    }
    .disabled(self.mail.status.isImporting)
  }
}

internal struct AIAnalyzeView: View {
  
  @Binding internal var messagesForAnalysis: [Message]
  @Binding internal var analyzedMessages: [String: MessageAnalysis]
  @State private var ai = AIInterface()
  
  internal var body: some View {
    HStack {
      Spacer()
      VStack {
        self.actionButton
        self.resetButton
      }
      Spacer()
    }
    .onChange(of: self.ai.analyzed) { _, newValue in
      self.analyzedMessages = newValue
    }
  }
  
  @ViewBuilder private var actionButton: some View {
    switch self.ai.status {
    case .unknown:
      Button("Check AI Readiness") {
        self.ai.step1_checkReadiness()
      }
    case .ready:
      if self.messagesForAnalysis.isEmpty {
        Text("No Messages to Analyze")
      } else {
        Button("Analyze \(self.messagesForAnalysis.count) Message(s)") {
          self.ai.step2_analyze(prompts: self.messagesForAnalysis.map { $0.promptValue })
        }
      }
    case .analyzing(complete: let complete, total: let total):
      ProgressView("Analyzing Messages", value: complete, total: total)
    case .analyzed(let count):
      Text("Analyzed: \(count) message(s)")
    case .unavailable(let error):
      Text("Unavailable: \(String(describing: error))")
    case .error(let error):
      Text(String(describing: error))
    }
  }
  
  private var resetButton: some View {
    Button("Reset") {
      self.ai.reset()
    }
    .disabled(self.ai.status.isAnalyzing)
  }
}

internal struct AnalysisStoreView: View {
  internal var body: some View {
    Color.green
  }
}

