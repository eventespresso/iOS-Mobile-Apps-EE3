//
//  EELoginViewController.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/3/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "NSUserDefaults+EventEspresso.h"

@interface EELoginViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* loginButtonVSConstraint;

@property (strong, nonatomic) IBOutlet UIButton* loginButton;
@property (strong, nonatomic) IBOutlet UIButton* startScanButton;

@property (strong, nonatomic) IBOutlet UIImageView* backgroundImage;

@property (strong, nonatomic) IBOutlet UILabel* endpointURLLabel;
@property (strong, nonatomic) IBOutlet UILabel* passwordLabel;
@property (strong, nonatomic) IBOutlet UILabel* usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel* versionLabel;

@property (strong, nonatomic) IBOutlet UITextField* endpointURLTextField;
@property (strong, nonatomic) IBOutlet UITextField* passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField* usernameTextField;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;

- (IBAction)displayFeedbackAndSupportLink:(id)sender;
- (IBAction)login:(id)sender;
- (IBAction)startScan:(id)sender;

@end
