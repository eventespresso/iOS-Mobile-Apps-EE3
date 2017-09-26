//
//  EELoginViewController.m
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/3/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EEEventsViewController.h"
#import "EELoginRequest.h"
#import "EELoginViewController.h"
#import "EEScannerViewController.h"
#import "UIDevice+iPhone5extension.h"
#import "UIImage+iPhone5extension.h"
#import "UIView+EventEspresso.h"

#define INPUT_ERROR_COLOR [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0]
#define INPUT_COLOR [UIColor darkGrayColor]

static CGFloat const kKeyboardToolbarHeight = 40.0f;

@interface EELoginViewController ()
{
	UIToolbar*          keyboardToolbar;
    EELoginRequest*     loginRequest;
	UISegmentedControl* nextPrevControl;
}

@property (nonatomic, assign) BOOL loggedIn;

@end

@implementation EELoginViewController

#pragma mark - Properties

@synthesize activityIndicator       = _activityIndicator;
@synthesize backgroundImage         = _backgroundImage;
@synthesize endpointURLLabel        = _endpointURLLabel;
@synthesize endpointURLTextField    = _endpointURLTextField;
@synthesize loggedIn                = _loggedIn;
@synthesize loginButton             = _loginButton;
@synthesize loginButtonVSConstraint = _loginButtonVSConstraint;
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
    else if ( [segue.identifier isEqualToString:@"Scanner"] )
    {
        EEScannerViewController* viewController = (EEScannerViewController *)[segue.destinationViewController topViewController];
        [viewController setEndpoint:self.endpointURLTextField.text];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // load proper image for hardware
    self.backgroundImage.image = [UIImage imageNamedForDevice:@"Background"];
    
	// display version number
    NSDictionary* infoDict = [NSBundle mainBundle].infoDictionary;
    NSString* bundleVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
	self.versionLabel.text= (bundleVersion.length > 0 ? [NSString stringWithFormat:@"Version %@", bundleVersion] : @"");
    
    // TODO: Password should be stored in keychain and fetched from there.
    
    // start without cached password
    [[NSUserDefaults standardUserDefaults] clearDefaultPassword];
}

-(void)viewWillAppear:(BOOL)animated
{
	self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;

    // While this view is active (visible), monitor the movement and visibility
    // of the virtual keyboard.
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
	
	self.endpointURLTextField.text = [NSUserDefaults standardUserDefaults].endpoint;
	self.passwordTextField.text = @"";
	self.usernameTextField.text = [NSUserDefaults standardUserDefaults].username;
}

-(void)viewWillDisappear:(BOOL)animated
{
	self.navigationController.navigationBarHidden = NO;

    // When this view is not active (visible), we are not interested in state of
    // the virtual keyboard.
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark - UITextField Delegate Methods

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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGPoint textFieldOriginInWindow = [textField.superview convertPoint:textField.frame.origin toView:nil];
    
    if ( [UIDevice currentDevice].iPhone5 )
    {
        if ( textField == self.passwordTextField )
        {
            [self.view moveUp:(int)(textFieldOriginInWindow.y - 184) withAnimation:YES];
        }
    }
    else
    {
        [self.view moveUp:(int)(textFieldOriginInWindow.y - 84) withAnimation:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[self.view moveToOriginWithAnimation:YES];
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

- (IBAction)dismissKeyboard:(id)sender
{
	[[self.view findFirstResponder] resignFirstResponder];
}

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
	[self.navigationItem setHidesBackButton:YES animated:YES];
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
                [NSUserDefaults standardUserDefaults].sessionKey = loginRequest.sessionKey;
                [self loginSucceeded];
            }
            
            [self.navigationItem setHidesBackButton:NO animated:NO];
            self.loginButton.enabled = YES;
            loginRequest = nil;
        }];
    }
    {
        [self.navigationItem setHidesBackButton:NO];
        self.loginButton.enabled = YES;
    }
}

- (IBAction)loginAsNewUser:(id)sender
{
	self.endpointURLTextField.text = [NSUserDefaults standardUserDefaults].endpoint;
	self.passwordTextField.text = @"";
	self.usernameTextField.text = @"";
    self.loggedIn = NO;
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

- (IBAction)startScan:(id)sender
{
    [self performSegueWithIdentifier:@"Scanner" sender:sender];
}

#pragma mark - UIKeyboard Notification Handlers

- (void)keyboardWillHide:(NSNotification *)notification
{
    // If we are currently displaying a keyboard toolbar, we must animate it
    // away along with the keyboard that is about to hide.
    
	if ( keyboardToolbar != nil )
    {
        UIViewAnimationCurve animationCurve	= [[[notification userInfo] valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        NSTimeInterval animationDuration = [[[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [UIView beginAnimations:@"EEHideKeyboardAnimation" context:nil];
        [UIView setAnimationCurve:animationCurve];
        [UIView setAnimationDuration:animationDuration];
        
        keyboardToolbar.alpha = 0.0f;
        keyboardToolbar.frame = CGRectMake(0.0f,
                                           self.view.bounds.size.height + kKeyboardToolbarHeight,
                                           self.view.bounds.size.width,
                                           kKeyboardToolbarHeight);
        [UIView commitAnimations];
	}
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    // Animate in a toolbar on top of the virtual keyboard.  Create the toolbar
    // if needed.
    
    CGRect keyboardFrame = [[[notification userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	
    if ( nil == keyboardToolbar )
    {
        keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,
                                                                      0,
                                                                      self.view.bounds.size.width,
                                                                      kKeyboardToolbarHeight)];
        keyboardToolbar.barStyle = UIBarStyleBlack;
        keyboardToolbar.translucent = YES;
        
        UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard:)];
        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        nextPrevControl = [[UISegmentedControl alloc] initWithItems:
                           @[NSLocalizedString(@"Previous", @"Previous form field"),
                           NSLocalizedString(@"Next", @"Next form field")]];
        nextPrevControl.segmentedControlStyle = UISegmentedControlStyleBar;
        nextPrevControl.momentary = YES;
        [nextPrevControl addTarget:self
                            action:@selector(nextPrevious:)
                  forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem* segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:nextPrevControl];
        
        NSArray* toolbarItems = @[segmentedControlItem, flexibleSpace, button];
        [keyboardToolbar setItems:toolbarItems];
        
        keyboardToolbar.frame = CGRectMake(keyboardFrame.origin.x,
                                           keyboardFrame.origin.y - keyboardToolbar.frame.size.height,
                                           keyboardToolbar.frame.size.width,
                                           keyboardToolbar.frame.size.height);
        
        [[UIApplication sharedApplication].keyWindow addSubview:keyboardToolbar];
    }		
	
	UIViewAnimationCurve animationCurve	= [[[notification userInfo] valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	NSTimeInterval animationDuration = [[[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
	[UIView beginAnimations:@"EEShowKeyboardAnimation" context:nil];
	[UIView setAnimationCurve:animationCurve];
	[UIView setAnimationDuration:animationDuration];
	
	keyboardToolbar.alpha = 1.0;
    
    if ( [UIDevice currentDevice].iPhone5 )
    {
        keyboardToolbar.frame = CGRectMake(0, 312, self.view.bounds.size.width, kKeyboardToolbarHeight);
    }
    else
    {
        keyboardToolbar.frame = CGRectMake(0, 224, self.view.bounds.size.width, kKeyboardToolbarHeight);
    }
	
	[UIView commitAnimations];
}

#pragma mark - Private Methods

- (void)setLoggedIn:(BOOL)loggedIn
{
    if ( loggedIn != _loggedIn )
    {
        _loggedIn = loggedIn;
        
        if ( loggedIn )
        {
            // reconfigure view to the logged-in state
            self.backgroundImage.image = [UIImage imageNamedForDevice:@"Default"];
            
            self.endpointURLLabel.hidden        = YES;
            self.endpointURLTextField.hidden    = YES;
            self.passwordLabel.hidden           = YES;
            self.passwordTextField.hidden       = YES;
            self.startScanButton.hidden         = NO;
            self.usernameLabel.hidden           = YES;
            self.usernameTextField.hidden       = YES;
            
            [self.loginButton removeTarget:self
                                    action:@selector(login:)
                          forControlEvents:UIControlEventTouchUpInside];

            [self.loginButton addTarget:self
                                 action:@selector(loginAsNewUser:)
                       forControlEvents:UIControlEventTouchUpInside];
            
            self.loginButtonVSConstraint.constant += 30.0f;
        }
        else
        {
            // reconfigure view to the logged-out state
            self.backgroundImage.image = [UIImage imageNamedForDevice:@"Background"];
            
            self.endpointURLLabel.hidden        = NO;
            self.endpointURLTextField.hidden    = NO;
            self.passwordLabel.hidden           = NO;
            self.passwordTextField.hidden       = NO;
            self.startScanButton.hidden         = YES;
            self.usernameLabel.hidden           = NO;
            self.usernameTextField.hidden       = NO;
            
            [self.loginButton removeTarget:self
                                    action:@selector(loginAsNewUser:)
                          forControlEvents:UIControlEventTouchUpInside];
            
            [self.loginButton addTarget:self
                                 action:@selector(login:)
                       forControlEvents:UIControlEventTouchUpInside];
            
            self.loginButtonVSConstraint.constant -= 30.0f;
        }
    }
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

- (void)loginSucceeded
{
    self.loggedIn = YES;
	[self performSegueWithIdentifier:@"Events" sender:self];
}

@end
