//
//  ViewController.swift
//  ToastMessagesSwift
//
//  Created by Santhosh K on 25/08/22.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textTF: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func toastBtnAction(_ sender: UIButton) {
        if let text = self.textTF.text {
            if text == "" {
                DisplayToastView.shared.toast("Please enter any text")
            }
            else {
                DisplayToastView.shared.toast(text)
            }
        }
    }
    
}

