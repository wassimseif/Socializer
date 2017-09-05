//
//  DataRequest.swift
//  Tech-Stack
//
//  Created by Wassim on 5/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import ObjectMapper
// MARK: - Data request
extension Socializer {
    
    /// Send a Request expecting Data as a response
    ///
    /// - Parameters:
    ///   - requestParameters: request Parameters
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of httpUrlResponse and Data
    public func sendRequestWithDataResponse(requestParameters: RequestParameters,
                                            queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<(HTTPURLResponse, Data)> {
        let responseSerializer = DataRequest.dataResponseSerializer()
        return self.sendRequest(requestParameters: requestParameters,
                                queue: queue,
                                responseSerializer: responseSerializer)
    }
    
    
    /// Sends an upload request with Data response
    ///
    /// - Parameters:
    ///   - uploadRequestParameters: Upload Request Parameters
    ///   - queue: DispatchQueue to send reqeust on
    /// - Returns: Observable of httpUrlResponse and Data
    public func sendUploadRequestWithDataResponse(uploadRequestParameters: UploadRequestParameters,
                                                  queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<(HTTPURLResponse, Data)> {
        let responseSerializer = DataRequest.dataResponseSerializer()
        return self.sendUploadRequest(uploadRequestParameters: uploadRequestParameters,
                                      queue: queue,
                                      responseSerializer: responseSerializer)
    }
}

