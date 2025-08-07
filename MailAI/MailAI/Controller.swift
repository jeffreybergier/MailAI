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
import FoundationModels

public struct AIInterface: Sendable {
  public func analyze(message: Message) async throws -> Analysis {
    let canUse = SystemLanguageModel.default.availability
    switch canUse {
    case .unavailable(let reason):
      fatalError(String(describing: reason))
    case .available:
      break
    }

    let session = LanguageModelSession(instructions:
    """
    You are a mail categorizing robot. In each prompt I will provide you an 
    email message. I will provide you the Subject, the Content, and the Headers 
    of the email. The headers give you extra context that the user cannot see 
    Your analysis is critical because the user will use your analysis to clean 
    up their email which will save them gigabytes of space. I will also provide 
    basic information about the user like their name and their employers so that 
    you know if this message is related to them or their work.
    """)
    
    let prompt =
    """
    Subject: \(message.subject)
    Content: \(message.content.prefix(2000))
    Headers: \(message.headers.prefix(1000))
    """
    let response = try await session.respond(
      to: prompt,
      generating: Analysis.self
    )
    NSLog(String(describing: response.content))
    return response.content
  }
}

private let kMailRowSeparator = "RrRrRr"
private let kMailColumnSeparator = "CcCcCc"

public struct MailInterface: Sendable {
  
  public var messages: [Message] = []
  public var error: MailInterfaceError?
  
  public init() { }
  
  public mutating func getSelected() {
    let appleScript = NSAppleScript(source: kScriptString)
    var error: NSDictionary?
    let result: String?
    if let __FAKE_DATA {
      result = __FAKE_DATA
    } else {
      result = appleScript?.executeAndReturnError(&error).stringValue
    }
    do {
      let messages = try Message.messages(fromAppleEvent: result ?? "")
      NSLog("MailInterface: [Success] \(messages.count)")
      self.messages = messages
      self.error = nil
    } catch {
      self.error = error
      NSLog("MailInterface: [Error] \(error)")
    }
  }
}

public enum MailInterfaceError: Error {
  case resultsParse
}

extension Message {
  internal static func messages(fromAppleEvent input: String) throws(MailInterfaceError) -> [Message] {
    // TODO: Using Map here does not work because of typed throws
    // return try input.split(separator: "RrRrRr").map { try Message(fromAppleEventRow: $0) }
    let rows = input.split(separator: kMailRowSeparator)
    guard !rows.isEmpty else { throw .resultsParse }
    var output: [Message] = []
    for row in rows {
      try output.append(Message(fromAppleEventRow: row))
    }
    return output
  }
  internal init<S: StringProtocol>(fromAppleEventRow row: S) throws(MailInterfaceError) {
    let items = row.split(separator: kMailColumnSeparator)
    guard items.count == 4 else {
      throw MailInterfaceError.resultsParse
    }
    self.id      = String(items[0])
    self.headers = String(items[1])
    self.subject = String(items[2])
    self.content = String(items[3])
  }
}

internal let kScriptString =
"""
set output to ""

tell application "Mail"
  set selectedMessages to selection
  repeat with i from 1 to count of selectedMessages
    set msg to item i of selectedMessages
    
    set theID to message id of msg
    set theHeaders to all headers of msg
    set theSubject to subject of msg
    set theContent to content of msg
    
    set row to ""
    set row to row & theID & "\(kMailColumnSeparator)"
    set row to row & theHeaders & "\(kMailColumnSeparator)"
    set row to row & theSubject & "\(kMailColumnSeparator)"
    set row to row & theContent
    
    set output to output & row & "\(kMailRowSeparator)"
  end repeat
end tell

return output
"""

private let __FAKE_DATA: String? = nil
