//
//  ErrorManager.swift
//  Tech-Stack
//
//  Created by Wassim on 5/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import ObjectMapper
// MARK: - Error management
/// Just to organize what can be considered as an error
public protocol SocializerErrorRespresentable : Error, Mappable  {
    
    var errorMessage : String { get }
    
    var errorCode : Int { get }
    
}

extension Socializer {
    
    /// Handles the errors from the web services
    ///
    /// - Parameters:
    ///   - error: Error
    ///   - httpURLResponse: the HTTPURLResponse
    ///   - responseData: The raw response from the web service
    /// - Returns: Socializer error representing the error
    internal func webserviceStackError(error: Error,
                                       httpURLResponse: HTTPURLResponse?,
                                       responseData: Data?) -> SocializerError {
        
        let finalError: SocializerError
        
        let nserror = error as NSError
        
        switch nserror.code {
            
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorCannotLoadFromNetwork,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorCallIsActive,
             NSURLErrorInternationalRoamingOff,
             NSURLErrorDataNotAllowed,
             NSURLErrorTimedOut:
            
            finalError = SocializerError.noInternet(error: nserror)
            
        case NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorRedirectToNonExistentLocation:
            
            finalError = SocializerError.serverUnreachable(error: nserror)
            
        case NSURLErrorBadServerResponse,
             NSURLErrorCannotParseResponse,
             NSURLErrorCannotDecodeContentData,
             NSURLErrorCannotDecodeRawData:
            
            finalError = SocializerError.badServerResponse(error: nserror)
            
        default:
            
            finalError = handlerOtherErrors(withError: nserror, andHTTPResponseResponse: httpURLResponse , andResponseData:  responseData)
        }
        
        return finalError
        
    }
    
    
    
    /// Just returns the json from Data
    ///
    /// - Parameter data: data
    /// - Returns: json
    func getJson(fromData data : Data?)-> [String : Any]?{
        guard data != nil else {
            return nil  
        }
        
        let json = try? JSONSerialization.jsonObject(with: data!, options: [] ) as! [String : Any]
        
        return json
    }
    
    func tryToParseDefaultError(fromJSON json : [String : Any]) -> T?{
        
        guard let errorObject = Mapper<T>().map(JSON: json) else {
            return nil
        }
        return errorObject
        
    }
    
    func handlerOtherErrors(withError error : NSError,
                            andHTTPResponseResponse httpURLResponse   : HTTPURLResponse? ,
                            andResponseData responseData : Data?) ->SocializerError{
        
        let returnError: SocializerError
        
        guard  let httpURLResponse = httpURLResponse else{
            return SocializerError.unknown
        }
        
        guard  let json = getJson(fromData: responseData) else {
            return SocializerError.parseError
            
        }
        //Should try to parse the default error to abstract the error code for the default error
        if let errorObject = tryToParseDefaultError(fromJSON: json) {
            return SocializerError.apiResponseError(error: errorObject)
        }
    
        
        if  400..<600 ~= httpURLResponse.statusCode {
            returnError = SocializerError.http(httpURLResponse: httpURLResponse, data: responseData)
        } else {
            returnError = SocializerError.otherError(error: error)
        }
        return returnError
    }

}

