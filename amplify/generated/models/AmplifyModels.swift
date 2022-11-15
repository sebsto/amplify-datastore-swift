// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "6259b1ad1732755d85c3e90d130a0f9b"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: PodcastData.self)
    ModelRegistry.register(modelType: EpisodeData.self)
  }
}