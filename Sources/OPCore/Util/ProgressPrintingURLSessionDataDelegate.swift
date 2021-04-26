import Foundation

class ProgressPrintingURLSessionDataDelegate: NSObject, URLSessionDataDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = min(Double(totalBytesSent) / Double(totalBytesExpectedToSend), 1)
        let message = String(format: "Upload Progress: %.2f (%d B / %d B)", progress, totalBytesSent, totalBytesExpectedToSend)
        debugPrint(message: message)
    }
}
