import Foundation

import Endpoints

/// A client for the ObservePoint API 2.0
/// Swagger Docs: https://api.observepoint.com/swagger-ui/index.html
class OPClient: AnyClient {
    
    private let apiKey: String
        
    override func encode<C>(call: C) -> URLRequest where C : Call {
        var request = super.encode(call: call)
        
        request.addValue("api_key \(apiKey)", forHTTPHeaderField: "Authorization")
                
        return request
    }
    
    init(baseURL: URL, apiKey: String) {
        self.apiKey = apiKey
        super.init(baseURL: baseURL)
    }
}
