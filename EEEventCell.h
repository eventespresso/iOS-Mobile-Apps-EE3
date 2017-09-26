//
//  EEEventCell.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 10/11/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EEEventCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* dateInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel* eventLabel;
@property (strong, nonatomic) IBOutlet UILabel* venueLabel;

@end
