//
//  EELoginViewController_iPad.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 10/26/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "NSUserDefaults+EventEspresso.h"


@protocol EELoginViewControllerDelegate
- (void)loginFailedWithError:(NSError *)error;
- (void)loginSucceededWithSessionKey:(NSString *)sessionKey
                            endpoint:(NSString *)endpoint;
@end

@interface EELoginViewController_iPad : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) id<EELoginViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIButton* loginButton;

@property (strong, nonatomic) IBOutlet UIImageView* backgroundImage;

@property (strong, nonatomic) IBOutlet UILabel* endpointURLLabel;
@property (strong, nonatomic) IBOutlet UILabel* passwordLabel;
@property (strong, nonatomic) IBOutlet UILabel* usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel* versionLabel;

@property (strong, nonatomic) IBOutlet UITextField* endpointURLTextField;
@property (strong, nonatomic) IBOutlet UITextField* passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField* usernameTextField;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicator;

@property (strong, nonatomic) IBOutlet UIToolbar* keyboardToolbar;

- (IBAction)displayFeedbackAndSupportLink:(id)sender;
- (IBAction)login:(id)sender;
- (IBAction)nextPrevious:(id)sender;

@end
