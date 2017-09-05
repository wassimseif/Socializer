//
//  AskCredentials.swift
//  Socializer
//
//  Created by Wassim on 7/4/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation
import RxSwift

/**
 
 AskCredential
 
 # Description
 
 This struct define the behavior when Socializer can't find how to provide token for request which need authorization.
 
 # Usage
 
 - Use triggerCondition to define for what error you need to call the handler.
 by default 401 error trigger handler.
 
 - Your provided handler must fetch new token and update the Socializer with it.
 
 */
public struct AskCredential {
    
    // MARK: - Type aliases
    
    public typealias AskCredentialHandler = (() -> Observable<Void>)
    public typealias AskCredentialTriggerCondition = ((Error) -> Bool)
    
    // MARK: - Properties
    
    public var triggerCondition: AskCredentialTriggerCondition
    public var handler: AskCredentialHandler
    
    // MARK: - Setup
    
    public init(triggerCondition: @escaping AskCredentialTriggerCondition, handler: @escaping AskCredentialHandler) {
        self.triggerCondition = triggerCondition
        self.handler = handler
    }
    
    public init(handler: @escaping AskCredentialHandler) {
        self.handler = handler
        self.triggerCondition = AskCredential.defaultTriggerCondition
    }
    
    // MARK: - Private
    
    private static func defaultTriggerCondition(error: Error) -> Bool {
        var shouldAskCredentials = false
        if case SocializerError.http(httpURLResponse: let httpURLResponse, data: _) = error, httpURLResponse.statusCode == 401 {
            shouldAskCredentials = true
        }
        return shouldAskCredentials
    }
    
}
