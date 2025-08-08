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
  
  public var messages: [MessageForAnalysis] = []
  public var error: MailInterfaceError?
  
  public init() { }
  
  public mutating func getSelected() {
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error { assertionFailure(String(describing: error)) }
    do {
      let messages = try MessageForAnalysis.messages(fromArray: descriptor)
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
  case parsing
  case execution
}

extension MessageForAnalysis {
  internal static func messages(fromArray descriptor: NSAppleEventDescriptor) throws(MailInterfaceError) -> [MessageForAnalysis] {
    // TODO: Using Map here does not work because of typed throws
    // return try input.split(separator: "RrRrRr").map { try Message(fromAppleEventRow: $0) }
    var output = [MessageForAnalysis]()
    for idx in 0..<descriptor.numberOfItems {
      guard let record = descriptor.atIndex(idx) else { throw .parsing }
      let message = try MessageForAnalysis(fromDictionary: record)
      output.append(message)
    }
    return output
  }
  internal init(fromDictionary descriptor: NSAppleEventDescriptor) throws(MailInterfaceError) {
    guard let uniqueID = descriptor.value(forKey: "uniqueID") as? String else { throw .parsing }
    self.id = uniqueID
    guard let deviceID = descriptor.value(forKey: "deviceID") as? Int    else { throw .parsing }
    self.deviceID = deviceID
    guard let mailbox  = descriptor.value(forKey: "mailbox")  as? String else { throw .parsing }
    self.mailbox = mailbox
    guard let account  = descriptor.value(forKey: "account")  as? String else { throw .parsing }
    self.account = account
    guard let subject  = descriptor.value(forKey: "subject")  as? String else { throw .parsing }
    self.subject = subject
    guard let content  = descriptor.value(forKey: "content")  as? String else { throw .parsing }
    self.content = content
    guard let headers  = descriptor.value(forKey: "headers")  as? String else { throw .parsing }
    self.headers = headers
  }
}

internal let kScriptString =
"""
set output to {}
tell application "Mail"
  set selectedMessages to selection
  repeat with msg in selectedMessages
    set theUniqueID to message id of msg
    set theDeviceID to id of msg
    set theMailbox to name of mailbox of msg
    set theAccount to name of account of mailbox of msg
    set theSubject to subject of msg
    set theContent to content of msg
    set theHeaders to all headers of msg
    set end of output to {uniqueID:theUniqueID, deviceID:theDeviceID, mailbox:theMailbox, account:theAccount, subject:theSubject, content:theContent, header:theHeaders}
  end repeat
end tell
log output
return output
"""
