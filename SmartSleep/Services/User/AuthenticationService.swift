//
//  AuthenticationService.swift
//  SmartSleep
//
//  Created by Anders Borch on 24/02/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import RxSwift
import KeychainAccess
import Crashlytics

fileprivate struct Token: Codable {
    var jwt: String
}

class AuthenticationService {
    
    enum AuthenticationError: Error {
        case invalidCode
        case networkError(error: Error)
        case httpStatus(code: Int)
        case missingData
    }
    
    struct AttendeeResult: Codable {
        let code: String
        let valid: Bool
    }
    
    struct AuthLoginBody: Codable {
        let email: String
        let password: String
        let clientId: String
        let clientSecret: String
        let attendeeCode: String?
    }
    
    private let keychain = Keychain(service: "dk.ku.sund.smartsleep")

    func validAttendee(code: String) -> Single<Bool> {
        return Single.create(subscribe: { event -> Disposable in
            guard let url = URL(string: baseUrl + "/auth/attendee/" + code) else {
                event(.error(AuthenticationError.invalidCode))
                return Disposables.create()
            }
            var request = URLRequest(url: url)
            request.setValue("ios", forHTTPHeaderField: "x-client-id")
            request.setValue(ClientSecret, forHTTPHeaderField: "x-client-secret")
            let session = URLSession(configuration: .ephemeral)
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                guard error == nil else {
                    NSLog("Failed validating attendee code: \(error!)")
                    event(.error(AuthenticationError.networkError(error: error!)))
                    return
                }
                let statusCode = (response as! HTTPURLResponse).statusCode
                guard statusCode == 200 else { event(.error(AuthenticationError.httpStatus(code: statusCode))) ; return }
                guard data != nil else { event(.error(AuthenticationError.missingData)) ;  return }
                let decoder = JSONDecoder()
                do {
                    let result = try decoder.decode(AttendeeResult.self, from: data!)
                    event(.success(result.valid))
                } catch let error {
                    event(.error(error))
                }
            })
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        })
    }
    
    func postCredentials(toAttendee code: String) {
        let manager = CredentialsService()
        guard let credentials = manager.credentials else { return }
        let url = URL(string: baseUrl + "/auth/attendee")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var session: URLSession? = URLSession(configuration: .ephemeral)
        let encoder = JSONEncoder()
        let login = AuthLoginBody(
            email: credentials.username,
            password: credentials.password,
            clientId: "ios",
            clientSecret: ClientSecret,
            attendeeCode: code
        )
        let json: Data
        do {
            json = try encoder.encode(login)
        } catch {
            Crashlytics.sharedInstance().recordError(error)
            Crashlytics.sharedInstance().crash()
            return
        }
        let task = session!.uploadTask(with: request, from: json) { (data, response, error) in
            // retain session until completion
            session = nil
            
            guard data != nil else { return }
            let decoder = JSONDecoder()
            guard let token = try? decoder.decode(Token.self, from: data!) else { return }
            TokenService().token = token.jwt
        }
        task.resume()
    }
    
}
