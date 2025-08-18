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
  case empty
}

public struct Message: Identifiable, Hashable, Codable, Sendable {
  
  public var id: String
  public var mailbox: String
  public var account: String
  public var subject: String
  public var content: String
  public var headers: String
  
  public var url: URL {
    let encoded = self.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    let urlString = "message://%3C" + encoded + "%3E"
    return URL(string:urlString)!
  }
}

extension Message {
  
  internal static func messages(fromArray descriptor: NSAppleEventDescriptor) throws(AppleScriptError) -> [Message] {
    var output = [Message]()
    let count = descriptor.numberOfItems
    guard count > 0 else { throw .empty }
    for idx in 1...count {
      guard let record = descriptor.atIndex(idx) else { throw .parsing }
      let message = try Message(fromDictionary: record)
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
