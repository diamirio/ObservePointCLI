import Foundation
import Endpoints

extension OPClient {
    struct AppJourneysAPI {
        private static let path = "app-journeys"
        
        /// Run Journey
        struct Run: Call {
            typealias Parser = OPParser<AppJourney>
            
            let id: Int

            var request: URLRequestEncodable {
                return Request(
                    .post,
                    "\(AppJourneysAPI.path)/\(id)/runs"
                )
            }
        }
    }
}

