//
//  EEScanViewController_iPad.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/25/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EEInOutQuantityViewController.h"
#import "ZBarSDK.h"

@class EEEvent;

@protocol EEScanViewControllerDelegate;

@interface EEScanViewController_iPad : UIViewController <UIAlertViewDelegate, UIPopoverControllerDelegate,EEInOutQuantityViewControllerDelegate, ZBarReaderViewDelegate>

@property (weak, nonatomic) id<EEScanViewControllerDelegate> delegate;
@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EEEvent* event;

@property (strong, nonatomic) IBOutlet UILabel* attendeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* couponDescriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* eventTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel* lastUpdateLabel;
@property (strong, nonatomic) IBOutlet UILabel* registrationCodeLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceOptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *ticketCountLabel;

@property (strong, nonatomic) IBOutlet UIImageView* resultImageView;
@property (strong, nonatomic) IBOutlet UIView *scanResultView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem* checkInButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* lastUpdateLabelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* leftSpacer;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* rescanButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* rightSpacer;

@property (strong, nonatomic) IBOutlet UIToolbar* toolbar;

- (IBAction)checkInWithoutPayment:(id)sender;
- (IBAction)displayAttendeeDetail:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)handleTapGesture:(id)sender;
- (IBAction)rescan:(id)sender;

@end

@protocol EEScanViewControllerDelegate <NSObject>

- (void)receivedUpdatedRegistration:(EERegistration *)registration;

@end
