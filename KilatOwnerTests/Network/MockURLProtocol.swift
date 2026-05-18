import Foundation
@testable import KilatOwner

final class MockURLProtocol: URLProtocol {
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)

    static var requestHandler: RequestHandler? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _requestHandler
        }
        set {
            stateLock.lock()
            _requestHandler = newValue
            stateLock.unlock()
        }
    }

    static var capturedRequests: [URLRequest] {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _capturedRequests
    }

    private static let stateLock = NSLock()
    private static var _requestHandler: RequestHandler?
    private static var _capturedRequests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let materializedRequest = Self.materializingBody(of: request)
        Self.capture(materializedRequest)

        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: APIError.network("Missing mock request handler."))
            return
        }

        do {
            let (response, data) = try handler(materializedRequest)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func reset() {
        stateLock.lock()
        _requestHandler = nil
        _capturedRequests = []
        stateLock.unlock()
    }

    private static func capture(_ request: URLRequest) {
        stateLock.lock()
        _capturedRequests.append(request)
        stateLock.unlock()
    }

    private static func materializingBody(of request: URLRequest) -> URLRequest {
        guard request.httpBody == nil, let stream = request.httpBodyStream else {
            return request
        }

        var copy = request
        copy.httpBody = readAll(from: stream)
        return copy
    }

    private static func readAll(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }

        return data
    }
}
