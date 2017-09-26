//
//  EEAttendeesViewController.m
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/19/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAttendee.h"
#import "EEAttendeeCell.h"
#import "EEAttendeeInfoViewController.h"
#import "EEAttendeesViewController.h"
#import "EECurrencyFormatter.h"
#import "EEDateTime.h"
#import "EEEvent.h"
#import "EEJSONRequest.h"
#import "EEPrice.h"
#import "EERegistration.h"
#import "EERegistrationsRequest.h"
#import "EEScannerViewController.h"
#import "EETransaction.h"
#import "NSMutableArray+EventEspresso.h"
#import "NSUserDefaults+EventEspresso.h"
#import "SVProgressHUD.h"


#define ATTENDEE_TABLE_IS_INDEXED \
    ([NSUserDefaults standardUserDefaults].attendeeIndexListThreshold <= registrations.count)

static NSString* const kAttendeeCellID  = @"AttendeeCell";
static NSString* const kBasicCellID     = @"BasicCell";

@interface EEAttendeesViewController ()
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
}
@end

@implementation EEAttendeesViewController

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
        EEScannerViewController* scanViewController = (EEScannerViewController *)[navController topViewController];
        [scanViewController setEndpoint:self.endpoint];
        
        // If there is no selected event, then we don't need delegate callbacks.
        // The user simply using the app as a ticket scanner and is not focusing
        // on a specific event.
        if ( self.event )
        {
            [scanViewController setDelegate:self];
            [scanViewController setEndpoint:self.endpoint];
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
    
    // Initialize the refresh-control and the start a refresh of the table's contents.
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
    
    [self refresh:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    // For now, we are not including the advanced-search feature.  Hide the
    // appropriate controls.
#if 0
    [self.navigationController setToolbarHidden:NO animated:YES];
}
#else
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
}
#endif

#pragma mark - Target Actions

- (IBAction)performAdvancedSearch:(id)sender
{
    [self performSegueWithIdentifier:@"SearchAttendees" sender:self];
}

- (IBAction)refresh:(id)sender
{
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing Attendees"];
    [self fetchRegistrations];
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
    return 106.0f;
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

- (EEAttendeeCell *)attendeeCellWithRegistation:(EERegistration *)registration
{
    EEAttendeeCell* cell                = (EEAttendeeCell *)[self.attendeesTableView dequeueReusableCellWithIdentifier:kAttendeeCellID];
    cell.amountPaidLabel.text           = [NSString stringWithFormat:@"Amount Pd: %@",
                                               [[EECurrencyFormatter sharedFormatter] stringFromNumber:registration.finalPrice]];
    cell.attendeeNameLabel.text         = [NSString stringWithFormat:@"Name: %@",
                                               registration.attendee.fullname];
    cell.registrationCodeLabel.text     = [NSString stringWithFormat:@"Reg Code: %@",
                                               registration.code];
    cell.priceOptionLabel.text          = [NSString stringWithFormat:@"Price Option: %@",
                                               registration.price.name];
    cell.eventTimeLabel.text            = [NSString stringWithFormat:@"Event Time: %@",
                                               registration.datetime.eventStartTime];
    cell.groupRegistrationLabel.text    = [NSString stringWithFormat:@"Registration Type: %@",
                                           registration.isGroupRegistration ? @"Group" : @"Single"];
    cell.accessoryType                  = registration.isCheckedIn ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

-(void)fetchRegistrations
{
    // Disable buttons while loading events.
    [self.navigationItem setHidesBackButton:YES animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
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
        [self.navigationItem setHidesBackButton:NO animated:YES];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
        if ( NO == manualRefreshInProgress )
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
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

- (void)updateTitleWithAttendeeCount:(NSUInteger)count
{
    if ( 0 == count )
    {
        self.navigationItem.title = @"No Attendees";
    }
    else if ( 1 == count )
    {
        self.navigationItem.title = @"1 Attendee";
    }
    else
    {
        self.navigationItem.title = [NSString stringWithFormat:@"%d Attendees", count];
    }
}

@end