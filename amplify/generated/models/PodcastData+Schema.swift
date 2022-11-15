// swiftlint:disable all
import Amplify
import Foundation

extension PodcastData {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case category
    case author
    case rating
    case episodes
    case image
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let podcastData = PodcastData.keys
    
    model.listPluralName = "PodcastData"
    model.syncPluralName = "PodcastData"

    model.fields(
      .id(),
      .field(podcastData.name, is: .required, ofType: .string),
      .field(podcastData.category, is: .required, ofType: .enum(type: PodcastCategoryData.self)),
      .field(podcastData.author, is: .required, ofType: .string),
      .field(podcastData.rating, is: .optional, ofType: .int),
      .hasMany(podcastData.episodes, is: .optional, ofType: EpisodeData.self, associatedWith: EpisodeData.keys.podcastDataEpisodesId),
      .field(podcastData.image, is: .optional, ofType: .string),
      .field(podcastData.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(podcastData.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
