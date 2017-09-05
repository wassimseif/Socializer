//
//  Helper.swift
//  NetworkStack
//
//  Created by Wassim on 5/10/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation

/// This file contains function that will only help using NetworkStack, they're completely optional but i decided to add them since people might find them helpful


public extension NetworkStack{
    public typealias NetworkStackErrorHandlerResponse =  ( errorMessage : String ,   errorCode : Int )
    /// Handles the error from the API and try to get something that could be displayed to the user. must be used on the controller level
    ///
    /// - Parameter error: the error from the networkStack
    /// - Returns: NetworkStackErrorHandlerResponse
    public func handlerNetworkStackError(fromError error : Error) -> NetworkStackErrorHandlerResponse {
        
        let networkStackError = error as! NetworkStackError
        switch networkStackError {
        case .badServerResponse(error: _) ,
             .mappingError(response: _ , json: _) ,
             .parseError,
             .serverUnreachable(error: _):
            
            return ("Internal Server Error. Please try Again Later", 10001)
            
        case .requestBuildFail :
            
            return ("Internal Error. Please try Again Later", 10002)
            
        case .noInternet(error: _):
            return ("Internet connection is not active. Please try again later", 10003)
            
        case let .apiResponseError(error: apiError ):
            let apiError = apiError as! T
            
            return (apiError.errorMessage, apiError.errorCode)
        default:
            return ("Internal Error. Please try Again Later", 10004)
        }
        
    }
}
