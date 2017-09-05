//
//  OAuth.swift
//  Tech-Stack
//
//  Created by Wassim on 5/8/17.
//  Copyright © 2017 Wassim. All rights reserved.
//
import Foundation
import RxSwift
import Alamofire
import ObjectMapper
// MARK: - OAuth
extension Socializer {
    /// Returns the access token only if available and NOT expired
    ///
    /// - Returns: accesstoken string if available and NOT expired nil otherwise
    internal func auhtorizationHeaderValue() -> String? {
        guard let accessToken = self.keychainService.accessToken, self.keychainService.isAccessTokenValid else {
            return nil
        }
        return "Bearer \(accessToken)"
    }
    
    /// Clears accesstoken , refreshtoken and expiration interval
    public func clearToken() {
        self.keychainService.accessToken = nil
        self.keychainService.refreshToken = nil
        self.keychainService.expirationInterval = nil
    }
    
    /// Updates the keychain servies credentials
    ///
    /// - Parameters:
    ///   - token: the new accesstoken
    ///   - refreshToken: the new refresh token
    ///   - expiresIn: the new expiry date of the accesstoken
    public func updateToken(token: String, refreshToken: String? = nil, expiresIn: TimeInterval? = nil) {
        print("\(#function) \(#line)  accesstoken : \(token)")
        self.keychainService.accessToken = token
        self.keychainService.refreshToken = refreshToken
        self.keychainService.expirationInterval = expiresIn
    }
    
    // Returns true if token is expired, and the app should show the authentication view
    public func isTokenExpired() -> Bool {
        return self.keychainService.isAccessTokenValid == false
    }
    
    /// Returns the current accesstoken
    ///
    /// - Returns: accesstoken as string
    public func currentAccessToken() -> String? {
        return self.keychainService.accessToken
    }
    /// Returns the current refreshtoken
    ///
    /// - Returns: refreshtoken as string
    public func currentRefreshToken() -> String? {
        return self.keychainService.refreshToken
    }
}
