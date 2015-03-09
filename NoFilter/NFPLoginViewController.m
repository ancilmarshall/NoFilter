//
//  KeyChainEditorViewController.m
//  UW_HW7_Ancil
//
//  Created by Ancil on 12/18/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import "NFPLoginViewController.h"
#import "KeyChainManager.h"
#import "NFPServerManager.h"
#import "AppDelegate.h"

static NSString* const kMissingInputs = @"Missing Input";
static NSString* const kIncorrectPassword = @"Incorrect Password";
NSString* const kUserDefaultUsername = @"Default Username";
NSString* const kUserDefaultRememberLogin = @"Remember Login";

@interface NFPLoginViewController () <UITextFieldDelegate, NFPServerManagerProtocol>
@property (nonatomic,weak) IBOutlet UITextField* usernameTextField;
@property (nonatomic,weak) IBOutlet UITextField* passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *logonActivityIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameTextFieldConstraint;
@property (weak, nonatomic) IBOutlet UISwitch *rememberLoginSwitch;

@property (nonatomic,strong) NSString* username;
@property (nonatomic,strong) KeyChainManager* keyChainManager;
@property (nonatomic,strong) NFPServerManager* serverManager;
@property (nonatomic,strong) NSUserDefaults* defaults;
@property (nonatomic,assign) BOOL rememberLogin;

@end

@implementation NFPLoginViewController

#pragma mark  - initalization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"NoFilter Client Log In";
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    self.keyChainManager = [KeyChainManager sharedInstance];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    self.username = [self.defaults valueForKey:kUserDefaultUsername];
    self.rememberLogin = [[self.defaults valueForKey:kUserDefaultRememberLogin] boolValue];
    self.rememberLoginSwitch.on = self.rememberLogin;
    
    //update input text fields
    if (self.rememberLogin){
        self.usernameTextField.text = self.username;
        self.passwordTextField.text = [self.keyChainManager
                                       passwordForUsername:self.username];
    } else {
        self.usernameTextField.text = @"";
        self.passwordTextField.text = @"";
    }
    self.logonActivityIndicator.alpha = 0.0f;

    self.serverManager = [NFPServerManager sharedInstance];
    self.serverManager.delegate = self;
    
    //simple animation effects
    self.usernameTextField.alpha = 0.1;
    self.passwordTextField.alpha = 0.1;
    [self.view layoutIfNeeded];
    self.usernameTextFieldConstraint.constant =+30;

    [UIView animateWithDuration:0.5
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.usernameTextField.alpha = 1.0f;
                         self.passwordTextField.alpha = 1.0f;
                         [self.view layoutIfNeeded];
                     } completion:nil];
    
}
#pragma mark - NFPServerManagerDelegate
-(void)NFPServerManagerDidLoginSuccessfully;
{
    [self.logonActivityIndicator stopAnimating];
    self.logonActivityIndicator.alpha = 0.0f;
    
    [[AppDelegate delegate]
        setRootViewControllerWithIdentifier:@"NFPCollectionViewController"];
    
}

-(void)NFPServerManagerTaskFailedWithErrorMessage:(NSString*)errorMsg;
{
    NSAssert([NSThread isMainThread],@"Need to be on the Main Thread");
    [self.logonActivityIndicator stopAnimating];
    self.logonActivityIndicator.alpha  = 0.0f;
    [self showAlert:errorMsg];
}

#pragma mark - Remember Login
-(IBAction)rememberLoginButtonPressed:(UISwitch*)sender;
{
    NSParameterAssert(sender == self.rememberLoginSwitch);
    BOOL switchValue = self.rememberLoginSwitch.isOn;
    [self.defaults setValue:@(switchValue) forKey:kUserDefaultRememberLogin];
    
}

#pragma mark - Login to Server

-(IBAction)logOnButtonPressed:(id)sender
{
    [self.view endEditing:YES]; //dismiss the keyboard
    
    NSString* inputUsername = self.usernameTextField.text;
    NSString* inputPassword = self.passwordTextField.text;
    
    //validate input
    if (inputUsername.length == 0 || inputPassword.length == 0){
        [self showAlert:kMissingInputs];
        return;
    }
    
    //add new username & password pair if username not already in key chain
    if (![self.keyChainManager containsUsername:inputUsername] )
    {
        [self.keyChainManager addUsername:inputUsername
                                 password:inputPassword];
        
    } else { // validate that username and password pair matches
        if (![inputPassword isEqualToString:[self.keyChainManager
                                             passwordForUsername:inputUsername]]){
            [self showAlert:kIncorrectPassword]; //ask user if he would like to override
            return; //let alert determine what function to call next
        }
    }
        
    [self logonToServer];
    
}

-(void)logonToServer;
{
    [self.defaults setValue:self.usernameTextField.text forKey:kUserDefaultUsername];
    self.logonActivityIndicator.alpha = 1.0f;
    [self.logonActivityIndicator startAnimating];
    
    [self.serverManager logonToServer];

   
}

// show alert based on the error message
- (void) showAlert:(NSString*)errMsg
{
    //instantiate an empty alertController here. Fill in data depending on errMsg
    UIAlertController* alertController = [UIAlertController
        alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    if ([errMsg isEqualToString:kMissingInputs])
    {
        alertController.title = @"Empty Input Text Fields";;
        alertController.message =  @"All input text fields must be filled in";
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                          }];
        
        [alertController addAction:okAction];

    }
    else if ([errMsg isEqualToString:kIncorrectPassword])
    {
        alertController.title = @"Username & password does not match";
        alertController.message = @"Do you want to update Keychain?";
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                              }];
        
        UIAlertAction* updateAction = [UIAlertAction actionWithTitle:@"Yes"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action)
        {
            [self.keyChainManager updateUsername:self.usernameTextField.text
                                        password:self.passwordTextField.text];
            [self logonToServer];

        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:updateAction];
    }
    else // else it is a server error
    {
        alertController.title = @"No Filter Server Error";
        alertController.message = errMsg;
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                         }];
        
        [alertController addAction:okAction];
        
    }
    
    [alertController setModalPresentationStyle:UIModalPresentationNone];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}



@end
