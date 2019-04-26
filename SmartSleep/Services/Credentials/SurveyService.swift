//
//  SurveyService.swift
//  SmartSleep
//
//  Created by Anders Borch on 02/03/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

import Foundation
import RxSwift

struct Survey: Codable {
    var sid: String
    var surveyls_title: String
    var startdate: Date?
    var expires: Date?
    var active: String
}

struct SurveyResult: Codable {
    var id: String
    var result: Array<Survey>
}

struct SessionKeyResult: Codable {
    var id: String
    var result: String
}

struct SurveyRequest: Codable {
    var id: String
    var method: String
    var params: Array<String>
}

class SurveyService {
    
    private let session = URLSession(configuration: .ephemeral)
    
    enum AuthenticationError: Error {
        case connectionError(error: Error)
        case httpStatus(code: Int)
        case missingData
    }

    func fetchSessionKey() -> Single<String> {
        return Single.create(subscribe: { event in
            let encoder = JSONEncoder()
            let url = URL(string: baseUrl + "/index.php/admin/remotecontrol/")!
            var request = URLRequest(url: url)
            request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? encoder.encode(SurveyRequest(
                id: "1",
                method: "get_session_key",
                params: ["admin", AdminCreds]
            ))
            let task = self.session.dataTask(with: request, completionHandler: { (data, response, error) in
                guard error == nil else { event(.error(AuthenticationError.connectionError(error: error!))) ;  return }
                let statusCode = (response as! HTTPURLResponse).statusCode
                guard statusCode == 200 else { event(.error(AuthenticationError.httpStatus(code: statusCode))) ; return }
                guard data != nil else { event(.error(AuthenticationError.missingData)) ;  return }
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(SessionKeyResult.self, from: data!)
                    event(.success(response.result))
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
    
    func fetchSurveys(sessionKey: String) -> Observable<Survey> {
        return Observable.create({ observable in
            let encoder = JSONEncoder()
            let url = URL(string: baseUrl + "/index.php/admin/remotecontrol/")!
            var request = URLRequest(url: url)
            request.setValue("Bearer " + (TokenService().token ?? ""), forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = try? encoder.encode(SurveyRequest(
                id: "1",
                method: "list_surveys",
                params: [sessionKey, "admin"]
            ))
            let task = self.session.dataTask(with: request, completionHandler: { (data, response, error) in
                guard error == nil else { observable.on(.error(AuthenticationError.connectionError(error: error!))) ;  return }
                let statusCode = (response as! HTTPURLResponse).statusCode
                guard statusCode == 200 else { observable.on(.error(AuthenticationError.httpStatus(code: statusCode))) ; return }
                guard data != nil else { observable.on(.error(AuthenticationError.missingData)) ;  return }
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(SurveyResult.self, from: data!)
                    response.result.forEach({ survey in
                        observable.on(.next(survey))
                    })
                } catch let error {
                    observable.on(.error(error))
                }
            })
            task.resume()
            return Disposables.create()
        })
    }
}
