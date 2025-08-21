// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import FoundationModels

@MainActor
@Observable
public class AIInterface {
  
  public typealias Analyses = [String: PromptAnalysis]
  
  public enum Status: Sendable {
    case unknown
    case ready
    case analyzing(complete: Double, total: Double)
    case analyzed(Int)
    case unavailable(SystemLanguageModel.Availability.UnavailableReason)
    case error(Error)
    public var isAnalyzing: Bool {
      switch self {
      case .analyzing:
        return true
      default:
        return false
      }
    }
  }
  
  public var instructions: String
  public var status = Status.unknown
  public var analyzed = Analyses()
  
  public init(instructions: String = AIInterface.defaultInstructions) {
    self.instructions = instructions
  }
  
  public func step1_checkReadiness() {
    switch self.status {
    case .analyzing, .analyzed:
      fatalError("Function used in wrong order")
    default:
      break
    }
    let canUse = SystemLanguageModel.default.availability
    switch canUse {
    case .unavailable(let reason):
      self.status = .unavailable(reason)
    case .available:
      self.status = .ready
    }
  }
  
  public func step2_analyze(prompts: [MessagePrompt]) {
    switch self.status {
    case .analyzing, .analyzed:
      fatalError("Function used in wrong order")
    default:
      break
    }
    let total = prompts.count
    self.status = .analyzing(complete: 0, total: Double(total))
    Task {
      let model = LanguageModelSession(instructions: self.instructions)
      for (idx, prompt) in prompts.enumerated() {
        do {
          let response = try await model.respond(to: prompt.stringValue,
                                                 generating: PromptAnalysis.self)
          self.analyzed[prompt.id] = response.content
          self.status = .analyzing(complete: Double(idx+1), total: Double(total))
        } catch {
          self.status = .error(error)
          break
        }
      }
      self.status = .analyzed(total)
    }
  }
  
  public func reset() {
    self.analyzed = [:]
    self.status = .unknown
  }
}
