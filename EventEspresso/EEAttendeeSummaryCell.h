//
//  EEAttendeeSummaryCell.h
//  EventEspressoHD
//
//  This cell type is used when displaying the attendee-info view on the iPhone.
//
//  Created by Michael A. Crawford on 3/1/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EEAttendeeSummaryCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* attendeeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceOptionLabel;

@end
