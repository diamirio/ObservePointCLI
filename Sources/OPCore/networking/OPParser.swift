import Foundation

import Endpoints

public class OPParser<T: Decodable>: JSONParser<T> {
    
    public typealias OutputType = T
    
    override public var jsonDecoder: JSONDecoder {
        return decoder
    }
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        
        d.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formatters = [
                "yyyy-MM-dd",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ].map { (format: String) -> DateFormatter in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = format
                return formatter
            }
            
            for formatter in formatters {
                
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
            
            throw DateError.invalidDate(dateStr)
        })
        
        return d
    }()
}

enum DateError: LocalizedError {
    case invalidDate(String)
    
    var errorDescription: String? {
        switch self {
        case let .invalidDate(parsedString):
            return "Unable to parse date string '\(parsedString)'"
        }
    }
}


