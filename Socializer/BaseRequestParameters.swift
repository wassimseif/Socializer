//
//  BaseRequestParameters.swift
//
//  Copyright © 2017 Niji. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Alamofire

public class BaseRequestParameters : NSObject{
  public var method: Alamofire.HTTPMethod
  public var route: Routable
  public var needsAuthorization: Bool
  public var parameters: Alamofire.Parameters? = nil
  public var headers: Alamofire.HTTPHeaders?
  
  public init(method: Alamofire.HTTPMethod,
       route: Routable,
       needsAuthorization: Bool = false,
       parameters: Alamofire.Parameters? = nil,
       headers: Alamofire.HTTPHeaders? = nil) {
    self.method = method
    self.route = route
    self.needsAuthorization = needsAuthorization
    self.parameters = parameters
    self.headers = headers
  }
    public override var description: String {
        return "\(self.method) on \(self.route.path) \(self.needsAuthorization == true ? "with" : "without") authorization \(self.parameters != nil ? "with" : "without") parameters and \(self.headers != nil ? "with" : "without") headers "
    }
}
