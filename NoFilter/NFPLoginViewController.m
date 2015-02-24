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

static NSString* const kMissingInputErrorString = @"Missing Input";
static NSString* const kDuplicateHostnameErrorString = @"Duplicate Hostname";

@interface NFPLoginViewController () <UITextFieldDelegate, KeyChainManagerDelegate>
@property (nonatomic,weak) IBOutlet UITextField* usernameTextField;
@property (nonatomic,weak) IBOutlet UITextField* passwordTextField;

@property (nonatomic,strong) NSString* hostname;
@property (nonatomic,strong) NSString* username;

@property (nonatomic,strong) KeyChainManager* keyChainManager;
@property (nonatomic,strong) NFPServerManager* serverManager;


@end

@implementation NFPLoginViewController


#pragma mark  - initalization

- (instancetype)init;
{
    self = [super init];
    if (self){
        
        _keyChainManager = [KeyChainManager sharedInstance];
        _keyChainManager.delegate = self;
        
        _hostname = NFPServerHost;
        _username = [_keyChainManager usernameForHostname:_hostname];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"NoFilter Client Log In";
        
    //update text field (if the values are non-nil)
    //TODO: what would happen if values were nil??
    self.usernameTextField.text = self.username;
    self.passwordTextField.text = [self.keyChainManager passwordForHostname:self.hostname];
    
}

#pragma mark - KeyChainManagerDelegate
-(void)keyChainManagerDidAddItem;{}
-(void)keyChainManagerDidUpdateItem;{}


#pragma mark - Navigation Segues

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender;
{
    NSParameterAssert([identifier isEqualToString:@"postLoginSegue"]);
    
    NSString* inputHostname = NFPServerHost;
    NSString* inputUsername = self.usernameTextField.text;
    NSString* inputPassword = self.passwordTextField.text;
    
    //validate input
    if (inputUsername == 0 || inputPassword == 0){
        [self showAlert:kMissingInputErrorString];
        return NO;
    }
    
    //check for duplicate hostname in KeyChainManager database
    if ( ![[KeyChainManager sharedInstance] containsHostname:inputHostname] )
    {
    
        [[KeyChainManager sharedInstance] addHostname:NFPServerHost
                               username:self.usernameTextField.text
                               password:self.passwordTextField.text];
        
    }
    
    self.serverManager = [NFPServerManager sharedInstance];
    
    
    return YES;
}

// show alert based on the error message
- (void) showAlert:(NSString*)errMsg
{
    UIAlertController* alertController = [UIAlertController
        alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    if ([errMsg isEqualToString:kMissingInputErrorString])
    {
        alertController.title = @"Empty Input Text Field";;
        alertController.message =  @"All input text fields must be filled in";
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
                                          }];
        
        [alertController addAction:okAction];

    }
    else if ([errMsg isEqualToString:kDuplicateHostnameErrorString])
    {
        alertController.title = @"Hostname already exists";
        alertController.message = @"Do you want to update Keychain?";
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
                                              }];
        
        UIAlertAction* updateAction = [UIAlertAction actionWithTitle:@"Yes"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action)
        {
            [[KeyChainManager sharedInstance] updateHostname:NFPServerHost
                                                    username:self.usernameTextField.text
                                                    password:self.passwordTextField.text];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:updateAction];
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
