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
#import "NFPThumbnailGenerator.h"

static NSString* const kMissingInputs = @"Missing Input";
static NSString* const kIncorrectPassword = @"Incorrect Password";
NSString* const kUserDefaultUsername = @"Default Username";
NSString* const kUserDefaultRememberLogin = @"Remember Login";

@interface NFPLoginViewController () <UITextFieldDelegate>
@property (nonatomic,weak) IBOutlet UITextField* usernameTextField;
@property (nonatomic,weak) IBOutlet UITextField* passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *logonActivityIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameTextFieldConstraint;
@property (weak, nonatomic) IBOutlet UISwitch *rememberLoginSwitch;

@property (nonatomic,strong) NSString* username;
@property (nonatomic,strong) KeyChainManager* keyChainManager;
@property (nonatomic,strong) NSUserDefaults* defaults;
@property (nonatomic,assign) BOOL rememberLogin;

@end

@implementation NFPLoginViewController

#pragma mark  - Initalization

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

    [self registerNotifications];

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

-(void)viewDidDisappear:(BOOL)animated;
{
    [super viewDidDisappear:animated];
    [self unregisterNotifications];
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
    
    [[NFPServerManager sharedInstance] logonToServer];
   
}

-(IBAction)rememberLoginButtonPressed:(UISwitch*)sender;
{
    NSParameterAssert(sender == self.rememberLoginSwitch);
    BOOL switchValue = self.rememberLoginSwitch.isOn;
    [self.defaults setValue:@(switchValue) forKey:kUserDefaultRememberLogin];
    
}


#pragma mark - NFPServerManager Notifications

/*
 * This register/unregister pair uses these particular versions of the notification
 * center's observer adding/removal since it seems to work best for unregistering
 * Need to unregister when this view goes away since the NFPServerManager still posts
 * notifications to other view controllers after this view controller disappears.
 */
-(void)registerNotifications;
{
    [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(serverSucceededNotification:)
         name:NFPServerManagerLoginDidSucceedNotification
         object:nil];
    
    [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(serverFailedNotification:)
         name:NFPServerManagerTaskFailedNotification
         object:nil];
}

-(void)unregisterNotifications;
{
    [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:NFPServerManagerLoginDidSucceedNotification
         object:nil];

    [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:NFPServerManagerTaskFailedNotification
         object:nil];
}

-(void)serverFailedNotification:(NSNotification*)note;
{
    NSAssert([NSThread isMainThread],@"Need to be on the Main Thread");
    
    NSDictionary* userInfo = note.userInfo;
    NSString* errorMsg = userInfo[@"error_msg"];
    [self.logonActivityIndicator stopAnimating];
    self.logonActivityIndicator.alpha  = 0.0f;
    [self showAlert:errorMsg];
    
}

-(void)serverSucceededNotification:(NSNotification*)note;
{
    NSAssert([NSThread isMainThread],@"Need to be on the Main Thread");
    
    [self.logonActivityIndicator stopAnimating];
    self.logonActivityIndicator.alpha = 0.0f;
    
    [[AppDelegate delegate]
     setRootViewControllerWithIdentifier:@"NFPCollectionViewController"];
    
}

#pragma mark - Alert Controller

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
    else { // Error from Server
        
        alertController.title = @"No server connection";
        alertController.message = errMsg;
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Continue"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
        {
            [[AppDelegate delegate]
             setRootViewControllerWithIdentifier:@"NFPCollectionViewController"];
            
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
