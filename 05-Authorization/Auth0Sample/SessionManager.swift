// SessionManager.swift
// Auth0Sample
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import SimpleKeychain
import Auth0

class SessionManager {
    static let shared = SessionManager()
    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    var profile: Profile?

    private init () { }

    func store(credentials: Credentials) -> Bool {
        return self.credentialsManager.store(credentials: credentials)
    }

    func profile(_ callback: @escaping (Error?, Profile?) -> ()) {
        self.credentials { error, credentials in
            guard error == nil else { return callback(error, nil) }
            guard let accessToken = credentials?.accessToken else { return callback(CredentialsManagerError.noCredentials, nil) }
            Auth0
                .authentication()
                .userInfo(token: accessToken)
                .start { result in
                    switch(result) {
                    case .success(let profile):
                        self.profile = profile
                        callback(nil, profile)
                    case .failure(let error):
                        callback(error, nil)
                    }
            }
        }
    }

    func credentials(callback: @escaping (Error?, Credentials?) -> Void) {
        self.credentialsManager.credentials { error, credentials in
            callback(error, credentials)
        }
    }

    func logout() {
        A0SimpleKeychain().clearAll()
    }
    
}
