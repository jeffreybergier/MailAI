// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import FoundationModels

@MainActor
@Observable
public class AIInterface {
  
  public enum Status: Sendable {
    case notStarted
    case processing(complete: Double, total: Double)
    case error(Error)
    public var isProcessing: Bool {
      switch self {
      case .processing:
        return true
      default:
        return false
      }
    }
  }
  
  public var status = Status.notStarted
}
