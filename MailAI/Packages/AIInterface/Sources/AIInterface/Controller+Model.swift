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

extension MessagePrompt {
  public var stringValue: String {
    return """
      User's Name(s): \(self.usersNames)
      User's Email(s): \(self.usersEmails)
      User's Description = \(self.usersDescription)
      Email Subject: \(self.subject)
      Email Content: \(self.content.prefix(2000))
      Email Headers: \(self.headers.prefix(1000))
      """
  }
}

extension AIInterface {
  public static let defaultInstructions: String = """
        You are a mail categorizing robot. In each prompt I will provide you an 
        email message. I will provide you the Subject, the Content, and the Headers 
        of the email. The headers give you extra context that the user cannot see 
        Your analysis is critical because the user will use your analysis to clean 
        up their email which will save them gigabytes of space. I will also provide 
        basic information about the user like their name(s), email(s) and a
        description so that you can determine how important this email might be to 
        them you know if this message is related to them or their work.
        """
}
