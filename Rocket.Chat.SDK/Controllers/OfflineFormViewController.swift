//
//  OfflineFormViewController.swift
//  Rocket.Chat
//
//  Created by Lucas Woo on 7/16/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import UIKit

class OfflineFormViewController: UITableViewController, LiveChatManagerInjected {

    var injectionContainer: InjectionContainer!

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = livechatManager.offlineTitle
    }

    // MARK: - Actions
    @IBAction func didTouchCancelButton(_ sender: UIBarButtonItem) {
        dismissSelf()
    }

    func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func didTouchSendButton(_ sender: UIButton) {
        guard let email = emailField.text else {
            return
        }
        guard let name = nameField.text else {
            return
        }
        guard let message = messageTextView.text else {
            return
        }
        activityIndicator.startAnimating()
        livechatManager.sendOfflineMessage(email: email, name: name, message: message) {
            self.activityIndicator.stopAnimating()
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

}

extension OfflineFormViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
}
