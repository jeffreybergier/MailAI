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

public struct Message: Identifiable, Hashable, Codable, Sendable {
  public var id: String
  public var headers: String
  public var subject: String
  public var content: String
}

@Generable
public struct Analysis: Hashable, Codable, Sendable {
  
  @Generable(description: """
The category that best fits the email. 
Spam is for spam or advertising content. 
Newsletters are for advertising or messages that are received on a schedule. 
Adult is for topics like pornography, guns, drugs, or other not safe for work emails. 
Malicious is for email that contains spams, phishing, identity theft, etc. 
Calendar is for email that is related to recieving, accepting, or sending calendar invites. 
CorrespondanceFriends is for conversations between friends. 
CorrespondanceWork is for conversations between coworkers or other email that looks work related. 
Unknown is for when the email seems to fit no other category.
""")
  public enum Category: Hashable, Codable, Sendable {
    case spam, newsletters, adult, malicious, calendar, correspondanceFriends, correspondanceWork, unknown
  }
  
  @Guide(description: "The category that best fits the email you have been provided")
  public var category: Category
  @Guide(description: "The reason you think this email fits into the category")
  public var explanation: String
}
