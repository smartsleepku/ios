//
//  TokenService.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation

import KeychainAccess

fileprivate struct Token: Codable {
    var userId: String
    var session: String
}

class TokenService {
    private let keychain = Keychain(service: "dk.ku.sund.smartsleep")
    
    var token: String? {
        get {
            return keychain["token"]
        }
        set(value) {
            keychain["token"] = value
        }
    }
    
    var userId: String? {
        get {
            guard let parts = token?.split(separator: ".") else { return nil }
            var payload = String(parts[1])
            payload = payload.padding(toLength: ((payload.count+3)/4)*4,
                               withPad: "=",
                               startingAt: 0)
            guard let json = Data(base64Encoded: payload) else { return nil }
            let decoder = JSONDecoder()
            guard let parsed = try? decoder.decode(Token.self, from: json) else { return nil }
            return parsed.userId
        }
    }
    
}
