//
//  UploadRequest.swift
//  Tech-Stack
//
//  Created by Wassim on 5/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//


import Foundation
import RxSwift
import Alamofire
import ObjectMapper
// MARK: - Upload request
extension Socializer {
    
    /// Sends an upload request
    ///
    /// - Parameters:
    ///   - uploadRequestParameters: Upload Request Parameters
    ///   - queue: DispatchQueue to send reqeust on
    ///   - responseSerializer: The response serializer to serialize the response
    /// - Returns: observable of the response serialized
    internal func sendUploadRequest<T: DataResponseSerializerProtocol>(uploadRequestParameters: UploadRequestParameters,
                                    queue: DispatchQueue = DispatchQueue.global(qos: .default),
                                    responseSerializer: T) -> Observable<(HTTPURLResponse, T.SerializedObject)> {
        
        let requestHeaders = self.requestHeaders(needsAuthorization: uploadRequestParameters.needsAuthorization,
                                                 headers: uploadRequestParameters.headers)
        
        return Observable.create({ (observer) -> Disposable in
            guard let requestURL = self.requestURL(uploadRequestParameters.route) else {
                observer.onError(SocializerError.requestBuildFail)
                return Disposables.create()
            }
            
            guard let uploadManager = self.uploadManager else {
                observer.onError(SocializerError.uploadManagerIsNotSet)
                return Disposables.create()
            }
            
            uploadManager.upload(multipartFormData: { [weak self] (multipartFormData) in
                self?.enrichMultipartFormData(multipartFormData: multipartFormData,
                                              from: uploadRequestParameters)
                }, to: requestURL.absoluteString,
                   headers: requestHeaders,
                   encodingCompletion: { (encodingResult) in
                    switch encodingResult {
                    case .success(let uploadRequest, _, _):
                        observer.onNext(uploadRequest)
                        observer.onCompleted()
                    case .failure(let encodingError):
                        observer.onError(encodingError)
                    }
            })
            
            return Disposables.create()
        })
            .flatMap { [unowned self] uploadRequest -> Observable<(HTTPURLResponse, T.SerializedObject)> in
                return self.sendRequest(alamofireRequest: uploadRequest, queue: queue, responseSerializer: responseSerializer)
        }
    }
    
    /// Sends an upload request in background
    ///
    /// - Parameters:
    ///   - uploadRequestParameters: Upload Request Parameters
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of URLSessionTask
    public func sendBackgroundUploadRequest(uploadRequestParameters: UploadRequestParameters,
                                            queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<URLSessionTask> {
        return Observable.create({ [unowned self] (observer) -> Disposable in
            
            guard let requestURL = self.requestURL(uploadRequestParameters.route) else {
                observer.onError(SocializerError.requestBuildFail)
                return Disposables.create()
            }
            
            guard let uploadManager = self.uploadManager else {
                observer.onError(SocializerError.uploadManagerIsNotSet)
                return Disposables.create()
            }
            
            let requestHeaders = self.requestHeaders(needsAuthorization: uploadRequestParameters.needsAuthorization,
                                                     headers: uploadRequestParameters.headers)
            
            uploadManager.upload(multipartFormData: { [weak self] (multipartFormData) in
                self?.enrichMultipartFormData(multipartFormData: multipartFormData, from: uploadRequestParameters)
                }, to: requestURL.absoluteString,
                   headers: requestHeaders,
                   encodingCompletion: {  (encodingResult) in
                    switch encodingResult {
                    case .success(let uploadRequest, _, _):
                        if let urlSessionTask = uploadRequest.task {
                            observer.onNext(urlSessionTask)
                            observer.onCompleted()
                        }
                    case .failure(let error):
                        observer.onError(error)
                    }
            })
            
            return Disposables.create()
        })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: queue))
    }
    
    /// upload request with multipart form data
    ///
    /// - Parameters:
    ///   - multipartFormData: the Multipart form data
    ///   - uploadRequestParameters: Upload Request Parameters
    fileprivate func enrichMultipartFormData(multipartFormData: MultipartFormData,
                                             from uploadRequestParameters: UploadRequestParameters) {
        
        for fileToUpload in uploadRequestParameters.uploadFiles {
            multipartFormData.append(fileToUpload.fileURL,
                                     withName: fileToUpload.parameterName,
                                     fileName: fileToUpload.fileName,
                                     mimeType: fileToUpload.mimeType)
        }
        guard let params = uploadRequestParameters.parameters else {
            return
        }
        
        for (key, value) in params {
            let data: Data?
            
            switch value {
            case let valueData as Data:
                data = valueData
            case let valueString as String:
                data = valueString.data(using: String.Encoding.utf8)
            default:
                let strValue = String(describing: value)
                data = strValue.data(using: String.Encoding.utf8)
            }
            
            if let data = data {
                multipartFormData.append(data, withName: key)
            }
        }
    }
}
