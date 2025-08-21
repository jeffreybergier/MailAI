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

import FoundationModels

@Generable
public struct PromptAnalysis: Hashable, Codable, Sendable {
  @Generable
  public struct TagAnalysis: Hashable, Codable, Sendable {
    @Generable
    public enum Tag: Hashable, Codable, Sendable {
      case spam, newsletters, adult, malicious, calendar, correspondanceFriends, correspondanceWork, actionRequired, old, deletable
    }
    public var tag: Tag
    @Guide(description: "The reason you think this tag is a match for this email message")
    public var justification: String
  }
  public var tags: [TagAnalysis] = []
}

extension PromptAnalysis.TagAnalysis.Tag: CustomStringConvertible {
  public var description: String {
    switch self {
    case .spam:
      return "Spam is for spam or advertising content that is has not been requested by the user."
    case .newsletters:
      return "Newsletters are for advertising or messages that are received on a daily, weekly, or monthly schedule."
    case .adult:
      return "Adult is for topics like pornography, guns, drugs, or other not safe for work emails."
    case .malicious:
      return "Malicious is for email that contains spams, phishing, identity theft, etc."
    case .calendar:
      return "Calendar is for email that is related to recieving, accepting, or sending calendar invites."
    case .correspondanceFriends:
      return "CorrespondanceFriends is for conversations between friends."
    case .correspondanceWork:
      return "CorrespondanceWork is for conversations between coworkers or other email that looks work related."
    case .actionRequired:
      return "ActionRequired is for emails that require action from the user such as tax, bank, service provider, insurance, or other items that need quick action."
    case .old:
      return "Old is for emails are really old and have outlives their usefulness or are no longer actionable"
    case .deletable:
      return "Deletable is for emails you think the user could delete and never miss."
    }
  }
}

public struct MessagePrompt {
  public var id: String
  public var usersNames: String
  public var usersEmails: String
  public var usersDescription: String
  public var subject: String
  public var content: String
  public var headers: String
  
  public init(id: String,
              usersNames: String       = MessagePrompt.defaultNoneProvided,
              usersEmails: String      = MessagePrompt.defaultNoneProvided,
              usersDescription: String = MessagePrompt.defaultNoneProvided,
              subject: String,
              content: String,
              headers: String)
  {
    self.id = id
    self.usersNames = usersNames
    self.usersEmails = usersEmails
    self.usersDescription = usersDescription
    self.subject = subject
    self.content = content
    self.headers = headers
  }
  
  public static let defaultNoneProvided = "None Provided"
}
