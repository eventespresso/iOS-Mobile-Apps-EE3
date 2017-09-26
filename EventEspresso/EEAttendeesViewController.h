//
//  EEAttendeesViewController.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/19/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EEScannerViewController.h"

@class EEEvent;

@interface EEAttendeesViewController : UITableViewController <UISearchBarDelegate, EEScanViewControllerDelegate>

@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EEEvent*  event;

@property (strong, nonatomic) IBOutlet UITableView* attendeesTableView;

- (IBAction)performAdvancedSearch:(id)sender;

@end
