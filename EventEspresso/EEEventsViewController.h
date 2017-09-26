//
//  EEEventsViewController.h
//  EventEspresso
//
//  Table-view controller used to display all events for the given endpoint.
//  This view is used in both the iPad and the iPhone versions of EventEspresso.
//  In the iPad implementation, it appears in the master-pane of the split-view
//  controller.
//
//  Created by Michael A. Crawford on 10/8/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

@interface EEEventsViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) NSString* endpoint;

@property (strong, nonatomic) IBOutlet UITableView* eventsTableView;

@end
