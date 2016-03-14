//
//  AuthenticationContainerView.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/23/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

class AuthenticationContainerView: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate
{
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var tapView: UIView!
    
    @IBOutlet weak var firstNameTxtField: UITextField!
    @IBOutlet weak var lastNameTxtField: UITextField!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var usernameTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    let kinveyBackend = KinveyBackend()
    var tappedTextField : UITextField?
    var multiplier: CGFloat = 1
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userRegistered",
                                                                name: "UserRegistered", object: nil)

        let tapRecognizer = UITapGestureRecognizer(target: self, action:Selector("handleTap:"))
            tapRecognizer.delegate = self
        tapView.addGestureRecognizer(tapRecognizer)
        
        var backImg = ""
        
        if Device.IS_IPHONE_4
        {
            backImg = "iphone4_back"
        }
        
        if Device.IS_IPHONE_5
        {
            backImg = "iphone5_back"
        }
        
        if Device.IS_IPHONE_6
        {
            backImg = "iphone6_back"
            multiplier = Constants.multiplier6
            adjustForBiggerScreen()
        }
        else if Device.IS_IPHONE_6_PLUS
        {
            backImg = "iphone6plus_back"
            multiplier = Constants.multiplier6plus
            adjustForBiggerScreen()
        }
        
        let path = NSBundle.mainBundle().pathForResource(backImg, ofType:"jpg")
        background.image = UIImage(contentsOfFile: path!)
        
        if Device.IS_IPHONE_4 || Device.IS_IPHONE_6 || Device.IS_IPHONE_6_PLUS
        {
            containerHeightConstraint.constant = self.view.frame.size.height
        }
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Notifications
    //-------------------------------------------------------------------------//
    
    func userRegistered()
    {
        Auxiliar.hideLoadingHUDInView(self.view)
        
        self.firstNameTxtField.text = "FIRST NAME"
        self.lastNameTxtField.text = "LAST NAME"
        self.emailTxtField.text = "EMAIL"
        self.usernameTxtField.text = "USERNAME"
        self.passwordTxtField.text = "PASSWORD"
        
        NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Kinvey Sign Up
    //-------------------------------------------------------------------------//
    
    @IBAction func signUpButtonTapped(sender: UIButton)
    {
        removeKeyboard()
        
        guard Reachability.connectedToNetwork() else
        {
            Auxiliar.presentAlertControllerWithTitle("No Internet Connection",
                andMessage: "Make sure your device is connected to the internet.",
                forViewController: self)
            return
        }
        
        let firstName = firstNameTxtField.text!
        let lastName = lastNameTxtField.text!
        let email = emailTxtField.text!
        let username = usernameTxtField.text!
        let password = passwordTxtField.text!
        
        if ((firstName != "") && (firstName != "FIRST NAME")) &&
           ((lastName != "") && (lastName != "LAST NAME")) &&
           ((email != "") && (email != "EMAIL")) &&
           ((username != "") && (username != "USERNAME")) &&
           ((password != "") && (password != "PASSWORD"))
        {
            Auxiliar.showLoadingHUDWithText("Signing up...", forView: self.view)
            
            kinveyBackend.signUpUser(firstName, lastName: lastName, email: email,
                username: username, password: password, completion: {
                    
                [unowned self](status, errorMessage) -> Void in
                
                if status == "Success"
                {
                    self.finalizeProcess()
                }
                else
                {
                    Auxiliar.hideLoadingHUDInView(self.view)
                    Auxiliar.presentAlertControllerWithTitle(status, andMessage: errorMessage,
                                                                forViewController: self)
                }
            })
        }
        else
        {
            Auxiliar.presentAlertControllerWithTitle("Error",
                andMessage: "Please fill in all fields", forViewController: self)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Kinvey Sign In
    //-------------------------------------------------------------------------//
    
    @IBAction func signInButtonTapped(sender: UIButton)
    {
        removeKeyboard()
        
        guard Reachability.connectedToNetwork() else
        {
            Auxiliar.presentAlertControllerWithTitle("No Internet Connection",
                andMessage: "Make sure your device is connected to the internet.",
                forViewController: self)
            return
        }
        
        let username = usernameTxtField.text!
        let password = passwordTxtField.text!
        
        if ((username != "") && (username != "USERNAME")) &&
           ((password != "") && (password != "PASSWORD"))
        {
            Auxiliar.showLoadingHUDWithText("Signing in...", forView: self.view)
            
            kinveyBackend.signInUser(username, password: password, completion: {
                
                [unowned self](status, errorMessage) -> Void in
                
                if status == "Success"
                {
                    self.finalizeProcess()
                }
                else
                {
                    Auxiliar.hideLoadingHUDInView(self.view)
                    Auxiliar.presentAlertControllerWithTitle(status, andMessage: errorMessage,
                                                                forViewController: self)
                }
            })
        }
        else
        {
            Auxiliar.presentAlertControllerWithTitle("Error",
                andMessage: "Please insert username and password", forViewController: self)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Finalize Sign In/Sign Up process
    //-------------------------------------------------------------------------//
    
    func finalizeProcess()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if defaults.objectForKey("RegisteredNotificationSettings") == nil
        {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.registerUserForPushNotifications()
        }
        else
        {
            Auxiliar.hideLoadingHUDInView(self.view)
            
            firstNameTxtField.text = "FIRST NAME"
            lastNameTxtField.text = "LAST NAME"
            emailTxtField.text = "EMAIL"
            usernameTxtField.text = "USERNAME"
            passwordTxtField.text = "PASSWORD"
            
            NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UITextFieldDelegate
    //-------------------------------------------------------------------------//
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        if (textField.text == "FIRST NAME") || (textField.text == "LAST NAME") ||
           (textField.text == "EMAIL") || (textField.text == "USERNAME") ||
           (textField.text == "PASSWORD")
        {
            textField.text = ""
        }
        
        tappedTextField = textField
        
        let textFieldY = tappedTextField!.frame.origin.y
        let textFieldHeight = tappedTextField!.frame.size.height
        let total = textFieldY + textFieldHeight
        
        if total > (self.view.frame.size.height/2)
        {
            let difference = total - (self.view.frame.size.height/2)
            let newConstraint = containerTopConstraint.constant - difference
            
            animateConstraint(containerTopConstraint, toValue: newConstraint)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        removeKeyboard()
        
        return true
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Tap gesture recognizer
    //-------------------------------------------------------------------------//
    
    func handleTap(recognizer : UITapGestureRecognizer)
    {
        removeKeyboard()
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Remove keyboard
    //-------------------------------------------------------------------------//
    
    func removeKeyboard()
    {
        if tappedTextField != nil
        {
            if tappedTextField!.text == ""
            {
                switch tappedTextField!.tag
                {
                    case 10:
                        tappedTextField!.text = "FIRST NAME"
                    case 11:
                        tappedTextField!.text = "LAST NAME"
                    case 12:
                        tappedTextField!.text = "EMAIL"
                    case 13:
                        tappedTextField!.text = "USERNAME"
                    case 14:
                        tappedTextField!.text = "PASSWORD"
                    default:
                        print("Unknown txt field")
                }
            }
            
            tappedTextField!.resignFirstResponder()
            tappedTextField = nil
            
            if containerTopConstraint.constant != 0
            {
                animateConstraint(containerTopConstraint, toValue: 0)
            }
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Animations
    //-------------------------------------------------------------------------//
    
    func animateConstraint(constraint : NSLayoutConstraint, toValue value : CGFloat)
    {
        UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseOut,
            animations:
            {
                constraint.constant = value
                
                self.view.layoutIfNeeded()
            },
            completion:
            {
                (finished: Bool) in
        })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Ajust for bigger screen
    //-------------------------------------------------------------------------//
    
    func adjustForBiggerScreen()
    {
        for constraint in firstNameTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in lastNameTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in emailTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in usernameTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in passwordTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in signUpButton.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in signInButton.constraints
        {
            constraint.constant *= multiplier
        }
        
        var fontSize = 14.0 * multiplier
        firstNameTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        lastNameTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        emailTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        usernameTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        passwordTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        fontSize = 16.0 * multiplier
        signUpButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        signInButton.titleLabel!.font =  UIFont(name: "HelveticaNeue", size: fontSize)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Memory Warning
    //-------------------------------------------------------------------------//

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
