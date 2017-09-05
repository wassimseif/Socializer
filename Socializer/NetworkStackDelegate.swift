//
//  NetworkStackDelegate.swift
//  NetworkStack
//
//  Created by Wassim on 8/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//

import Foundation
import RxRelay
import Alamofire

public protocol ResponseAdaptable {}

extension Result : ResponseAdaptable {}

public class NetworkStackDelegate {
    
    public var didFailToBuildRequest = PublishRelay<RequestParameters>()
    
    public var didSendRequest  = PublishRelay<DataRequest>()
    
    public var didDisconnect = PublishRelay<Void>()
    
}
