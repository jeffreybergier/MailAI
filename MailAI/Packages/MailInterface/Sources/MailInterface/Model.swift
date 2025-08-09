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

public struct MessageForAnalysis: Identifiable, Hashable, Codable, Sendable {
  
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

public struct MessageForLoading: Identifiable, Hashable, Codable, Sendable {
  public var id: String
  public var mailbox: String
  public var account: String
}

import SwiftData

@Model
public final class MessageForStorage {
  @Attribute(.unique)
  public var id: String
  public var mailbox: String
  public var account: String
  public var subject: String
  public init(id: String, deviceID: String, mailbox: String, account: String, subject: String) {
    self.id = id
    self.mailbox = mailbox
    self.account = account
    self.subject = subject
  }
}
