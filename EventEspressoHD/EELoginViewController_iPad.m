//
//  EELoginViewController_iPad.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 10/3/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EEEventsViewController.h"
#import "EELoginRequest.h"
#import "EELoginViewController_iPad.h"
#import "SVProgressHUD.h"
#import "UIView+EventEspresso.h"

#define INPUT_ERROR_COLOR [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0]
#define INPUT_COLOR [UIColor darkGrayColor]

@interface EELoginViewController_iPad ()
{
	UINib*          keyboardToolbarNib;
    EELoginRequest* loginRequest;
}

@end

@implementation EELoginViewController_iPad

#pragma mark - Properties

@synthesize activityIndicator       = _activityIndicator;
@synthesize backgroundImage         = _backgroundImage;
@synthesize endpointURLLabel        = _endpointURLLabel;
@synthesize endpointURLTextField    = _endpointURLTextField;
@synthesize keyboardToolbar         = _keyboardToolbar;
@synthesize loginButton             = _loginButton;
@synthesize passwordLabel           = _passwordLabel;
@synthesize passwordTextField       = _passwordTextField;
@synthesize usernameLabel           = _usernameLabel;
@synthesize usernameTextField       = _usernameTextField;
@synthesize versionLabel            = _versionLabel;

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"Events"] )
    {
        [segue.destinationViewController setEndpoint:self.endpointURLTextField.text];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // configure keyboard-toolbar
    [self loadKeyboardToolbar];
    
	// display version number
    NSDictionary* infoDict = [NSBundle mainBundle].infoDictionary;
    NSString* bundleVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
	self.versionLabel.text= (bundleVersion.length > 0 ? [NSString stringWithFormat:@"Version %@", bundleVersion] : @"");
    
    // TODO: Password should be stored in keychain and fetched from there.
    
    // start without cached password
    [[NSUserDefaults standardUserDefaults] clearDefaultPassword];
}

-(void)viewDidAppear:(BOOL)animated
{
	self.navigationController.navigationBarHidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    // set defaults for textfields
	self.endpointURLTextField.text = [NSUserDefaults standardUserDefaults].endpoint;
	self.passwordTextField.text = @"";
	self.usernameTextField.text = [NSUserDefaults standardUserDefaults].username;
}

#pragma mark - UITextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ( self.passwordTextField == textField )
    {
        [self.view moveUp:84 withAnimation:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ( self.passwordTextField == textField )
    {
        [self.view moveToOriginWithAnimation:YES];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // disallow leading whitespace
    if ( 0 == range.location && 0 == range.length && [string isEqualToString:@" "] )
    {
        return NO;
    }
    
    NSMutableString* resultString = [NSMutableString stringWithString:textField.text];
    [resultString replaceCharactersInRange:range withString:string];
	
	UILabel* associatedLabel = nil;
    
	if ( textField == self.endpointURLTextField )
    {
		associatedLabel = self.endpointURLLabel;
	}
	else if ( textField == self.passwordTextField )
    {
		associatedLabel = self.passwordLabel;
	}
	else if ( textField == self.usernameTextField )
    {
		associatedLabel = self.usernameLabel;
	}
	
    if ( [resultString length] == 0 )
    {
        associatedLabel.textColor = INPUT_ERROR_COLOR;
    } 
	else
    {
        associatedLabel.textColor = INPUT_COLOR;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // When the user hits return on the last empty input field, treat it as it
    // they tapped the login button.  Otherwise, advance to the next field in
    // the loop.
    
	if ( self.endpointURLTextField.text.length > 0 &&
        self.passwordTextField.text.length > 0 &&
        self.usernameTextField.text.length > 0)
    {
		[self login:self];
	}
	else
    {
		if ( textField == self.endpointURLTextField )
        {
			[self.usernameTextField becomeFirstResponder];
		}
        else if ( textField == self.usernameTextField )
        {
			[self.passwordTextField becomeFirstResponder];
		}
        else if ( textField == self.passwordTextField )
        {
			[self.endpointURLTextField becomeFirstResponder];
		}		
	}

	return YES;
}

#pragma mark - Target Actions

- (IBAction)displayFeedbackAndSupportLink:(id)sender
{
    NSURL* feedbackAndSupportURL = [NSURL URLWithString:@"http://eventespresso.com/forum/ticketing/"];
    [[UIApplication sharedApplication] openURL:feedbackAndSupportURL];
}

- (IBAction)login:(id)sender
{
    [self.endpointURLTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.usernameTextField resignFirstResponder];
    self.loginButton.enabled = NO;
    
    // If validation of the input succeeds, login to the server.
    if ( [self validateFields] )
    {
        // Sanitize the provided URL string and then save it and the other input
        // parameters for re-use.
        NSString* endpointURLString = self.endpointURLTextField.text;
        
        if ( NO == [endpointURLString hasPrefix:@"http"] )
        {
            endpointURLString = [NSString stringWithFormat:@"http://%@", endpointURLString];
            self.endpointURLTextField.text = endpointURLString;
        }
        
        // TODO: Store password in keychain!
        [NSUserDefaults standardUserDefaults].endpoint  = self.endpointURLTextField.text;
        [NSUserDefaults standardUserDefaults].password  = self.passwordTextField.text;
        [NSUserDefaults standardUserDefaults].username  = self.usernameTextField.text;
        
        NSURL* endpointURL = [NSURL URLWithString:endpointURLString];
        
        if ( nil == endpointURL )
        {
            NSError* error = [NSError errorWithDomain:EEErrorDomain
                                                 code:EEErrorInvalidEndpoint
                                             userInfo:@{NSLocalizedDescriptionKey : @"Specified endpoint is invalid."}];
            [self loginDidFail:error];
        }
        
        [self.activityIndicator startAnimating];
        
        loginRequest = [EELoginRequest requestWithUsername:self.usernameTextField.text password:self.passwordTextField.text URL:endpointURL completion:^(NSError* error) {
            [self.activityIndicator stopAnimating];

            if ( error )
            {
                [self loginDidFail:error];
            }
            else
            {
                [self.delegate loginSucceededWithSessionKey:loginRequest.sessionKey endpoint:self.endpointURLTextField.text];
            }
            
            [self.navigationItem setHidesBackButton:NO animated:NO];
            self.loginButton.enabled = YES;
            loginRequest = nil;
        }];
    }
    else
    {
        self.loginButton.enabled = YES;
    }
}

- (IBAction)nextPrevious:(id)sender
{
	UIResponder* responder = [self.view findFirstResponder];
	
	if ( 0 == [(UISegmentedControl *)sender selectedSegmentIndex] )
    {
		// previous
        if ( responder == self.endpointURLTextField )
        {
            [self.passwordTextField becomeFirstResponder];
        }
        else if ( responder == self.passwordTextField )
        {
            [self.usernameTextField becomeFirstResponder];
        }
        else if ( responder == self.usernameTextField )
        {
            [self.endpointURLTextField becomeFirstResponder];
        }
    }
    else
    {
		// next
        if ( responder == self.endpointURLTextField )
        {
            [self.usernameTextField becomeFirstResponder];
        }
        else if ( responder == self.usernameTextField )
        {
            [self.passwordTextField becomeFirstResponder];
        }
        else if ( responder == self.passwordTextField )
        {
            [self.endpointURLTextField becomeFirstResponder];
        }
	}
}

#pragma mark - Private Methods

- (void)loadKeyboardToolbar
{
    keyboardToolbarNib = [UINib nibWithNibName:@"EEKeyboardToolbar" bundle:nil];
    NSArray* topLevelObjects = [keyboardToolbarNib instantiateWithOwner:self options:nil];
    self.keyboardToolbar = topLevelObjects[0];
    self.endpointURLTextField.inputAccessoryView = self.keyboardToolbar;
    self.passwordTextField.inputAccessoryView = self.keyboardToolbar;
    self.usernameTextField.inputAccessoryView = self.keyboardToolbar;
}

- (BOOL)validateFields
{
    NSString* endpointURLString = self.endpointURLTextField.text;
    NSString* passwordString    = self.passwordTextField.text;
    NSString* usernameString    = self.usernameTextField.text;
    
    BOOL validationFailed = NO;
    
    if ( 0 == endpointURLString.length )
    {
        validationFailed = YES;
        self.endpointURLLabel.textColor = INPUT_ERROR_COLOR;
    }
    
    if ( 0 == passwordString.length )
    {
        validationFailed = YES;
        self.passwordLabel.textColor = INPUT_ERROR_COLOR;
    }
    
    if ( 0 == usernameString.length )
    {
        validationFailed = YES;
        self.usernameLabel.textColor = INPUT_ERROR_COLOR;
    }

    return ( !validationFailed );
}

- (void)loginDidFail:(NSError *)error
{
    if ( error )
    {
        NSString* message;
        
        if ( 403 == [error code] )
        {
            message = @"Please update your credentials and try again.";
        }
        else
        {
            message = [error localizedDescription];
        }
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Sorry, can't log in"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
        [alertView show];
    }
}

@end
