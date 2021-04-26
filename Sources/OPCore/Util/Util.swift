import Foundation

func debugPrint(message: String, file: String = #file, line: UInt = #line) {
    let filename = file.split(separator: "/").last!

    Swift.print("[\(filename):\(line)] \(Date()): \(message)")
}
