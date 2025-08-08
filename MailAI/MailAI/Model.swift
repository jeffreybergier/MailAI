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
  
  public var id: String // uniqueID in AppleScript
  public var deviceID: String
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

import SwiftData

@Model
public final class MessageForStorage {
  @Attribute(.unique)
  public var id: String // uniqueID in AppleScript
  public var deviceID: String
  public var mailbox: String
  public var account: String
  public var subject: String
  public init(id: String, deviceID: String, mailbox: String, account: String, subject: String) {
    self.id = id
    self.deviceID = deviceID
    self.mailbox = mailbox
    self.account = account
    self.subject = subject
  }
}


import FoundationModels

@Generable
public struct MessageAnalysis: Hashable, Codable, Sendable {
  
  @Generable(description: """
The category that best fits the email. 
Spam is for spam or advertising content that is has not been requested by the user. 
Newsletters are for advertising or messages that are received on a daily, weekly, or monthly schedule. 
Adult is for topics like pornography, guns, drugs, or other not safe for work emails. 
Malicious is for email that contains spams, phishing, identity theft, etc. 
Calendar is for email that is related to recieving, accepting, or sending calendar invites. 
CorrespondanceFriends is for conversations between friends. 
CorrespondanceWork is for conversations between coworkers or other email that looks work related. 
ActionRequired is for emails that require action from the user such as tax, bank, service provider, insurance, or other items that need quick action.
Unknown is for when the email seems to fit no other category.
""")
  public enum Category: Hashable, Codable, Sendable {
    case spam, newsletters, adult, malicious, calendar, correspondanceFriends, correspondanceWork, actionRequired, unknown
  }
  
  @Guide(description: "The category that best fits the email you have been provided")
  public var category: Category
  @Guide(description: "The reason you think this email fits into the category")
  public var explanation: String
}
