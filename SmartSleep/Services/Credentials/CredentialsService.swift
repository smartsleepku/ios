//
//  CredentialsService.swift
//  SmartSleep
//
//  Created by Anders Borch on 23/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import KeychainAccess

struct Credentials: Codable {
    var username: String
    var password: String
}

class CredentialsService {
    private let keychain = Keychain(service: "dk.ku.sund.smartsleep")
    
    var credentials: Credentials? {
        get {
            let ud = UserDefaults()
            guard let username: String = ud.valueFor(.username) else { return nil }
            guard let password = keychain[username] else { return nil }
            return Credentials(
                username: username,
                password: password
            )
        }
        set(value) {
            if let creds = value {
                let ud = UserDefaults()
                ud.setValueFor(.username, to: creds.username)
                ud.synchronize()
                keychain[creds.username] = creds.password
            }
        }
    }
}
