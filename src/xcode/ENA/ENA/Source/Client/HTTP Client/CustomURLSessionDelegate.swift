//
//  CustomURLSessionDelegate.swift
//  ENA
//
//  Created by Schmitz, Christopher on 30.05.20.
//  Copyright © 2020 SAP SE. All rights reserved.
//

import Foundation

class CustomURLSessionDelegate : NSObject, URLSessionDelegate{
	func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		
		var error: UnsafeMutablePointer<CFError?>?
		
		guard
			challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
			let serverTrust = challenge.protectionSpace.serverTrust,
			
			SecTrustEvaluateWithError(serverTrust,error),
			
			let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0)
		
			else {
				reject(with: completionHandler)
				return
		}
		
		let connectionServerCertData = SecCertificateCopyData(serverCert) as Data
		
		guard
			let localCertPath = Bundle.main.path(forResource: certificateNameFor(host: challenge.protectionSpace.host), ofType: "der"),
			let localCertData = NSData(contentsOfFile: localCertPath) as Data?,
			localCertData == connectionServerCertData else {
				
				reject(with: completionHandler)
				return
		}
		accept(with: serverTrust, completionHandler)
	}

	func reject(with completionHandler: ((URLSession.AuthChallengeDisposition, URLCredential?) -> Void)) {
		completionHandler(.cancelAuthenticationChallenge, nil)
	}

	func accept(with serverTrust: SecTrust, _ completionHandler: ((URLSession.AuthChallengeDisposition, URLCredential?) -> Void)) {
		completionHandler(.useCredential, URLCredential(trust: serverTrust))
	}
	
	func certificateNameFor(host: String) -> String{
// Mark: whitelist individual landscapes. Host -> SubmissionService
		return host
	}
}
