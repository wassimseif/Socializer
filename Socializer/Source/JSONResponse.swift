//
//  JSONResponse.swift
//  Tech-Stack
//
//  Created by Wassim on 5/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import ObjectMapper
// MARK: - JSON request
extension Socializer {
    
    /// models a json serializer
    ///
    /// - Returns: DataResponseSerializer
    internal func defaultJSONResponseSerializer() -> DataResponseSerializer<Any> {
        let jsonOption = JSONSerialization.ReadingOptions.allowFragments
        return DataRequest.jsonResponseSerializer(options: jsonOption)
    }
    
    /// Send a Request expecting JSON as a response
    ///     
    /// - Parameters:
    ///   - requestParameters: request parameters
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of httpUrlResponse and json
    @discardableResult
    public func sendRequestWithJSONResponse(requestParameters: RequestParameters,
                                            queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<(HTTPURLResponse, Any)> {
        let responseSerializer = self.defaultJSONResponseSerializer()
        return self.sendRequest(requestParameters: requestParameters,
                                queue: queue,
                                responseSerializer: responseSerializer)
    }
    
    /// Send a Request expecting a specific type as a response
    ///
    /// - Parameters:
    ///   - requestParams: request parameters
    ///   - responseObjectType: the type that the json should model
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of httpUrlResponse and type T
    @discardableResult
    public func sendRequestWithTypedResponse<T: Mappable>(withRequestParameters requestParams : RequestParameters,
                                             andResponseObjectType  responseObjectType : T.Type ) -> Observable<(HTTPURLResponse , T)>{
        return Observable.create{ [weak self] observer in

            let  queue : DispatchQueue = DispatchQueue.global(qos: .default)
            let responseSerializer = self!.defaultJSONResponseSerializer()
            let subscription = self!.sendRequest(requestParameters: requestParams,
                                                      queue: queue,
                                                      responseSerializer: responseSerializer)
                .subscribe(onNext: { (response , json) in
                    guard  let jsonDictionary = json as? [String : AnyObject] else {
                        observer.onError(SocializerError.mappingError(response: response, json: json))
                        observer.onCompleted()
                        return
                    }
                    guard let objectToEmit = Mapper<T>().map(JSON: jsonDictionary) else {
                        observer.onError(SocializerError.mappingError(response: response, json: json))
                        observer.onCompleted()
                        return
                    }
                    observer.onNext(response, objectToEmit)
                    observer.onCompleted()
                }, onError: { (error ) in
                    observer.onError(error)
                }, onCompleted: {
                    observer.onCompleted()
                }, onDisposed: {
                    observer.onCompleted()
                })
            return Disposables.create {
                subscription.dispose()
            }
        }
        
    }
    
    /// Send a Request expecting a specific type as a response array
    ///
    /// - Parameters:
    ///   - requestParams: request parameters
    ///   - responseObjectType: the type that the json should model
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of httpUrlResponse and type array of T
    @discardableResult
    public func sendRequestWithArrayTypedResponse<T : Mappable>(withRequestParameters requestParams : RequestParameters,
                                             andResponseObjectType responseObjectType : T.Type) -> Observable<(HTTPURLResponse, [T])>{
        return Observable.create{ [weak self ] observer in
            
            
            let  queue : DispatchQueue = DispatchQueue.global(qos: .default)
            let responseSerializer = self!.defaultJSONResponseSerializer()
            let subscription = self!.sendRequest(requestParameters: requestParams,
                                                 queue: queue,
                                                 responseSerializer: responseSerializer)
            .subscribe(onNext: { response, json in
//                if let jsonDictionary = json as? [[String : AnyObject]],
//                    let objectToEmit = Mapper<T>().mapArray(JSONArray: jsonDictionary)  {
//                    observer.onNext(response , objectToEmit)
//                } else {
//                    observer.onError(NetworkStackError.mappingError(response: response, json: json))
//                }
                
                
                guard let jsonDictionary = json as? [[String : AnyObject]] else {
                    observer.onError(SocializerError.mappingError(response: response, json: json))
                    observer.onCompleted()
                    return
                }
                let objectToEmit = Mapper<T>().mapArray(JSONArray: jsonDictionary)
                observer.onNext(response, objectToEmit)
                observer.onCompleted()
            }, onError: { (error ) in
                observer.onError(error)
            }, onCompleted: {
                observer.onCompleted()
            }, onDisposed: { 
                observer.onCompleted()
            })
            return Disposables.create {
                subscription.dispose()
            }
        }
    }
    /// Sends an upload request with JSON response
    ///
    /// - Parameters:
    ///   - uploadRequestParameters: upload request parameters
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of httpUrlResponse and JSON
    @discardableResult
    internal func sendUploadRequestWithJSONResponse(uploadRequestParameters: UploadRequestParameters,
                                                  queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<(HTTPURLResponse, Any)> {
        let responseSerializer = self.defaultJSONResponseSerializer()
        return self.sendUploadRequest(uploadRequestParameters: uploadRequestParameters,
                                      queue: queue,
                                      responseSerializer: responseSerializer)
    }
}
