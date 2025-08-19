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

import SwiftUI

public struct AppView: View {
  public init() {}
  public var body: some View {
    HStack {
      MailImportView()
      AIAnalyzeView()
      AnalysisStoreView()
    }
  }
}

internal struct MailImportView: View {
  internal var body: some View {
    Color.yellow
  }
}

internal struct AIAnalyzeView: View {
  internal var body: some View {
    Color.blue
  }
}

internal struct AnalysisStoreView: View {
  internal var body: some View {
    Color.green
  }
}

