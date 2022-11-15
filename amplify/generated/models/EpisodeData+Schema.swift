// swiftlint:disable all
import Amplify
import Foundation

extension EpisodeData {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case date
    case title
    case duration
    case description
    case createdAt
    case updatedAt
    case podcastDataEpisodesId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let episodeData = EpisodeData.keys
    
    model.listPluralName = "EpisodeData"
    model.syncPluralName = "EpisodeData"

    model.fields(
      .id(),
      .field(episodeData.date, is: .required, ofType: .string),
      .field(episodeData.title, is: .required, ofType: .string),
      .field(episodeData.duration, is: .required, ofType: .string),
      .field(episodeData.description, is: .optional, ofType: .string),
      .field(episodeData.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(episodeData.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(episodeData.podcastDataEpisodesId, is: .optional, ofType: .string)
    )
    }
}
