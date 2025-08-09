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
    let kScriptString =
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
        set end of output to {kUniqueID:theUniqueID, kDeviceID:theDeviceID, kMailbox:theMailbox, kAccount:theAccount, kSubject:theSubject, kContent:theContent, kHeaders:theHeaders}
      end repeat
    end tell
    log output
    return output
    """
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
    let count = descriptor.numberOfItems
    for idx in 1...count {
      guard let record = descriptor.atIndex(idx) else { throw .parsing }
      let message = try MessageForAnalysis(fromDictionary: record)
      output.append(message)
    }
    return output
  }
  internal init(fromDictionary descriptor: NSAppleEventDescriptor) throws(MailInterfaceError) {
    let dictionary = try descriptor.dictionaryValue()
    guard let uniqueID = dictionary["kUniqueID"] else { throw .parsing }
    self.id = uniqueID
    guard let deviceID = dictionary["kDeviceID"] else { throw .parsing }
    self.deviceID = deviceID
    guard let mailbox  = dictionary["kMailbox"]  else { throw .parsing }
    self.mailbox = mailbox
    guard let account  = dictionary["kAccount"]  else { throw .parsing }
    self.account = account
    guard let subject  = dictionary["kSubject"]  else { throw .parsing }
    self.subject = subject
    guard let content  = dictionary["kContent"]  else { throw .parsing }
    self.content = content
    guard let headers  = dictionary["kHeaders"]  else { throw .parsing }
    self.headers = headers
  }
}

// Credit: https://stackoverflow.com/a/13182999
extension NSAppleEventDescriptor {
  internal func dictionaryValue() throws(MailInterfaceError) -> [String: String] {
    var output = [String: String]()
    let this = self.atIndex(1)!
    let count = this.numberOfItems
    var idx = 1
    while idx <= count {
      guard let key = this.atIndex(idx)?.stringValue else { throw .parsing }
      idx += 1
      guard let val = this.atIndex(idx)?.stringValue else { throw .parsing }
      idx += 1
      output[key] = val
    }
    return output
  }
}
