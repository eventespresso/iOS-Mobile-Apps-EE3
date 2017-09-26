//
//  EEScannerViewController.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/17/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EEInOutQuantityViewController.h"
#import "ZBarSDK.h"

@class EEEvent, EERegistration;

@protocol EEScanViewControllerDelegate;

@interface EEScannerViewController : UIViewController <UIAlertViewDelegate, EEInOutQuantityViewControllerDelegate, ZBarReaderViewDelegate>

@property (weak, nonatomic) id<EEScanViewControllerDelegate> delegate;
@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EEEvent* event;

@property (strong, nonatomic) IBOutlet UILabel* attendeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* couponDescriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* eventTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel* registrationCodeLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceOptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketCountLabel;

@property (strong, nonatomic) IBOutlet UIImageView* resultImageView;
@property (strong, nonatomic) IBOutlet UIView* scanResultView;

- (IBAction)checkInWithoutPayment:(id)sender;
- (IBAction)displayAttendeeDetail:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)handleTapGesture:(id)sender;

@end

@protocol EEScanViewControllerDelegate <NSObject>

- (void)receivedUpdatedRegistration:(EERegistration *)registration;

@end
