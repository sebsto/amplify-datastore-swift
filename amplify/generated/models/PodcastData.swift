// swiftlint:disable all
import Amplify
import Foundation

public struct PodcastData: Model {
  public let id: String
  public var name: String
  public var category: PodcastCategoryData
  public var author: String
  public var rating: Int?
  public var episodes: List<EpisodeData>?
  public var image: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      category: PodcastCategoryData,
      author: String,
      rating: Int? = nil,
      episodes: List<EpisodeData>? = [],
      image: String? = nil) {
    self.init(id: id,
      name: name,
      category: category,
      author: author,
      rating: rating,
      episodes: episodes,
      image: image,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      category: PodcastCategoryData,
      author: String,
      rating: Int? = nil,
      episodes: List<EpisodeData>? = [],
      image: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.category = category
      self.author = author
      self.rating = rating
      self.episodes = episodes
      self.image = image
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}