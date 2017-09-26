//
//  EEDetailViewController.m
//  EventEspressoHD
//
//  The detail view-controller for EventEspressoHD displays the attendee-
//  registration information.  It is equivalent to the EEAttendeeViewController
//  for the iPhone version of the app.
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAttendee.h"
#import "EEAttendeeCell_iPad.h"
#import "EECurrencyFormatter.h"
#import "EEDateTime.h"
#import "EEDetailViewController.h"
#import "EEEvent.h"
#import "EEEventTicketStats.h"
#import "EEPrice.h"
#import "EERegistration.h"
#import "EERegistrationsRequest.h"
#import "EETransaction.h"
#import "NSMutableArray+EventEspresso.h"
#import "NSUserDefaults+EventEspresso.h"
#import "SVProgressHUD.h"


#define ATTENDEE_TABLE_IS_INDEXED \
    ([NSUserDefaults standardUserDefaults].attendeeIndexListThreshold <= registrations.count)

static NSString* const kAttendeeCellID  = @"AttendeeCell_iPad";
static NSString* const kBasicCellID     = @"BasicCell_iPad";

NSString* const kTicketStatsUpdatedNotification = @"EEDetailViewControllerTicketStatsUpdated";

@interface EEDetailViewController ()
{
    NSDateFormatter*        lastUpdateDateFormatter;
    BOOL                    manualRefreshInProgress;
    NSMutableArray*         matchingRegistrations;
    NSMutableArray*         registrations;
    EERegistrationsRequest* registrationsRequest;
    BOOL                    searching;
    BOOL                    searchLoading;
    NSMutableArray*         sections;
    EERegistration*         selectedRegistration;
    UILabel*                toolbarLabel;
}

@property (strong, nonatomic) UIPopoverController* masterPopoverController;

@end

@implementation EEDetailViewController

#pragma mark - Properties

@synthesize event = _event;

- (void)setEvent:(EEEvent *)event
{
    if ( _event != event )
    {
        _event = event;
        
        if ( _event != nil )
        {
            [self fetchRegistrations];
            
            // When either a new event is assigned or an existing one is re-assigned,
            // make sure to dismiss the popover if it is currently displayed.
            if ( self.masterPopoverController != nil )
            {
                [self.masterPopoverController dismissPopoverAnimated:YES];
            }        
            
            // If we are currently not the top view for the nav-controller pop the
            // current view, which should be the attendee-info view and display the
            // updates we just fetched from the server.
            if ( self.navigationController.topViewController != self )
            {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
        else
        {
            // If there is no event then there can be no registrations.  Make
            // this fact plain in the interface.
            [self updateTitleWithAttendeeCount:0];
            registrations = [NSMutableArray new];
            [self.attendeesTableView reloadData];
        }
    }
}

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if ( self )
    {
        // Initialize date-formatter used by refresh control logic.
        lastUpdateDateFormatter = [NSDateFormatter new];
        [lastUpdateDateFormatter setDateFormat:@"MMM d, h:mm a"];

        registrations = [NSMutableArray new];

        // Load endpoint from defaults.
        _endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"AttendeeInfo"] )
    {
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setRegistration:selectedRegistration];
        [segue.destinationViewController setEndpoint:self.endpoint];
    }
    else if ( [segue.identifier isEqualToString:@"ScanView"] )
    {
        UINavigationController* navController = segue.destinationViewController;
        EEScanViewController_iPad* scanViewController = (EEScanViewController_iPad *)[navController topViewController];
        [scanViewController setEndpoint:self.endpoint];
        
        // If there is no selected event, then we don't need delegate callbacks.
        // The user simply using the app as a ticket scanner and is not focusing
        // on a specific event.
        if ( self.event )
        {
            [scanViewController setDelegate:self];
            [scanViewController setEvent:self.event];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // When the search bar is in editing mode, we want a transparent keyboard.
    // This should do it.
    for ( UIView* subview in self.searchDisplayController.searchBar.subviews )
    {
        if ( [subview conformsToProtocol:@protocol(UITextInputTraits)] )
        {
            @try
            {
                [(UITextField *)subview setReturnKeyType:UIReturnKeyDone];
                [(UITextField *)subview setKeyboardAppearance:UIKeyboardAppearanceAlert];
            }
            @catch ( NSException* exception )
            {
                NSLog(@"Exception while attempting to configfure search-bar keyboard: %@", exception);
            }
        }
    }
    
    // Initialize the refresh-control and then disable until we get and event.
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
}

#pragma mark - UISplitViewController Delegate Methods

- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController
{
    // Master (event) view is going away.  Setup a bar-button-item on the detail
    // view so that we may display the master view as a popover.
    barButtonItem.title = NSLocalizedString(@"Events", @"Events");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Master view is about to be shown again in the split view, invalidating
    // the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Target Actions

- (IBAction)refresh:(id)sender
{
    // We can only refress the attendees list if we have an selected event.
    if ( self.event != nil )
    {
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing Attendees"];
        [self fetchRegistrations];
    }
    else
    {
        [self.refreshControl endRefreshing];
    }
}

- (IBAction)scan:(id)sender
{
    [self performSegueWithIdentifier:@"ScanView" sender:self];
}

#pragma mark - UITableView DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
        return 1;
    }
    else
    {
        if ( ATTENDEE_TABLE_IS_INDEXED )
        {
            return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
        }
        else
        {
            return 1;
        }
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
        return nil;
    }
    else
    {
        if ( ATTENDEE_TABLE_IS_INDEXED )
        {
            return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
        }
        else
        {
            return nil;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
        // In the case where we are currently searching for a match from the
        // search bar, we want to use a generic cell to display the status of
        // our search if the search is pending or if the search failed.  For
        // this reason, we use a noAttendeeCell to display that status.  Othwise
        // we will allocate a standard attendee-cell and populate it accordingly.
        if( nil == matchingRegistrations )
        {
            UITableViewCell* noAttendeesCell = [self.attendeesTableView dequeueReusableCellWithIdentifier:kBasicCellID];
        	noAttendeesCell.textLabel.text = @"Searching ...";
			return noAttendeesCell;
        }
		else if ( 0 == matchingRegistrations.count )
        {
            UITableViewCell* noAttendeesCell = [self.attendeesTableView dequeueReusableCellWithIdentifier:kBasicCellID];
			noAttendeesCell.textLabel.text = @"No Attendees";
			return noAttendeesCell;
		}
		else
        {
			EERegistration* registration = matchingRegistrations[indexPath.row];
            return [self attendeeCellWithRegistation:registration];
		}
	}
	else
    {
        // In this case, we are asked for a cell for the attendees table-view.
        // We dequeue an instance of a blank cell and populate it with the data.
        if ( ATTENDEE_TABLE_IS_INDEXED )
        {
            return [self attendeeCellWithRegistation:sections[indexPath.section][indexPath.row]];
        }
        else
        {
            return [self attendeeCellWithRegistation:registrations[indexPath.row]];
        }
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
        // In the case where we are currently searching for a match from the
        // search bar, we want to use a generic cell to display the status of
        // our search if the search is pending or if the search failed.  For
        // this reason, when there are no matches we return a value of 1 for the
        // cell we will use to display the search status.  If we have found any
        // matches we return that count instead.
	 	if ( 0 == matchingRegistrations.count )
        {
		 	return 1;
	 	}
        else
        {
		 	return matchingRegistrations.count;
        }
    }
    
    // In this case, we always return the current count of events found.
    if ( ATTENDEE_TABLE_IS_INDEXED )
    {
        return [sections[section] count];
    }
    else
    {
        return registrations.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( ATTENDEE_TABLE_IS_INDEXED && ([sections[section] count] > 0) )
    {
        NSArray* sectionTitles = [[UILocalizedIndexedCollation currentCollation] sectionTitles];
        return sectionTitles[section];
    }
    
    return nil;
}

#pragma mark - UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
		if ( matchingRegistrations.count > 0 )
        {
			selectedRegistration = [matchingRegistrations objectAtIndex:indexPath.row];
		}
	}
	else
    {
        if ( ATTENDEE_TABLE_IS_INDEXED )
        {
            selectedRegistration = sections[indexPath.section][indexPath.row];
        }
        else
        {
            selectedRegistration = registrations[indexPath.row];
        }
	}
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
    [self performSegueWithIdentifier:@"AttendeeInfo" sender:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

#pragma mark - UISearchBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if ( searchText.length > 0 )
    {
        searching = YES;
        
        if ( NO == searchLoading )
        {
            // I assume the orignal author wanted to prevent the search from
            // starting until at least three characters had been entered into
            // the search field.
            if ( 3 == searchText.length )
            {
                [self fetchRegistrationsForSubstring:searchText];
            }
            else if ( searchText.length > 3 )
            {
                [self populateMatchingRegistrations:registrations];
            }
        }
	}
	else
    {
        matchingRegistrations = nil;
        [self.searchDisplayController.searchBar resignFirstResponder];
        [self.searchDisplayController.searchResultsTableView reloadData];
		searching = NO;
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Hide keyboard when the cancel button is clicked.
	[searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Hide the keyboard when the search button is clicked.
    [searchBar resignFirstResponder];
}

#pragma mark - EEAttendeeInfoViewController/EEScanViewController Delegate Methods

- (void)receivedUpdatedRegistration:(EERegistration *)registration
{
    // Perform a linear search for the registration with matching ID. Once found,
    // replace object. If not found, log it and reload from server.  Group
    // registrations are tricky.  Since only one member of the group is returned
    // no matter how many records one updated, the safe thing to do is to simply
    // reload the entire table by doing a new fetch from the back-end.
    if ( registration.isGroupRegistration )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchRegistrations];
        });
    }
    else
    {
        NSUInteger index = [registrations replaceMatchingRegistration:registration];
        
        if ( NSNotFound == index )
        {
            MCLog(@"Unable to find selected registration (%@) with updated registration (%@) in %@",
                  selectedRegistration,
                  registration,
                  registrations);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchRegistrations];
            });
        }
        else
        {
            [self updateTicketStatsAndNotifyObservers];

            if ( ATTENDEE_TABLE_IS_INDEXED )
            {
                [self setObjects:registrations];
            }
            else
            {
                [self.attendeesTableView reloadData];
            }
        }
    }
}

#pragma mark - Private Methods

- (EEAttendeeCell_iPad *)attendeeCellWithRegistation:(EERegistration *)registration
{
    EEAttendeeCell_iPad* cell       = (EEAttendeeCell_iPad *)[self.attendeesTableView dequeueReusableCellWithIdentifier:kAttendeeCellID];
    cell.attendeeNameLabel.text     = registration.attendee.fullname;
    cell.groupRegistrationLabel.text= (registration.isGroupRegistration ? @"Group" : @"Single");
    cell.priceLabel.text            = [[EECurrencyFormatter sharedFormatter] stringFromNumber:registration.finalPrice];
    cell.priceOptionLabel.text      = registration.price.name;
    
    if ( registration.isCheckedIn )
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)fetchRegistrations
{
    // If the user is not dragging down the view to invoke the refresh control,
    // we assume this fetch is requested programatically.
    if ( self.attendeesTableView.contentOffset.y >= 0 )
    {
        [SVProgressHUD showWithStatus:@"Loading"];
    }
    else
    {
        manualRefreshInProgress = YES;
    }

    // Issue a network request for all attendees associated with the given event.
    // Results will be displayed in table when the request completes.
    NSString* queryParams = nil;
    NSUInteger queryLimit = [NSUserDefaults standardUserDefaults].registrationsQueryLimit;
    
    if ( queryLimit > 0 )
    {
        queryParams = [NSString stringWithFormat:@"?Event.id=%@&limit=%d", self.event.ID, queryLimit];
    }
    else
    {
        queryParams = [NSString stringWithFormat:@"?Event.id=%@", self.event.ID];
    }
        
    queryParams = [queryParams stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
    NSLog(@"Registrations query parameters: %@", queryParams);

    registrationsRequest = [EERegistrationsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
        if ( error )
        {
            [self updateTitleWithAttendeeCount:0];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Registrations" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            // Once we have the registrations we must update the ticket stats
            // and then filter duplicates, for display.  These MUST be done in
            // the stated order.
            registrations = [NSMutableArray arrayWithArray:registrationsRequest.returnedRegistrations];
            [self updateTicketStatsAndNotifyObservers];
            [registrations removeDuplicateAttendees];

            if ( ATTENDEE_TABLE_IS_INDEXED )
            {
                [self setObjects:registrations];
            }
            else
            {
                [self.attendeesTableView reloadData];
            }

            [self updateTitleWithAttendeeCount:registrations.count];
        }

        [self refreshCompleted];
        
        if ( NO == manualRefreshInProgress )
        {
            [SVProgressHUD dismiss];
        }
        else
        {
            manualRefreshInProgress = NO;
        }
    }];
}

- (void)fetchRegistrationsForSubstring:(NSString*)substring
{
    searchLoading = YES;
    
    NSString* queryParams = [NSString stringWithFormat:@"?Attendee.firstname__like=%%%@%%", substring];
    
    queryParams = [queryParams stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
    NSLog(@"Registrations query parameters: %@", queryParams);

    registrationsRequest = [EERegistrationsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
        if ( error )
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Registrations" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            // searchActivityIndicater is stopped in called method
            [self populateMatchingRegistrations:registrationsRequest.returnedRegistrations];
        }

        searchLoading = NO;
    }];
}

- (void)populateMatchingRegistrations:(NSArray *)returnedRegistration
{
    if( nil == matchingRegistrations )
    {
        matchingRegistrations = [NSMutableArray new];
    }
    
    if ( searching )
    {
        [matchingRegistrations removeAllObjects];
        
        NSString* searchText = self.searchDisplayController.searchBar.text;
        
        for ( EERegistration* registration in returnedRegistration )
        {
            NSRange titleResultsRange = [registration.attendee.fullname rangeOfString:searchText options:NSCaseInsensitiveSearch];
            
            if ( titleResultsRange.length > 0 )
            {
                [matchingRegistrations addObject:registration];
            }
        }
        
        [self.searchDisplayController.searchResultsTableView reloadData];        
    }
}

- (void)refreshCompleted
{
    NSString* lastUpdated = [NSString stringWithFormat:@"Last updated on %@",
                             [lastUpdateDateFormatter stringFromDate:[NSDate date]]];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
    [self.refreshControl endRefreshing];
}

- (void)setObjects:(NSArray *)objects
{
    // This method sets up the rather complex data structure used to correlate
    // data for the indexed table-view implementation.  It begins by allocating
    // an array for each section.  Then, for each array, it stores the approriate
    // subset of objects based on the attendee's last-name.  Finally, each array
    // is sorted, again according to lastname.  This happens every time a new
    // event is selected.
    SEL selector = @selector(attendeeLastName);
    NSInteger sectionTitlesCount = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
    NSMutableArray* mutableSections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    for ( NSInteger idx = 0; idx < sectionTitlesCount; ++idx )
    {
        [mutableSections addObject:[NSMutableArray new]];
    }
    
    for ( id object in objects )
    {
        NSInteger sectionNumber = [[UILocalizedIndexedCollation currentCollation] sectionForObject:object collationStringSelector:selector];
        [mutableSections[sectionNumber] addObject:object];
    }
    
    for ( NSInteger idx = 0; idx < sectionTitlesCount; ++idx )
    {
        NSArray* objectsForSection = [mutableSections objectAtIndex:idx];
        [mutableSections replaceObjectAtIndex:idx withObject:[[UILocalizedIndexedCollation currentCollation] sortedArrayFromArray:objectsForSection collationStringSelector:selector]];
    }
    
    sections = mutableSections;
    [self.attendeesTableView reloadData];
}

- (void)updateTicketStatsAndNotifyObservers
{
    self.ticketStats = [[EEEventTicketStats alloc] initWithRegistrations:registrations];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTicketStatsUpdatedNotification
                                                        object:self];
}

- (void)updateTitleWithAttendeeCount:(NSUInteger)count
{
    if ( nil == self.event )
    {
        self.navigationItem.title = @"Please select an event";
    }
    else
    {
        static NSInteger const kMaxEventNameLength = 40;
        
        // If the length of the event name is too long, we need to truncate it
        // so that the attendee count is always visible.
        NSString* name = self.event.name;
        NSInteger length = name.length;

        if ( length > kMaxEventNameLength )
        {
            name = [NSString stringWithFormat:@"%@... ", [name substringToIndex:kMaxEventNameLength]];
        }
        
        if ( 0 == count )
        {
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - No Attendees", name];
        }
        else if ( 1 == count )
        {
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - 1 Attendee", name];
        }
        else
        {
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %d Attendees", name, count];
        }
    }
}

@end
