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

public enum AppleScriptError: Error {
  case parsing
  case execution
}

extension NSAppleScript {
  
  internal static func selectedMessagesForLoading() throws(AppleScriptError) -> [MessageForLoading] {
    let kScriptString =
      """
      set output to {}
      tell application "Mail"
        set selectedMessages to selection
        repeat with msg in selectedMessages
          set theUniqueID to message id of msg
          set theMailbox to name of mailbox of msg
          set theAccount to name of account of mailbox of msg
          set end of output to {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount}
        end repeat
      end tell
      log output
      return output
      """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return try MessageForLoading.messages(fromArray: descriptor)
  }
  
  internal static func selectedMessagesForAnalysis() throws(AppleScriptError) -> [MessageForAnalysis] {
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
      log output
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
  
  internal static func messageForAnalysis(with messageForLoading: MessageForLoading) throws(AppleScriptError) -> MessageForAnalysis {
    let mailbox = messageForLoading.mailbox
    let account = messageForLoading.account
    let messageID = messageForLoading.id
    let kScriptString = """
    tell application "Mail"
        set msg to first message of mailbox "\(mailbox)" of account "\(account)" whose message id is "\(messageID)"
        set theUniqueID to message id of msg
        set theMailbox to name of mailbox of msg
        set theAccount to name of account of mailbox of msg
        set theSubject to subject of msg
        set theContent to content of msg
        set theHeaders to all headers of msg
        return {kUniqueID:theUniqueID, kMailbox:theMailbox, kAccount:theAccount, kSubject:theSubject, kContent:theContent, kHeaders:theHeaders}
    end tell
    """
    var error: NSDictionary?
    let descriptor = NSAppleScript(source: kScriptString)!.executeAndReturnError(&error)
    if let error = error {
      NSLog(String(describing: error))
      throw .execution
    }
    return try MessageForAnalysis(fromDictionary: descriptor)
  }
}

extension MessageForAnalysis {
  internal static func messages(fromArray descriptor: NSAppleEventDescriptor) throws(AppleScriptError) -> [MessageForAnalysis] {
    var output = [MessageForAnalysis]()
    let count = descriptor.numberOfItems
    for idx in 1...count {
      guard let record = descriptor.atIndex(idx) else { throw .parsing }
      let message = try MessageForAnalysis(fromDictionary: record)
      output.append(message)
    }
    return output
  }
  internal init(fromDictionary descriptor: NSAppleEventDescriptor) throws(AppleScriptError) {
    let dictionary = try descriptor.dictionaryValue()
    guard let uniqueID = dictionary["kUniqueID"] else { throw .parsing }
    self.id = uniqueID
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

extension MessageForLoading {
  internal static func messages(fromArray descriptor: NSAppleEventDescriptor) throws(AppleScriptError) -> [MessageForLoading] {
    // TODO: Using Map here does not work because of typed throws
    // return try input.split(separator: "RrRrRr").map { try Message(fromAppleEventRow: $0) }
    var output = [MessageForLoading]()
    let count = descriptor.numberOfItems
    for idx in 1...count {
      guard let record = descriptor.atIndex(idx) else { throw .parsing }
      let message = try MessageForLoading(fromDictionary: record)
      output.append(message)
    }
    return output
  }
  internal init(fromDictionary descriptor: NSAppleEventDescriptor) throws(AppleScriptError) {
    let dictionary = try descriptor.dictionaryValue()
    guard let uniqueID = dictionary["kUniqueID"] else { throw .parsing }
    self.id = uniqueID
    guard let mailbox  = dictionary["kMailbox"]  else { throw .parsing }
    self.mailbox = mailbox
    guard let account  = dictionary["kAccount"]  else { throw .parsing }
    self.account = account
  }
}

// Credit: https://stackoverflow.com/a/13182999
extension NSAppleEventDescriptor {
  internal func dictionaryValue() throws(AppleScriptError) -> [String: String] {
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
