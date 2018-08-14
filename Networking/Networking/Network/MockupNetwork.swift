import Foundation
import Alamofire


/// Network Mockup: Allows us to simulate HTTP Responses.
///
class MockupNetwork: Network {

    /// Mapping between URL Suffix and JSON Mockup responses.
    ///
    private var responseMap = [String: String]()

    /// Mapping between URL Suffix and Error responses.
    ///
    private var errorMap = [String: Error]()

    /// Keeps a collection of all of the `responseJSON` requests.
    ///
    var requestsForResponseJSON = [URLRequestConvertible]()

    /// Keeps a collection of all of the `responseData` requests.
    ///
    var requestsForResponseData = [URLRequestConvertible]()




    /// Public Initializer
    ///
    required init(credentials: Credentials) { }

    /// Dummy convenience initializer. Remember: Real Network wrappers will allways need credentials!
    ///
    convenience init() {
        let dummy = Credentials(username: "", authToken: "")
        self.init(credentials: dummy)
    }


    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response, *PARSED* as json.
    /// Otherwise, an error will be relayed back (.unavailable!).
    ///
    func responseJSON(for request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        requestsForResponseJSON.append(request)

        if let error = error(for: request) {
            completion(nil, error)
            return
        }

        if let filename = filename(for: request), let response = Loader.jsonObject(for: filename) {
            completion(response, nil)
            return
        }

        completion(nil, NetworkError.unknown)
    }

    /// Whenever the Request's URL matches any of the "Mocked Up Patterns", we'll return the specified response file, loaded as *Data*.
    /// Otherwise, an error will be relayed back (.unavailable!).
    ///
    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        requestsForResponseData.append(request)

        if let error = error(for: request) {
            completion(nil, error)
            return
        }

        if let filename = filename(for: request), let data = Loader.contentsOf(filename) {
            completion(data, nil)
            return
        }

        completion(nil, NetworkError.unknown)
    }
}


/// Public Methods
///
extension MockupNetwork {

    /// Whenever a request is enqueued, we'll return the specified JSON Encoded file, whenever the Request's URL suffix matches with
    /// the specified one.
    ///
    func simulateResponse(requestUrlSuffix: String, filename: String) {
        responseMap[requestUrlSuffix] = filename
    }

    /// We'll return the specified Error, whenever a request matches the specified Suffix Criteria!.
    ///
    func simulateError(requestUrlSuffix: String, error: Error) {
        errorMap[requestUrlSuffix] = error
    }

    /// Removes all of the stored Simulated Responses.
    ///
    func removeAllSimulatedResponses() {
        responseMap.removeAll()
        errorMap.removeAll()
    }

    /// Returns the Mockup JSON Filename for a given URLRequestConvertible.
    ///
    private func filename(for request: URLRequestConvertible) -> String? {
        let searchPath = path(for: request)
        for (pattern, filename) in responseMap where searchPath.hasSuffix(pattern) {
            return filename
        }

        return nil
    }

    /// Returns the Mockup Error for a given URLRequestConvertible.
    ///
    private func error(for request: URLRequestConvertible) -> Error? {
        let searchPath = path(for: request)
        for (pattern, error) in errorMap where searchPath.hasSuffix(pattern) {
            return error
        }

        return nil
    }

    /// Returns the "Request Path" for a given URLRequestConvertible instance.
    ///
    private func path(for request: URLRequestConvertible) -> String {
        switch request {
        case let request as AuthenticatedRequest:
            return path(for: request.request)
        case let request as JetpackRequest:
            return request.path
        case let request as DotcomRequest:
            return request.path
        default:
            let targetURL = try! request.asURLRequest().url?.absoluteString
            return targetURL ?? ""
        }
    }
}
