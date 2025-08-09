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
  
  public var isUpdating: Bool = false
  public var selection: [MessageForLoading] = []
  public var messages: [MessageForAnalysis] = []
  public var error: AppleScriptError?
  
  public init() { }
  
  public func getSelected() {
    Task {
      do {
        self.isUpdating = true
        self.selection = try NSAppleScript.selectedMessagesForLoading()
      } catch let error as AppleScriptError {
        NSLog(error.localizedDescription)
        self.error = error
      }
      self.isUpdating = false
    }
  }
}
