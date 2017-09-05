import Foundation
import RxSwift
import Alamofire
import ObjectMapper

public final class Socializer<T : SocializerErrorRespresentable> {
    // MARK: - Constants
    let authorizationHeaderKey = "Authorization"
    // MARK: - Type aliases
    let errorObjectTag = "error"
    
    public typealias AskCredentialHandler = (() -> Observable<Void>)
    
    public typealias RenewTokenHandler = (() -> Observable<Void>)
    
    // MARK: - Properties
    
    internal let disposeBag = DisposeBag()
    
    public var askCredential: AskCredential?
 
    internal let keychainService: KeychainService
    
    public let baseURL: String
    
    private var errorObject : T.Type!
    
    fileprivate var requestManager: Alamofire.SessionManager
    
    internal var uploadManager: Alamofire.SessionManager?
    
    public var delegate : SocializerDelegate = SocializerDelegate()
    
    public var uploadManagerSessionDelegate: Alamofire.SessionDelegate? {
        return uploadManager?.delegate
    }
    
    public var backgroundCompletionHandler: (() -> Void)? {
        get {
            return uploadManager?.backgroundCompletionHandler
        }set {
            uploadManager?.backgroundCompletionHandler = newValue
        }
    }
    
    public var askCredentialHandler: AskCredentialHandler?
    
    public var renewTokenHandler: RenewTokenHandler?
    
    
    // MARK: - Setup
    
    /// Inits the Socializer
    ///
    /// - Parameters:
    ///   - baseURL: the base URL for the webservice
    ///   - keychainService: the keychain service the would handle the web service authentication mechanism
    ///   - requestManager: Alamofire Manager that handles the requests. defautls to a NEW Alamofire manager
    ///   - uploadManager:  Alamofire Manager that handles the upload requests. defautls to nil
    ///   - askCredentialHandler: the ask credentials handler
    public init(baseURL: String,
                keychainService: KeychainService,
                defaultErrorObjet : T.Type,
                requestManager: Alamofire.SessionManager = Alamofire.SessionManager(),
                uploadManager: SessionManager? = nil,
                askCredentialHandler: AskCredentialHandler? = nil) {
        
        self.baseURL = baseURL
        self.keychainService = keychainService
        self.uploadManager = uploadManager
        self.requestManager = requestManager
        self.askCredentialHandler = askCredentialHandler
        self.errorObject = defaultErrorObjet
    }
}

// MARK: - Cancellation
extension Socializer {
    
    /// Disconnects the webservice. cancels all the requests
    ///
    /// - Returns: observable of void
    public func disconnect() -> Observable<Void> {
        return self.cancelAllRequest()
            .map({ [unowned self] () -> Void in
                return self.clearToken()
            })
    }
    
    /// internal function to cancel all the requests
    ///
    /// - Returns: observable of void 
    fileprivate func cancelAllRequest() -> Observable<Void> {
        delegate.didDisconnect.accept()
        return Observable.just()
            .map { () -> Void in
                self.resetRequestManager()
            }
            .flatMap { () -> Observable<Void> in
                return self.resetUploadManager()
        }
    }
    
    /// internal function to reset the request manager. creates a new manager fom the same configuration as the old one
    internal func resetRequestManager() {
        self.requestManager = self.recreateManager(manager: self.requestManager)
    }
    
    // TODO: Handle upload manager reset
    
    /// internal function to reset the upload request manager. creates a new manager fom the same configuration as the old one
    internal func resetUploadManager() -> Observable<Void> {
        guard let uploadManager = self.uploadManager else {
            return Observable.just()
        }
        
        let configuration = uploadManager.session.configuration
        
        return Observable.create { observer -> Disposable in
            let sessionDelegate = uploadManager.delegate
            sessionDelegate.sessionDidBecomeInvalidWithError = { (session: URLSession, error: Error?) -> Void in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext()
                }
            }
            uploadManager.session.invalidateAndCancel()
            
            return Disposables.create()
            }
            .map { [weak self] () -> Void in
                self?.uploadManager = SessionManager(configuration: configuration)
        }
    }
    
    /// internal function to recreate a new manager from the old one. resets the old one
    ///
    /// - Parameter manager: the old Session Manager
    /// - Returns: the new Session Manager. same configuration as the old one
    internal func recreateManager(manager: SessionManager) -> SessionManager {
        let configuration = manager.session.configuration
        manager.session.invalidateAndCancel()
        return SessionManager(configuration: configuration)
    }
}

// MARK: - Request building
extension Socializer {
    
    /// Builds the Alamofire.DataRequest
    ///
    /// - Parameters:
    ///   - method: Alamofire.HTTPMethod,
    ///   - route: a path conforming the the Routable protocol
    ///   - needsAuthorization: Sets whether the request need authorization or not .default to false
    ///   - parameters: the requests body parameters. default to nil
    ///   - headers: the request header Parameters. default to nil
    ///   - encoding: the encoding of the parameters. . default to JSONEncoding
    /// - Returns: DataRequest if building the requests is successful. nil otherwiswe
    public func request(method: Alamofire.HTTPMethod,
                        route: Routable,
                        needsAuthorization: Bool = false,
                        parameters: Alamofire.Parameters? = nil,
                        headers: Alamofire.HTTPHeaders? = nil,
                        encoding: Alamofire.ParameterEncoding = JSONEncoding.default) -> DataRequest? {
        guard let requestUrl = self.requestURL(route) else {
            return nil
        }
        
        let requestHeaders = self.requestHeaders(needsAuthorization: needsAuthorization, headers: headers)
        
        return self.requestManager.request(requestUrl,
                                           method: method,
                                           parameters: parameters,
                                           encoding: encoding,
                                           headers: requestHeaders)
    }
    
    /// Builds the requests from request parameters object. uses the request internal function
    ///
    /// - Parameter requestParameters: RequestParameters object
    /// - Returns: DataRequest if building the requests is successful. nil otherwiswe
    internal func buildRequest(requestParameters: RequestParameters) -> DataRequest? {
        return self.request(method: requestParameters.method,
                            route: requestParameters.route,
                            needsAuthorization: requestParameters.needsAuthorization,
                            parameters: requestParameters.parameters,
                            headers: requestParameters.headers,
                            encoding: requestParameters.parametersEncoding)
    }
    
    /// inits a URL object from a path by appending it to the base url
    ///
    /// - Parameter route: the path
    /// - Returns: URL object if building is successful. nil otherwise
    internal func requestURL(_ route: Routable) -> URL? {
        
        var urlString : String?
        switch route.isAbsolute {
        case true :
            urlString = route.path
        case false :
            urlString = self.baseURL + route.path
        }
        
        guard let requestUrl = URL(string: urlString!) else {
            return nil
        }
        return requestUrl
        
    }
    
    /// builds the request headers from an existing requests headers. adds the authorization parameters if needed
    ///
    /// - Parameters:
    ///   - needsAuthorization: boolean to specify whether authorization is needed for the request headers
    ///   - headers: the old request headers
    /// - Returns: Alamofire.HTTPHeaders defauls to empty
    internal func requestHeaders(needsAuthorization: Bool = false,
                                 headers: Alamofire.HTTPHeaders?) -> Alamofire.HTTPHeaders {
        var requestHeaders: Alamofire.HTTPHeaders
        if let headers = headers {
            requestHeaders = headers
        } else {
            requestHeaders = [:]
        }
        
        if needsAuthorization {
            let tokenValue = self.auhtorizationHeaderValue()
            if let tokenAutValue = tokenValue {
                requestHeaders[self.authorizationHeaderKey] = tokenAutValue
            }
        }
        if let headers = headers {
            for (key, value) in headers {
                requestHeaders[key] = value
            }
        }
        return requestHeaders
    }
    
    /// updates the authorization headers for an existing data reqeust
    ///
    /// - Parameter dataRequest: the old data reqeust
    /// - Returns: new datarequest
    internal func updateRequestAuthorizationHeader(dataRequest: Alamofire.DataRequest) -> Alamofire.DataRequest {
        guard let tokenValue = self.auhtorizationHeaderValue(), var newURLRequest = dataRequest.request else {
            return dataRequest
        }
        
        newURLRequest.setValue(tokenValue, forHTTPHeaderField: self.authorizationHeaderKey)
        return self.requestManager.request(newURLRequest)
    }
}

// MARK: - Request validation
extension Socializer {
    /// Validates the datareqeust's response code
    ///
    /// - Parameter request: old datareqeust
    /// - Returns: new datareqeust with validation
    fileprivate func validateRequest(request: Alamofire.DataRequest) -> Alamofire.DataRequest {
        return request.validate(statusCode: 200 ..< 300)
    }
}

// MARK: - Request
extension Socializer {
    
    
    /// sends a request from a request parameters object. DataRequest then sends if using the internal functions
    ///
    /// - Parameters:
    ///   - requestParameters: RequestsParameters object
    ///   - queue: DispatchQueue to send reqeust on
    ///   - responseSerializer: The Response Serializers
    /// - Returns: Obserable of HTTPURLResponse and the response serialized
    internal func sendRequest<T: DataResponseSerializerProtocol>(requestParameters: RequestParameters,
                              queue: DispatchQueue = DispatchQueue.global(qos: .default),
                              responseSerializer: T) -> Observable<(HTTPURLResponse, T.SerializedObject)> {
        guard let request = self.buildRequest(requestParameters: requestParameters) else {
            
            return Observable.error(SocializerError.requestBuildFail)
        }
        
        //            return self.sendAuthenticatedRequest(request: request, queue: queue, responseSerializer: responseSerializer)
        return self.sendRequest(alamofireRequest: request, queue: queue, responseSerializer: responseSerializer)
        
    }
    
    
    
    /// internal function to send the request
    ///
    /// - Parameters:
    ///   - alamofireRequest: DataRequest
    ///   - queue: DispatchQueue to send reqeust on
    ///   - responseSerializer: the resposne serializer to serialize the response
    /// - Returns: Observable of httpUrlResponse and serialzied response
    internal func sendRequest<T: DataResponseSerializerProtocol>(
        alamofireRequest: Alamofire.DataRequest,
        queue: DispatchQueue = DispatchQueue.global(qos: .default),
        responseSerializer: T)
        -> Observable<(HTTPURLResponse, T.SerializedObject)> {
            return Observable.create { [unowned self] observer in
                
                self.validateRequest(request: alamofireRequest)
                    .response(queue: queue, responseSerializer: responseSerializer) { [unowned self] (packedResponse: DataResponse<T.SerializedObject>) -> Void in
                        /*
                         if let response = packedResponse.response, let request = packedResponse.request {
                         self.delegate?.networkStack(self, didReceiveResponse: response, forRequest: request)
                         }
                         */
                        let result = packedResponse.result
                        switch result {
                            
                        case .success(let result):
                            if let httpResponse = packedResponse.response {
                                observer.onNext(httpResponse, result)
                            } else {
                                observer.onError(SocializerError.unknown)
                            }
                            observer.onCompleted()
                        case .failure(let error):
                            let socializerError = self.webserviceStackError(error: error, httpURLResponse: packedResponse.response, responseData: packedResponse.data)
                            observer.onError(socializerError)
                        }
                }
                return Disposables.create {
                    alamofireRequest.cancel()
                }
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(queue: queue))
    }
    
}
