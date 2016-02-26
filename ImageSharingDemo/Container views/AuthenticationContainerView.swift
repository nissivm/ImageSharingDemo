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

        let tapRecognizer = UITapGestureRecognizer(target: self, action:Selector("handleTap:"))
            tapRecognizer.delegate = self
        tapView.addGestureRecognizer(tapRecognizer)
        
        if Device.IS_IPHONE_4 || Device.IS_IPHONE_6 || Device.IS_IPHONE_6_PLUS
        {
            containerHeightConstraint.constant = self.view.frame.size.height
        }
        
        if Device.IS_IPHONE_6
        {
            multiplier = Constants.multiplier6
            adjustForBiggerScreen()
        }
        else if Device.IS_IPHONE_6_PLUS
        {
            multiplier = Constants.multiplier6plus
            adjustForBiggerScreen()
        }
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
        
        if firstName.characters.count > 0 &&
            lastName.characters.count > 0 &&
            email.characters.count > 0 &&
            username.characters.count > 0 &&
            password.characters.count > 0
        {
            Auxiliar.showLoadingHUDWithText("Signing up...", forView: self.view)
            kinveyBackend.signUpUser(firstName, lastName: lastName, email: email,
                username: username, password: password, completion: {
                    
                [unowned self](status, errorMessage) -> Void in
                    
                Auxiliar.hideLoadingHUDInView(self.view)
                    
                if status == "Success"
                {
                    self.firstNameTxtField.text = ""
                    self.lastNameTxtField.text = ""
                    self.emailTxtField.text = ""
                    self.usernameTxtField.text = ""
                    self.passwordTxtField.text = ""
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    
                    if defaults.objectForKey("RegisteredNotificationSettings") == nil
                    {
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            appDelegate.registerUserForPushNotifications()
                    }
                    else
                    {
                        NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
                    }
                }
                else
                {
                    Auxiliar.presentAlertControllerWithTitle(status,
                        andMessage: errorMessage,
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
        
        if username.characters.count > 0 && password.characters.count > 0
        {
            Auxiliar.showLoadingHUDWithText("Signing in...", forView: self.view)
            kinveyBackend.signInUser(username, password: password, completion: {
                
                [unowned self](status, errorMessage) -> Void in
                
                Auxiliar.hideLoadingHUDInView(self.view)
                
                if status == "Success"
                {
                    self.firstNameTxtField.text = ""
                    self.lastNameTxtField.text = ""
                    self.emailTxtField.text = ""
                    self.usernameTxtField.text = ""
                    self.passwordTxtField.text = ""
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
                }
                else
                {
                    Auxiliar.presentAlertControllerWithTitle(status,
                        andMessage: errorMessage,
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
    // MARK: UITextFieldDelegate
    //-------------------------------------------------------------------------//
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
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
            if constraint.firstAttribute != .CenterX
            {
                constraint.constant *= multiplier
            }
        }
        
        for constraint in signInButton.constraints
        {
            if constraint.firstAttribute != .CenterX
            {
                constraint.constant *= multiplier
            }
        }
        
        let fontSize = 16.0 * multiplier
        firstNameTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        lastNameTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        emailTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        usernameTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
        passwordTxtField.font =  UIFont(name: "HelveticaNeue", size: fontSize)
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
