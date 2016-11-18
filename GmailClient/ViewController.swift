//
//  ViewController.swift
//  GmailClient
//
//  Created by Pavel Nikitinskiy on 11/14/16.
//  Copyright © 2016 Pavel Nikitinskiy. All rights reserved.
//

import GoogleAPIClientForREST
import GTMOAuth2
import UIKit

class ViewController: UIViewController {
    
    private let kKeychainItemName = "Gmail API"
    private let kClientID = "805540983821-m037u7hmefs25e98k8pj40si7p5jkjrt.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeGmailReadonly]
    
    private let service = GTLRGmailService()
    let output = UITextView()
    
    // When the view loads, create necessary subviews
    // and initialize the Gmail API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        view.addSubview(output);
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain(forName: kKeychainItemName, clientID: kClientID, clientSecret: nil) {
            print("=========================2")
            service.authorizer = auth
        }
        
    }
    
    // When the view appears, ensure that the Gmail API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
        if let authorizer = service.authorizer,
            let canAuth = authorizer.canAuthorize , canAuth {
            fetchLabels()
        } else {
            print("=========================1")
            present(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }
    
    // Construct a query and get a list of upcoming labels from the gmail API
    func fetchLabels() {
        output.text = "Getting labels..."
        
        let query = GTLRGmailQuery_UsersLabelsList.query(withUserId: "me")
        service.executeQuery(query,
                             delegate: self,
                             didFinish: "displayResultWithTicket:finishedWithObject:error:"
        )
    }
    
    // Display the labels in the UITextView
    func displayResultWithTicket(ticket : GTLRServiceTicket,
                                 finishedWithObject labelsResponse : GTLRGmail_ListLabelsResponse,
                                 error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        var labelString = ""
        
        if (labelsResponse.labels?.count)! > 0 {
            labelString += "Labels:\n"
            for label in labelsResponse.labels! {
                labelString += "\(label.name!)\n"
            }
        } else {
            labelString = "No labels found."
        }
        
        output.text = labelString
        
    }
    
    
    // Creates the auth controller for authorizing access to Gmail API
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joined(separator: " ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: "viewController:finishedWithAuth:error:"
        )
    }
    
    // Handle completion of the authorization process, and update the Gmail API
    // with the new credentials.
    func viewController(vc : UIViewController, finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            service.authorizer = nil
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        dismiss(animated: true, completion: nil)
    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
