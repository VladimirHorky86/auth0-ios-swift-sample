// ProfileViewController.swift
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

import UIKit
import Auth0
import SimpleKeychain

class ProfileViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!

    var profile: Profile!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        profile = SessionManager.shared.profile
        self.welcomeLabel.text = "Welcome, \(self.profile.name)"
        let task = URLSession.shared.dataTask(with: self.profile.pictureURL) { (data, response, error) in
            guard let data = data , error == nil else { return }
            DispatchQueue.main.async {
                self.avatarImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }

    @IBAction func logout(_ sender: UIBarButtonItem) {
        SessionManager.shared.logout()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func checkUserRole(sender: UIButton) {
        SessionManager.shared.credentials { error, credentials in
            guard error == nil else {
                DispatchQueue.main.async {
                    print("Error: \(String(describing: error))")
                    self.showAccessDeniedAlert()
                }
                return
            }
            guard let idToken = credentials?.idToken else {
                DispatchQueue.main.async {
                    print("No idToken")
                    self.showAccessDeniedAlert()
                }
                return
            }
            Auth0
                .users(token: idToken)
                .get(self.profile.id, fields: [], include: true)
                .start { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let user):
                            guard
                                let appMetadata = user["app_metadata"] as? [String: Any],
                                let roles = appMetadata["roles"] as? [String],
                                let role = roles.first, role == "admin"
                                else {
                                    return self.showAccessDeniedAlert()
                            }
                            self.showAdminPanel()
                        case .failure(let error):
                            print("Error: \(error)")
                            return self.showAccessDeniedAlert()
                        }
                    }
            }
        }
    }

    private func showAdminPanel() {
        self.performSegue(withIdentifier: "ShowAdminPanel", sender: nil)
    }

    private func showAccessDeniedAlert() {
        let alert = UIAlertController.alert(title: "Access denied", message: "You do not have privileges to access the admin panel", includeDoneButton: true)
        self.present(alert, animated: true, completion: nil)
    }

    private func showErrorRetrievingUserAlert() {
        let alert = UIAlertController.alert(title: "Error", message: "Could not retrieve user from server", includeDoneButton: true)
        self.present(alert, animated: true, completion: nil)
    }
}
