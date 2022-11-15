// swiftlint:disable all
import Amplify
import Foundation

public struct EpisodeData: Model {
  public let id: String
  public var date: String
  public var title: String
  public var duration: String
  public var description: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var podcastDataEpisodesId: String?
  
  public init(id: String = UUID().uuidString,
      date: String,
      title: String,
      duration: String,
      description: String? = nil,
      podcastDataEpisodesId: String? = nil) {
    self.init(id: id,
      date: date,
      title: title,
      duration: duration,
      description: description,
      createdAt: nil,
      updatedAt: nil,
      podcastDataEpisodesId: podcastDataEpisodesId)
  }
  internal init(id: String = UUID().uuidString,
      date: String,
      title: String,
      duration: String,
      description: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      podcastDataEpisodesId: String? = nil) {
      self.id = id
      self.date = date
      self.title = title
      self.duration = duration
      self.description = description
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.podcastDataEpisodesId = podcastDataEpisodesId
  }
}