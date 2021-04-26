import Foundation
import Endpoints

extension OPClient {
    struct AppsAPI {
        private static let path = "apps"
        
        /// Returns all apps
        struct Get: Call {
            typealias Parser = OPParser<[StoreApp]>
            
            var request: URLRequestEncodable {
                return Request(
                    .get,
                    "\(AppsAPI.path)"
                )
            }
        }
        
        /// Returns the app with the passed id
        struct GetById: Call {
            typealias Parser = OPParser<StoreApp>
            
            let id: Int
            
            var request: URLRequestEncodable {
                return Request(
                    .get,
                    "\(AppsAPI.path)/\(id)"
                )
            }
        }
        
        /// Returns the app with the passed id
        struct JourneysForApp: Call {
            
            typealias Parser = OPParser<[AppJourney]>
            
            let id: Int
            
            var request: URLRequestEncodable {
                return Request(
                    .get,
                    "\(AppsAPI.path)/\(id)/app-journeys"
                )
            }
        }
        
        /// Creates a new app in ObservePoint
        struct CreateUploadId: Call {
            typealias Parser = OPParser<MobileAppUpload>
            
            let data: ExistingMobileApp
            
            var request: URLRequestEncodable {
                return Request(
                    .post,
                    "\(AppsAPI.path)/\(data._id)",
                    body: try! JSONEncodedBody(encodable: data)
                )
            }
            
            init(_ data: ExistingMobileApp) {
                self.data =  data
            }
        }
        
        /// Uploads the app file 
        struct UploadFile: Call {
            typealias Parser = OPParser<MobileAppUpload>
            
            let upload: MobileAppUpload
            let appFileData: Data
            
            var request: URLRequestEncodable  {
                return Request(
                    .put,
                    "\(AppsAPI.path)/\(upload.uploadId)",
                    body: MultipartBody(parts: [
                        MultipartBody.Part(
                            name: "appFile",
                            data: appFileData,
                            filename: "appFile"
                        )
                    ])
                )
            }
            
            init(_ upload: MobileAppUpload, appFileData: Data) {
                self.upload = upload
                self.appFileData = appFileData
            }
        }
        
        struct CheckUploadState: Call {
            typealias Parser = OPParser<MobileAppUploadStatus>
            
            let upload: MobileAppUpload
            
            var request: URLRequestEncodable {
                return Request(
                    .get,
                    "\(AppsAPI.path)/\(upload.uploadId)"
                )
            }
            
            init(upload: MobileAppUpload) {
                self.upload = upload
            }
        }
    }
}

