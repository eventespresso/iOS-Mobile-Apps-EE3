//
//  EEAddressViewController.h
//  EventEspressoHD
//
//  This view display two lines of address information with a detailed disclosure
//  that, when tapped, will segue into a map view displaying the address on the
//  map.
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>


@class EEVenue;

@interface EEAddressViewController : UIViewController

@property (strong, nonatomic) EEVenue* venue;

@property (strong, nonatomic) IBOutlet UILabel* nameLabel;
@property (strong, nonatomic) IBOutlet UILabel* addressLine1Label;
@property (strong, nonatomic) IBOutlet UILabel* addressLine2Label;

@end
