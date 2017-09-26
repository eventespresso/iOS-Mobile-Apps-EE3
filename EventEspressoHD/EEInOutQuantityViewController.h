//
//  EEInOutQuantityViewController.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 2/4/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EEInOutQuantityViewControllerDelegate;

@interface EEInOutQuantityViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView* pickerView;

@property (nonatomic, weak) id<EEInOutQuantityViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL ignorePaymentStatus;
@property (nonatomic, assign) BOOL in;
@property (nonatomic, assign) NSUInteger ticketCount;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@protocol EEInOutQuantityViewControllerDelegate <NSObject>

- (void)controller:(EEInOutQuantityViewController *)controller didSelectQuantity:(NSInteger)quantity;
- (void)controllerDidCancelQuantitySelection:(EEInOutQuantityViewController *)controller;

@end