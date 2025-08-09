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

import Foundation

@MainActor
@Observable
public class MailInterface {
  
  public var isUpdating: Bool = false
  public var messages: [MessageForAnalysis] = []
  public var error: AppleScriptError?
  
  public init() { }
  
  public func getSelected() {
    Task {
      do {
        self.isUpdating = true
        self.messages = try NSAppleScript.selectedMessagesForAnalysis()
      } catch let error as AppleScriptError {
        NSLog(error.localizedDescription)
        self.error = error
      }
      self.isUpdating = false
    }
  }
}

@MainActor
@Observable
public class MailInterface2 {
  
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
        self.selection = try NSAppleScript.selectedMessagesForLoading()
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
          try NSAppleScript.messageForAnalysis(with: forLoading)
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
