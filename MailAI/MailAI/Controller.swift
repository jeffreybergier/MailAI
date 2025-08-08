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

public struct AIInterface: Sendable {
  public func analyze(message: Any/*MessageForAnalysis*/) async throws -> MessageAnalysis {
    fatalError()
    /*
    let canUse = SystemLanguageModel.default.availability
    switch canUse {
    case .unavailable(let reason):
      fatalError(String(describing: reason))
    case .available:
      break
    }

    let session = LanguageModelSession(instructions:
    """
    You are a mail categorizing robot. In each prompt I will provide you an 
    email message. I will provide you the Subject, the Content, and the Headers 
    of the email. The headers give you extra context that the user cannot see 
    Your analysis is critical because the user will use your analysis to clean 
    up their email which will save them gigabytes of space. I will also provide 
    basic information about the user like their name and their employers so that 
    you know if this message is related to them or their work.
    """)
    
    let prompt =
    """
    Subject: \(message.subject)
    Content: \(message.content.prefix(2000))
    Headers: \(message.headers.prefix(1000))
    """
    let response = try await session.respond(
      to: prompt,
      generating: MessageAnalysis.self
    )
    NSLog(String(describing: response.content))
    return response.content
    */
  }
}
