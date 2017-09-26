//
//  EEAttendeeSearchViewController.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/17/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>


@class EEEvent;

@interface EEAttendeeSearchViewController : UIViewController

@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EEEvent*  event;

@property (strong, nonatomic) IBOutlet UITextField* emailTextField;
@property (strong, nonatomic) IBOutlet UITextField* firstnameTextField;
@property (strong, nonatomic) IBOutlet UITextField* lastnameTextField;
@property (strong, nonatomic) IBOutlet UITextField* phoneTextField;

- (IBAction)fetchAllAttendees:(id)sender;
- (IBAction)searchAttendees:(id)sender;

@end
