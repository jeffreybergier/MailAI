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

public struct MailInterface: Sendable {
  
  public var messages: [Message] = []
  
  public init() { }
  
  public mutating func getSelected() {
    let appleScript = NSAppleScript(source: kScriptString)
    var error: NSDictionary?
    let result = appleScript?.executeAndReturnError(&error)

    let jsonString = result?.stringValue
    let jsonData = jsonString?.data(using: .utf8)
    
    guard let jsonData else { fatalError(String(describing: error!)) }
    let messages = try! JSONDecoder().decode([Message].self, from: jsonData)
    self.messages = messages
  }
  
}

internal let kScriptString =
"""
set output to "["

tell application "Mail"
  set selectedMessages to selection
  repeat with i from 1 to count of selectedMessages
    set msg to item i of selectedMessages
    set theID to message id of msg
    set theHeaders to all headers of msg
    set theSubject to subject of msg
    set theContent to content of msg
    
    set jsonItem to "{"
    set jsonItem to jsonItem & "id: " & quoted form of theID & ", "
    set jsonItem to jsonItem & "headers: " & quoted form of theHeaders & ", "
    set jsonItem to jsonItem & "subject: " & quoted form of theSubject & ", "
    set jsonItem to jsonItem & "content: " & quoted form of theContent & "}"
    
    set output to output & jsonItem
    if i < (count of selectedMessages) then
      set output to output & ", "
    end if
  end repeat
end tell

set output to output & "]"
return output
"""
