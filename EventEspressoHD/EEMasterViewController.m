//
//  EEMasterViewController.m
//  EventEspressoHD
//
//  The master view-controller for EventEspressoHD displays the events table-
//  view.  It is equivalent to the EEEventsViewController for the iPhone version
//  of the app.
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEDateFormatter.h"
#import "EEDateTime.h"
#import "EEDetailViewController.h"
#import "EEError.h"
#import "EEEvent.h"
#import "EEEventCell.h"
#import "EEEventsRequest.h"
#import "EEEventsViewController.h"
#import "EEMasterViewController.h"
#import "EEVenue.h"
#import "NSUserDefaults+EventEspresso.h"
#import "SVProgressHUD.h"


static NSString* const kBasicCellID = @"BasicCell";
static NSString* const kEventCellID = @"EventCell";

@interface EEMasterViewController ()
{
    NSDateFormatter*    dateFormatter;
    UISegmentedControl* eventDateFilterControl;
    NSArray*            events;
    UISegmentedControl* eventSortOptionControl;
    EEEventsRequest*    eventsRequest;
    NSDateFormatter*    lastUpdateDateFormatter;
    BOOL                manualRefreshInProgress;
    NSMutableArray*     matchingEvents;
    BOOL                searching;
    BOOL                searchLoading;
    NSMutableArray*     sections;
    EEEvent*            selectedEvent;
    UILabel*            toolbarLabel;
}

@end

@implementation EEMasterViewController

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    // Create etched label at in bottom toolbar for associated nav-controller.
    [self configureToolbarItems];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if ( self )
    {
        // Initialize date-formatter used by refresh controll logic.
        lastUpdateDateFormatter = [NSDateFormatter new];
        [lastUpdateDateFormatter setDateFormat:@"MMM d, h:mm a"];
        events = @[];
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"EventInfo"] )
    {
        [segue.destinationViewController setEndpoint:self.endpoint];
        [segue.destinationViewController setEvent:selectedEvent];
        [segue.destinationViewController setDetailViewController:self.detailViewController];
    }
    else if ( [segue.identifier isEqualToString:@"LoginView"] )
    {
        [segue.destinationViewController setDelegate:self];
    }
    else if ( [segue.identifier isEqualToString:@"ScanView"] )
    {
        // There is no selected event. The user simply using the app as a ticket
        // scanner and is not focusing on a specific event.
        UINavigationController* navController = segue.destinationViewController;
        EEScanViewController_iPad* scanViewController = (EEScanViewController_iPad *)[navController topViewController];
        [scanViewController setEndpoint:self.endpoint];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.detailViewController = (EEDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
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
                break;
            }
            @catch ( NSException* exception )
            {
                NSLog(@"Exception while attempting to configfure search-bar keyboard: %@", exception);
            }
        }
    }
    
    // Set initial state for event-date-filter
    eventDateFilterControl.selectedSegmentIndex = [NSUserDefaults standardUserDefaults].eventDateFilter ;
    
    // Set initial state for event-sort-option
    eventSortOptionControl.selectedSegmentIndex = ([NSUserDefaults standardUserDefaults].sortByDate ? 0 : 1);
        
    // Initialize the refresh-control and then start a refresh of the table's
    // contents, assuming we have a valid session-key.
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
    
    // If we don't have a session key, we must fetch one before we can do any
    // thing else.
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    
    if ( nil == sessionKey || 0 == sessionKey.length ||
        nil == self.endpoint || 0 == self.endpoint.length )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"LoginView" sender:self];
        });
    }
    else
    {
        [self refresh:self];
    }
}

#pragma mark - Target Actions

- (IBAction)displayMenu:(id)sender
{
    // Disable menu button in order to prevent multiple taps; display menu.
    self.menuButton.enabled = NO;
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Logout"
                                                    otherButtonTitles:@"Scan All Tickets", nil];
    [actionSheet showFromBarButtonItem:self.menuButton animated:YES];
}

- (IBAction)eventDateFilterChanged:(id)sender
{
    [NSUserDefaults standardUserDefaults].eventDateFilter = eventDateFilterControl.selectedSegmentIndex;
    [self fetchEvents];
}

- (IBAction)eventSortOptionChanged:(id)sender
{
    [NSUserDefaults standardUserDefaults].sortByDate = (0 == eventSortOptionControl.selectedSegmentIndex ? YES : NO);
    [self fetchEvents];
}

- (IBAction)refresh:(id)sender
{
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing Events"];
    [self fetchEvents];
}

#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // If the logout menu-item was selected then logout.  Otherwise, simply
    // dismiss the menu.
    if ( 0 == buttonIndex )
    {
        self.endpoint = nil;
        [NSUserDefaults standardUserDefaults].sessionKey = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"LoginView" sender:self];
        });
    }
    else if ( 1 == buttonIndex )
    {
        [self performSegueWithIdentifier:@"ScanView" sender:self];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Now that the menu is gone, re-enable the menu button.
    self.menuButton.enabled = YES;
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
        if ( EVENT_TABLE_IS_INDEXED )
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
        if ( EVENT_TABLE_IS_INDEXED )
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
        // this reason, we use a noEventCell to display that status.  Othwise
        // we will allocate a standard event-cell and populate it accordingly.
        if( nil == matchingEvents )
        {
            UITableViewCell* noEventsCell = [self.eventsTableView dequeueReusableCellWithIdentifier:kBasicCellID];
        	noEventsCell.textLabel.text = @"Searching ...";
			return noEventsCell;
        }
		else if ( 0 == matchingEvents.count )
        {
            UITableViewCell* noEventsCell = [self.eventsTableView dequeueReusableCellWithIdentifier:kBasicCellID];
			noEventsCell.textLabel.text = @"No Events";
			return noEventsCell;
		}
		else
        {
			EEEvent* event = matchingEvents[indexPath.row];
            return [self eventCellWithEvent:event];
		}
	}
	else
    {
        // In this case, we are asked for a cell for the events table-view. We
        // dequeue an instance of a blank cell and populate it with the data.
        if ( EVENT_TABLE_IS_INDEXED )
        {
            return [self eventCellWithEvent:sections[indexPath.section][indexPath.row]];
        }
        else
        {
            return [self eventCellWithEvent:events[indexPath.row]];
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
	 	if ( 0 == matchingEvents.count )
        {
		 	return 1;
	 	}
        else
        {
		 	return matchingEvents.count;
        }
    }
    
    // In this case, we always return the current count of events found.
    if ( EVENT_TABLE_IS_INDEXED )
    {
        return [sections[section] count];
    }
    else
    {
        return events.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( EVENT_TABLE_IS_INDEXED && ([sections[section] count] > 0) )
    {
        NSArray* sectionTitles = [[UILocalizedIndexedCollation currentCollation] sectionTitles];
        return sectionTitles[section];
    }
    
    return nil;
}

#pragma mark - UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
		if ( matchingEvents.count > 0 )
        {
            selectedEvent = matchingEvents[indexPath.row];
        }
    }
    else
    {
        if ( EVENT_TABLE_IS_INDEXED )
        {
            selectedEvent = sections[indexPath.section][indexPath.row];
        }
        else
        {
            selectedEvent = events[indexPath.row];
        }
    }
    
    self.detailViewController.event = selectedEvent;
    [self performSegueWithIdentifier:@"EventInfo" sender:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
		if ( matchingEvents.count > 0 )
        {
			selectedEvent = matchingEvents[indexPath.row];
		}
	}
    else
    {
        if ( EVENT_TABLE_IS_INDEXED )
        {
            selectedEvent = sections[indexPath.section][indexPath.row];
        }
        else
        {
            selectedEvent = events[indexPath.row];
        }
    }
    
    self.detailViewController.event = selectedEvent;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66.0f;
}

#pragma mark - UISearchBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [NSUserDefaults standardUserDefaults].eventDateFilter = selectedScope;
    [self.searchDisplayController setActive:NO animated:YES];
    [self fetchEvents];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if ( searchText.length > 0 )
    {
        searching = YES;
        
        if ( NO == searchLoading )
        {
            // Prevent the search from starting until at least three characters
            // have been entered into the search field.
            if ( 3 == searchText.length )
            {
                [self fetchEventsForSubstring:searchText];
            }
            else if ( searchText.length > 3 )
            {
                [self populateMatchingEvents:events];
            }
        }
	}
	else
    {
        matchingEvents = nil;
        [self.searchDisplayController.searchBar resignFirstResponder];
        [self.searchDisplayController.searchResultsTableView reloadData];
		searching = NO;
	}
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Hide keyboard when the cancel button is clicked.
	[searchBar resignFirstResponder];
    [self.searchDisplayController setActive:NO animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Hide the keyboard when the search button is clicked.
    [searchBar resignFirstResponder];
    [self.searchDisplayController setActive:NO animated:YES];
}

#pragma mark - EELoginViewController Delegate Methods

- (void)loginFailedWithError:(NSError *)error
{
    MCLog(@"EELoginViewControlle failed: %@", error);
}

- (void)loginSucceededWithSessionKey:(NSString *)sessionKey endpoint:endpoint
{
    [NSUserDefaults standardUserDefaults].endpoint = endpoint;
    [NSUserDefaults standardUserDefaults].sessionKey = sessionKey;
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.endpoint = endpoint;
    self.detailViewController.endpoint = endpoint;
    [self dismissViewControllerAnimated:YES completion:^{
        [self refresh:self];
    }];
}

#pragma mark - Private Methods

- (void)configureToolbarItems
{
    eventDateFilterControl = [[UISegmentedControl alloc] initWithItems:@[@"Today", @"Future", @"Past"]];
    eventDateFilterControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    [eventDateFilterControl addTarget:self
                               action:@selector(eventDateFilterChanged:)
                     forControlEvents:UIControlEventValueChanged];
    
    eventSortOptionControl = [[UISegmentedControl alloc] initWithItems:@[@"Date", @"Name"]];
    eventSortOptionControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    [eventSortOptionControl addTarget:self
                               action:@selector(eventSortOptionChanged:)
                     forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem* control = [[UIBarButtonItem alloc] initWithCustomView:eventDateFilterControl];

    UIBarButtonItem* control2 = [[UIBarButtonItem alloc] initWithCustomView:eventSortOptionControl];
    
    UIBarButtonItem* spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                               UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[control, spacer, control2];
}

- (EEEventCell *)eventCellWithEvent:(EEEvent *)event
{
    EEEventCell* cell = (EEEventCell *)[self.eventsTableView dequeueReusableCellWithIdentifier:kEventCellID];
    
    cell.eventLabel.text = event.name;
    
    if ( 0 == event.venues.count || [event.venues[0][kVenueNameKey] isEqualToString:@""] )
    {
        cell.venueLabel.text = @"Venue not available";
    }
    else
    {
        cell.venueLabel.text = event.venues[0][kVenueNameKey];
    }
    
    EEDateTime* datetime = [EEDateTime datetimeWithJSONDictionary:event.datetimes[0]];
    cell.dateInfoLabel.text = [[EEDateFormatter sharedFormatter] dateTimeStringFromBackEndDateString:datetime.eventStart];
    return cell;
}

- (void)fetchEvents
{
    // This will eventually disable the processing where we automatically switch
    // the event-date filter trying desperately to find some data to display to
    // the user.
    [NSUserDefaults standardUserDefaults].fetchRequestCount++;
    
    // If the user is not dragging down the view to invoke the refresh control,
    // we assume this fetch is requested programatically.
    if ( self.eventsTableView.contentOffset.y >= 0 )
    {
        [SVProgressHUD showWithStatus:@"Loading"];
    }
    else
    {
        manualRefreshInProgress = YES;
    }
    
    // Taking the current date-fileter setting into account, issue a network
    // request for all events.  Once completed received event info will be
    // displayed in updated table.
    EventDateFilter filterMode = [NSUserDefaults standardUserDefaults].eventDateFilter;
    NSUInteger queryLimit = [NSUserDefaults standardUserDefaults].eventsQueryLimit;
    NSString* queryParams = nil;
    NSDate* today = [NSDate date];
    
    if ( queryLimit > 0 )
    {
        if ( EventDateFilterToday == filterMode )
        {
            queryParams = [NSString stringWithFormat:@"?%@&limit=%d",
                           [self parameterStringForTodaysEvents],
                           queryLimit];
        }
        else if ( EventDateFilterUpcoming == filterMode )
        {
            queryParams = [NSString stringWithFormat:@"?Datetime.event_start__gt=%@&limit=%d",
                           [self stringFromDate:today],
                           queryLimit];
        }
        else // EventDateFilterPast
        {
            queryParams = [NSString stringWithFormat:@"?Datetime.event_start__lt=%@&limit=%d",
                           [self stringFromDate:today],
                           queryLimit];
        }
    }
    else
    {
        if ( EventDateFilterToday == filterMode )
        {
            queryParams = [NSString stringWithFormat:@"?%@",
                           [self parameterStringForTodaysEvents]];
        }
        else if ( EventDateFilterUpcoming == filterMode )
        {
            queryParams = [NSString stringWithFormat:@"?Datetime.event_start__gt=%@",
                           [self stringFromDate:today]];
        }
        else // EventDateFilterPast
        {
            queryParams = [NSString stringWithFormat:@"?Datetime.event_start__lt=%@",
                           [self stringFromDate:today]];
        }
    }
    
    queryParams = [queryParams stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
    NSLog(@"Events query parameters: %@", queryParams);
    
    eventsRequest = [EEEventsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
        if ( error )
        {
            [self updateTitleWithEventCount:0];
            self.detailViewController.event = nil;
            
            if ( EspressoAPIErrorDomain == error.domain && 403 == error.code )
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Events"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            // The request succeeded but even so, we must handle the case where
            // no events were returned.
            events = eventsRequest.returnedEvents;
            
            if ( EVENT_TABLE_IS_INDEXED )
            {
                [self setObjects:events];
            }
            else
            {
                NSSortDescriptor* sortByDate = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
                NSSortDescriptor* sortByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                
                if ( [NSUserDefaults standardUserDefaults].sortByDate )
                {
                    events = [events sortedArrayUsingDescriptors:@[sortByDate, sortByName]];
                }
                else
                {
                    events = [events sortedArrayUsingDescriptors:@[sortByName, sortByDate]];
                }
                
                [self.eventsTableView reloadData];
            }
            
            [self updateTitleWithEventCount:events.count];
            
            if ( events.count )
            {
                [NSUserDefaults standardUserDefaults].fetchRequestSucceeded = YES;
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                
                // Locate the first section with a valid event and assign said
                // event to the detail view controller in order to display the
                // attendee list.
                if ( EVENT_TABLE_IS_INDEXED )
                {
                    [sections enumerateObjectsUsingBlock:^(id eventsInSection, NSUInteger sectionIndex, BOOL* stop) {
                        if ( [eventsInSection count] > 0 )
                        {
                            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
                            [self.eventsTableView selectRowAtIndexPath:indexPath
                                                              animated:NO
                                                        scrollPosition:UITableViewScrollPositionTop];
                            self.detailViewController.event = eventsInSection[0];
                            *stop = YES;
                        }
                    }];
                }
                else
                {
                    self.detailViewController.event = events[0];
                }
            }
            else
            {
                self.detailViewController.event = nil;
                
                // In the case where the filter is set for today or upcoming and there
                // are no events, switch the event-date-filter to the past in hopes
                // that we find some.
                if ( NO == [NSUserDefaults standardUserDefaults].fetchRequestSucceeded )
                {
                    if ( [NSUserDefaults standardUserDefaults].fetchRequestCount < EventDataFilterCount )
                    {
                        if ( EventDateFilterToday == eventDateFilterControl.selectedSegmentIndex )
                        {
                            [eventDateFilterControl setSelectedSegmentIndex:EventDateFilterUpcoming];
                        }
                        else if ( EventDateFilterUpcoming == [NSUserDefaults standardUserDefaults].eventDateFilter )
                        {
                            [eventDateFilterControl setSelectedSegmentIndex:EventDateFilterPast];
                        }
                        else // EventDateFilterPast
                        {
                            [eventDateFilterControl setSelectedSegmentIndex:EventDateFilterToday];
                        }
                        
                        [NSUserDefaults standardUserDefaults].eventDateFilter = eventDateFilterControl.selectedSegmentIndex;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self fetchEvents];
                        });
                    }
                }
            }
        }
        
        [self refreshCompleted];
        
        if ( NO == manualRefreshInProgress )
        {
            // We pop instead of dismiss since the detail view also shows activity.
            [SVProgressHUD popActivity];
        }
        else
        {
            manualRefreshInProgress = NO;
        }
    }];
}


- (void)fetchEventsForSubstring:(NSString*)substring
{
    searchLoading = YES;
    
    NSString* queryParams = [NSString stringWithFormat:@"?name__like=%%%@%%", substring];
    
    EventDateFilter filterMode = [NSUserDefaults standardUserDefaults].eventDateFilter;
    
    NSDate* today = [NSDate date];
    
    if ( EventDateFilterToday == filterMode )
    {
        queryParams = [NSString stringWithFormat:@"%@&%@&limit=%d",
                       queryParams,
                       [self parameterStringForTodaysEvents],
                       [NSUserDefaults standardUserDefaults].eventsQueryLimit];
    }
    else if ( EventDateFilterUpcoming == filterMode )
    {
        queryParams = [NSString stringWithFormat:@"%@&Datetime.event_start__gt=%@&limit=%d",
                       queryParams,
                       [self stringFromDate:today],
                       [NSUserDefaults standardUserDefaults].eventsQueryLimit];
    }
    else // EventDateFilterPast
    {
        queryParams = [NSString stringWithFormat:@"%@&Datetime.event_start__lt=%@&limit=%d",
                       queryParams,
                       [self stringFromDate:today],
                       [NSUserDefaults standardUserDefaults].eventsQueryLimit];
    }
    
    queryParams = [queryParams stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
    NSLog(@"Event query parameters: %@", queryParams);
    
    eventsRequest = [EEEventsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
        if ( error )
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Events" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            // filterActivityIndicater is stopped in called method
            [self populateMatchingEvents:eventsRequest.returnedEvents];
        }
        
        searchLoading = NO;
    }];
}

- (NSString *)parameterStringForTodaysEvents
{
    // Assemble a dates to be used to test for a date that starts before midnight
    // and ends after the start of today.  Then, format it into a parameter string.
    // Start by getting the date components for today's date.
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    NSDateComponents* components = [calendar components:unitFlags fromDate:[NSDate date]];
    
    // Next, add the time components for the beginning of the range and create
    // the first date.
    components.hour     = 0;
    components.minute   = 0;
    components.second   = 0;
    
    NSDate* endDate = [calendar dateFromComponents:components];
    
    // Finally, create the end of the range and format the string with the
    // generated dates.
    components = [NSDateComponents new];
    components.day = 1;
    NSDate* startDate = [calendar dateByAddingComponents:components toDate:endDate options:0];

    return [NSString stringWithFormat:
            @"Datetime.event_start__lt=%@&Datetime.event_end__gt=%@",
            [self stringFromDate:startDate],
            [self stringFromDate:endDate]];
}

- (void)populateMatchingEvents:(NSArray *)returnedEvents
{
    if ( nil == matchingEvents )
    {
        matchingEvents = [NSMutableArray new];
    }
    
    if ( searching )
    {
        [matchingEvents removeAllObjects];
        
        NSString* searchText = self.searchDisplayController.searchBar.text;
        
        for ( EEEvent* event in returnedEvents )
        {
            NSRange titleResultsRange = [event.name rangeOfString:searchText
                                                          options:NSCaseInsensitiveSearch];
            
            if ( titleResultsRange.length > 0 )
            {
                [matchingEvents addObject:event];
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
    SEL selector = @selector(name);
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
    
    [self.eventsTableView reloadData];
}

-(NSString *)stringFromDate:(NSDate *)dateString
{
    if ( nil == dateFormatter )
    {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	}
    
	return [dateFormatter stringFromDate:dateString];
}

- (void)updateTitleWithEventCount:(NSUInteger)count
{
    if ( 0 == count )
    {
        self.navigationItem.title = @"No Events";
    }
    else if ( 1 == count )
    {
        self.navigationItem.title = @"1 Event";
    }
    else
    {
        self.navigationItem.title = [NSString stringWithFormat:@"%d Events", count];
    }
}

@end
