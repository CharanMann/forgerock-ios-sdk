//
//  AuthServiceTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class AuthServiceTests: FRBaseTest {

    var serverURL = "http://localhost:8080/am"
    var realm = "customRealm"
    var timeout = 90.0
    var authServiceName = "loginService"
    
    var clientId = "a09a42d7-b2f2-47f2-a3eb-a3c15e8008e8"
    var scope = "openid email phone"
    var redirectUri = "http://redirect.uri"
    
    func testAuthServicePublicInit() {
        
        // Given
        let serverConfig = ServerConfig(url: URL(string: self.serverURL)!, realm: self.realm, timeout: self.timeout)
        let authService: AuthService = AuthService(name: "loginService", serverConfig: serverConfig)
        
        // Then
        XCTAssertEqual(authService.serviceName, self.authServiceName)
        XCTAssertEqual(authService.serverConfig.baseURL.absoluteString, self.serverURL)
        XCTAssertEqual(authService.serverConfig.treeURL, self.serverURL + "/json/realms/\(self.realm)/authenticate")
        XCTAssertEqual(authService.serverConfig.tokenURL, self.serverURL + "/oauth2/realms/\(self.realm)/access_token")
        XCTAssertEqual(authService.serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/\(self.realm)/authorize")
        XCTAssertEqual(authService.serverConfig.timeout, 90)
        XCTAssertEqual(authService.serverConfig.realm, self.realm)
        XCTAssertNil(authService.oAuth2Config)
    }
    
    func testAuthServicePrivateInit() {
        // Given
        let serverConfig = ServerConfig(url: URL(string: self.serverURL)!, realm: self.realm, timeout: self.timeout)
        let oAuth2Client = OAuth2Client(clientId: self.clientId, scope: self.scope, redirectUri: URL(string: self.redirectUri)!, serverConfig: serverConfig)
        let authService: AuthService = AuthService(name: "loginService", serverConfig: serverConfig, oAuth2Config: oAuth2Client)
        
        // Then
        XCTAssertEqual(authService.serviceName, self.authServiceName)
        XCTAssertEqual(authService.serverConfig.baseURL.absoluteString, self.serverURL)
        XCTAssertEqual(authService.serverConfig.treeURL, self.serverURL + "/json/realms/\(self.realm)/authenticate")
        XCTAssertEqual(authService.serverConfig.tokenURL, self.serverURL + "/oauth2/realms/\(self.realm)/access_token")
        XCTAssertEqual(authService.serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/\(self.realm)/authorize")
        XCTAssertEqual(authService.serverConfig.timeout, 90)
        XCTAssertEqual(authService.serverConfig.realm, "customRealm")
        XCTAssertNotNil(authService.oAuth2Config)
        XCTAssertEqual(authService.oAuth2Config?.clientId, self.clientId)
        XCTAssertEqual(authService.oAuth2Config?.redirectUri.absoluteString, self.redirectUri)
        XCTAssertEqual(authService.oAuth2Config?.scope, self.scope)
    }
}
