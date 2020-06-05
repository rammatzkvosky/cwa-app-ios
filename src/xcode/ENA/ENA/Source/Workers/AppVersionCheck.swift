//
// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import Foundation
import UIKit

class AppVersionCheck {

	let client: Client

    /// The retained `NotificationCenter` observer that listens for `UIApplication.didBecomeActiveNotification` notifications.
    var applicationDidBecomeActiveObserver: NSObjectProtocol?

	init(client:Client){
		self.client = client
	}
	deinit {
		NotificationCenter.default.removeObserver(applicationDidBecomeActiveObserver as Any)
        applicationDidBecomeActiveObserver = nil
	}

	func checkAppVersionDialog(for vc: UIViewController?) {
		client.appVersionConfiguration { result in
			do {
				let alert = UIAlertController(title: "Akutalisierung verfügbar", message: "Es gibt eine neue Aktualisierung für die Applikation", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("Aktualisieren", comment: "Default action"), style: .default, handler: { _ in
					//TODO: Add correct App Store ID
					let urlStr = "itms-apps://itunes.apple.com/app/apple-store/"
					UIApplication.shared.open(URL(string: urlStr)!, options: [:], completionHandler: nil)
				}))

				let versionInfo = try result.get()
				let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
				let minVersion = "\(versionInfo.ios.min.major).\(versionInfo.ios.min.minor).\(versionInfo.ios.min.patch)"
				let latestVersion = "\(versionInfo.ios.latest.major).\(versionInfo.ios.latest.minor).\(versionInfo.ios.latest.patch)"

				let checkMinVersion = appVersion?.compare(minVersion, options: .numeric)
				if checkMinVersion == .orderedAscending {
					alert.message = "Um die Applikation weiter zu nutzen müssen sie eine neue Version installieren"
					self.setObserver(vc: vc)
					vc?.present(alert, animated: true, completion: nil)
				} else {
					let checkLatestVersion = appVersion?.compare(latestVersion, options: .numeric)
					if checkLatestVersion == .orderedAscending {
						alert.addAction(UIAlertAction(title: NSLocalizedString("Später aktualisieren", comment: "Remind me later"), style: .default, handler: { _ in
						//Do nothing
						}))
						vc?.present(alert, animated: true, completion: nil)
					}
				}

			} catch {
				return
			}
		}
	}

	private func setObserver(vc: UIViewController?){
		guard self.applicationDidBecomeActiveObserver == nil else { return }
		self.applicationDidBecomeActiveObserver = NotificationCenter
			.default
			.addObserver(forName: UIApplication.didBecomeActiveNotification,
						 object: nil,
						 queue: nil) { [weak self] _ in
							guard let self = self else { return }
							self.checkAppVersionDialog(for: vc)
						}
	}
}
