//
//  EEAttendeeInfoViewController.m
//  EventEspressoHD
//
//  When this view is loaded, it is provided with the registration record that
//  has the attendee informtation for the attendee selected from the previous
//  view.  Optionally a list of associated registrations are provided.  If present,
//  these associated registrations are used to calculate the number of tickets
//  purchased as well as the number of tickets that have been redeemed.
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAttendee.h"
#import "EEAttendeeInfoCell.h"
#import "EEAttendeeInfoViewController.h"
#import "EEAttendeeNameCell.h"
#import "EEAttendeeSummaryCell.h"
#import "EECheckInRequest.h"
#import "EECheckOutRequest.h"
#import "EECurrencyFormatter.h"
#import "EEDateFormatter.h"
#import "EEDateTime.h"
#import "EEGroupRegistration.h"
#import "EEPrice.h"
#import "EERegistration.h"
#import "EERegistrationsRequest.h"
#import "EETransaction.h"
#import "NSMutableArray+EventEspresso.h"
#import "NSUserDefaults+EventEspresso.h"
#import "SVProgressHUD.h"

// Cell IDs
static NSString* const kAttendeeInfoCellID      = @"AttendeeInfoCellID";
static NSString* const kAttendeeNameCellID      = @"AttendeeNameCellID";
static NSString* const kAttendeeSummaryCellID   = @"AttendeeSummaryCellID";

// Section IDs & Ordering
static NSInteger const kAdditionalAttendeeSection = 2;
static NSInteger const kInfoSection = 1;
static NSInteger const kNameSection = 0;

// Row IDs & Ordering
typedef NS_ENUM(NSInteger, _AttendeeInfo) {
    AttendeeInfoEmail,
    AttendeeInfoPriceOption,
    AttendeeinfoPrice,
    AttendeeInfoPaymentType,
    AttendeeInfoPaymentStatus,
    AttendeeInfoEventTime,
    AttendeeInfoTicketsPurchased,
    AttendeeInfoTicketsRedeemed,
    AttendeeInfoRegistrationCode,
    AttendeeInfoRegistrationDate,
    AttendeeInfoRowCount /* this one must always be listed last */
} AttendeeInfo;

@interface EEAttendeeInfoViewController ()
{
    NSMutableDictionary*    attendeeRegCountMap;
    UIBarButtonItem*        checkInCheckOutButton;
    UISegmentedControl*     checkInCheckOutSegmentedControl;
    NSDateFormatter*        lastUpdateDateFormatter;
    NSInteger               numTicketsPending;
    EERegistrationsRequest* registrationsRequest;
    NSInteger               selectedAdditionalAttendeeRegistrationIndex;
    UIPopoverController*    ticketQuantityPopover;
    NSInteger               ticketsPurchased;
    NSInteger               ticketsRedeemed;
}

@property (nonatomic, strong) EEGroupRegistration* groupRegistration;

@end

@implementation EEAttendeeInfoViewController

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if ( self )
    {
        // Initialize date-formatter used by refresh controll logic.
        lastUpdateDateFormatter = [NSDateFormatter new];
        [lastUpdateDateFormatter setDateFormat:@"MMM d, h:mm a"];
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"AdditionalAttendee"] )
    {
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            EERegistration* registration = self.groupRegistration.additionalAttendeeRegistrations[selectedAdditionalAttendeeRegistrationIndex];
            EEAdditionalAttendeeViewController* viewController =
                (EEAdditionalAttendeeViewController *)[segue.destinationViewController topViewController];
            [viewController setDelegate:self];
            [viewController setRegistration:registration];
        }
        else
        {
            EERegistration* registration = self.groupRegistration.additionalAttendeeRegistrations[selectedAdditionalAttendeeRegistrationIndex];
            [segue.destinationViewController setDelegate:self];
            [segue.destinationViewController setRegistration:registration];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Display appropriate button based on checked-in/out status.
    if ( self.registration.isCheckedIn )
    {
        [self displayCheckOutButton];
    }
    else
    {
        [self displayCheckInButton];
    }
    
    // If we are dealing with a group registration, fetch the group and update
    // the display and processing option as needed.
    if ( self.registration.isGroupRegistration )
    {
        [self fetchGroupedRegistrationsWithCode:self.registration.code];
    }
    else
    {
        ticketsPurchased = 1;
        ticketsRedeemed = (self.registration.isCheckedIn ? 1 : 0);
    }
    
    // Initialize the refresh-control and then start a refresh of the table's
    // contents, assuming we have a valid session-key.
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Target Actions

- (IBAction)checkIn:(id)sender
{
    BOOL ignorePaymentStatus = (self.registration.transaction.status != EERegStatusComplete);
    [self checkInQuantity:1 ignorePaymentStatus:ignorePaymentStatus];
}

- (IBAction)checkInCheckOutSegmentSelected:(id)sender
{
    [sender setEnabled:NO];
    BOOL checkInTickets = (0 == [sender selectedSegmentIndex]);
    
    // If there is only one ticket remaining to be checked-in, we can proceed to
    // just checkin said ticket.  Otherwise, present uI to allow user to determine
    // the quantity of tickets to be checked-in.
    if ( checkInTickets && 1 == (ticketsPurchased - ticketsRedeemed) )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkInQuantity:1 ignorePaymentStatus:YES];
        });        
    }
    // If there is only one ticket that is currently redeemed, we can proceed to
    // just checkout said ticket.  Otherwise, present UI to allow user to determine
    // the quantity of tickets to be checked-out.
    else if ( NO == checkInTickets && 1 == ticketsRedeemed )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkOutQuantity:1];
        });
    }
    else
    {
        EEInOutQuantityViewController* viewController = [[EEInOutQuantityViewController alloc] initWithNibName:@"EEInOutQuantityView" bundle:nil];
        viewController.delegate = self;
        
        if ( 0 == [sender selectedSegmentIndex] )
        {
            // checkin one or more tickets
            NSUInteger ticketsRemaining = ticketsPurchased - ticketsRedeemed;
            NSAssert(ticketsRemaining > 1,
                     @"Ticket quantity should not be displayed unless there are two or more tickets remaining");
            viewController.in = YES;
            viewController.ticketCount = ticketsRemaining;
        }
        else
        {
            // checkout one or more tickets
            NSAssert(ticketsRedeemed > 1,
                     @"Ticket quantity should not be displayed unless there are two or more tickets already redeemed");
            viewController.in = NO;
            viewController.ticketCount = ticketsRedeemed;
        }
        
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            ticketQuantityPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
            ticketQuantityPopover.delegate = self;
            [ticketQuantityPopover presentPopoverFromBarButtonItem:checkInCheckOutButton
                                          permittedArrowDirections:UIPopoverArrowDirectionAny
                                                          animated:YES];
        }
        else
        {
            viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            
            [self presentViewController:viewController
                               animated:YES
                             completion:nil];
        }
    }
}

- (IBAction)checkInWithQuantity:(id)sender
{
    [sender setEnabled:NO];
    EEInOutQuantityViewController* viewController = [[EEInOutQuantityViewController alloc] initWithNibName:@"EEInOutQuantityView" bundle:nil];
    viewController.delegate = self;
    
    // checkin one or more tickets
    NSUInteger ticketsRemaining = ticketsPurchased - ticketsRedeemed;
    NSAssert(ticketsRemaining > 1,
             @"Ticket quantity should not be displayed unless there are two or more tickets remaining");
    viewController.in = YES;
    viewController.ticketCount = ticketsRemaining;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        ticketQuantityPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
        ticketQuantityPopover.delegate = self;
        [ticketQuantityPopover presentPopoverFromBarButtonItem:self.checkInOutButton
                                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                                      animated:YES];
    }
    else
    {
        viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        [self presentViewController:viewController
                           animated:YES
                         completion:nil];
    }
}

- (IBAction)checkOut:(id)sender
{
    [self checkOutQuantity:1];
}

- (IBAction)checkOutWithQuantity:(id)sender
{
    [sender setEnabled:NO];
    EEInOutQuantityViewController* viewController = [[EEInOutQuantityViewController alloc] initWithNibName:@"EEInOutQuantityView" bundle:nil];
    viewController.delegate = self;
    
    // checkout one or more tickets
    NSAssert(ticketsRedeemed > 1,
             @"Ticket quantity should not be displayed unless there are two or more tickets already redeemed");
    viewController.in = NO;
    viewController.ticketCount = ticketsRedeemed;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        ticketQuantityPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
        ticketQuantityPopover.delegate = self;
        [ticketQuantityPopover presentPopoverFromBarButtonItem:self.checkInOutButton
                                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                                      animated:YES];
    }
    else
    {
        viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        [self presentViewController:viewController
                           animated:YES
                         completion:nil];
    }
}

- (IBAction)refresh:(id)sender
{
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing attendee information"];
    [self fetchGroupedRegistrationsWithCode:self.registration.code];
}

#pragma mark - UITableView DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // The number of sections depends on whether or not this is a group
    // registration.  If so, there are three sections instead of two.
    if ( self.groupRegistration && self.groupRegistration.additionalAttendeeRegistrations.count > 0 )
    {
        return 3;
    }
    else
    {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( kNameSection == indexPath.section )
    {
        EEAttendeeNameCell* cell = [tableView dequeueReusableCellWithIdentifier:kAttendeeNameCellID];
        cell.attendeeNameLabel.text = self.registration.attendee.fullname;
        return cell;
    }
    else if ( kAdditionalAttendeeSection == indexPath.section )
    {
        return [self associatedAttendeeCellWithRegistation:self.groupRegistration.additionalAttendeeRegistrations[indexPath.row]];
    }
    else // kInfoSection
    {
        // All of the cells in this section are the same and are handled below.
        EEAttendeeInfoCell* cell = [tableView dequeueReusableCellWithIdentifier:kAttendeeInfoCellID];
        
        switch ( indexPath.row )
        {
            case AttendeeInfoEmail:
                if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
                {
                    cell.labelLabel.text = @"Email Address";
                }
                else // iPhone
                {
                    cell.labelLabel.text = @"Email";
                }
                cell.contentLabel.text = self.registration.attendee.email;
                break;
                
            case AttendeeInfoEventTime: {
                cell.labelLabel.text = @"Event Time";
                EEDateTime* datetime = self.registration.datetime;
                cell.contentLabel.text = [[EEDateFormatter sharedFormatter] timeStringFromBackEndDateString:datetime.eventStart];
                break;
            }
                
            case AttendeeInfoPaymentStatus:
                if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
                {
                    cell.labelLabel.text = @"Payment Status";
                }
                else // iPhone
                {
                    cell.labelLabel.text = @"Pmnt Status";
                }
                cell.contentLabel.text = self.registration.transaction.statusRaw;
                break;
                
            case AttendeeInfoPaymentType:
                if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
                {
                    cell.labelLabel.text = @"Payment Type";
                }
                else // iPhone
                {
                    cell.labelLabel.text = @"Pmnt Type";
                }
                cell.contentLabel.text = self.registration.transaction.paymentGateway;
                break;
                
            case AttendeeinfoPrice:
                cell.labelLabel.text = @"Price";
                cell.contentLabel.text = [[EECurrencyFormatter sharedFormatter] stringFromNumber:self.registration.finalPrice];
                break;
                
            case AttendeeInfoPriceOption:
                cell.labelLabel.text = @"Price Option";
                cell.contentLabel.text = self.registration.price.name;
                break;
                
            case AttendeeInfoRegistrationCode:
                if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
                {
                    cell.labelLabel.text = @"Registration Code";
                }
                else // iPhone
                {
                    cell.labelLabel.text = @"Reg. Code";
                }
                cell.contentLabel.text = self.registration.code;
                break;
                
            case AttendeeInfoRegistrationDate:
                if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
                {
                    cell.labelLabel.text = @"Registration Date";
                }
                else // iPhone
                {
                    cell.labelLabel.text = @"Reg. Date";
                }
                cell.contentLabel.text = [[EEDateFormatter sharedFormatter] dateStringFromBackEndDateString:self.registration.date];
                break;
                
            case AttendeeInfoTicketsPurchased:
                cell.labelLabel.text = @"Purchased";
                cell.contentLabel.text = [NSString stringWithFormat:@"%d", ticketsPurchased];
                break;
                
            default: // AttendeeInfoTicketsRedeemed:
                cell.labelLabel.text = @"Redeemed";
                cell.contentLabel.text = [NSString stringWithFormat:@"%d", ticketsRedeemed];
                break;
        }
        
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ( section )
    {
        case kAdditionalAttendeeSection:
            return self.groupRegistration.additionalAttendeeRegistrations.count;
            
        case kInfoSection:
            return AttendeeInfoRowCount;
            
        default: // kNameSection
            return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( kAdditionalAttendeeSection == section )
    {
        return @"Additional Attendees";
    }
    
    return nil;
}

#pragma mark - UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    selectedAdditionalAttendeeRegistrationIndex = indexPath.row;
    [self performSegueWithIdentifier:@"AdditionalAttendee" sender:self];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( kAdditionalAttendeeSection == indexPath.section )
    {
        return indexPath;
    }
    
    return nil;
}

#pragma mark - UIPopoverController Delegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self enableControls];
}

#pragma mark - EEAdditionalAttendeeViewController Delegate Methods

- (void)receivedUpdatedRegistration:(EERegistration *)registration
{
    if ( [self.groupRegistration updateAdditionalAttendeeRegistration:registration] )
    {
        [self.attendeeInfoTableView reloadData];
    }
}

#pragma mark - EEInOutQuantityViewController Delegate Methods

- (void)controller:(EEInOutQuantityViewController *)controller didSelectQuantity:(NSInteger)quantity
{
    // Perform requested operation with requested count and then dismiss controller.
    BOOL in = [controller in];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( in )
        {
            [self checkInQuantity:quantity ignorePaymentStatus:YES];
        }
        else
        {
            [self checkOutQuantity:quantity];
        }
    });
    
    [self dismissInOutQuantityView];
}

- (void)controllerDidCancelQuantitySelection:(EEInOutQuantityViewController *)controller
{
    // Dismiss controller without taking further action.
    [self dismissInOutQuantityView];
}

#pragma mark - Private Methods

- (EEAttendeeSummaryCell *)associatedAttendeeCellWithRegistation:(EERegistration *)registration
{
    EEAttendeeSummaryCell* cell = [self.attendeeInfoTableView dequeueReusableCellWithIdentifier:kAttendeeSummaryCellID];
    cell.attendeeNameLabel.text = registration.attendee.fullname;
    cell.priceLabel.text        = [[EECurrencyFormatter sharedFormatter] stringFromNumber:registration.finalPrice];
    cell.priceOptionLabel.text  = registration.price.name;
    
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

- (NSMutableDictionary *)computeAttendeeRegistrationCounts:(NSArray *)registrationArray
{
    // Determine the number of tickets for this attendee
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:registrationArray.count];
    
    for ( EERegistration* registration in registrationArray )
    {
        NSNumber* number = dict[registration.attendee.ID];
        
        if ( number )
        {
            number = @(number.integerValue + 1);
        }
        else
        {
            number = @1;
        }
        
        dict[registration.attendee.ID] = number;
    }
    
    return dict;
}

- (void)configureView
{
    // If this view is displaying a group registration with multiple tickets for
    // an attendee, we need to dynamically assign the check-in/check-out controls
    // based on the number of tickets and the number remaining to be checked-in
    // or checked-out. For multiple attendees, the check-in/check-out button
    // applies only to the primary registration.  Secondary registration are
    // checked-in and out in a different view.
    //
    // For a primary with multipl tickets, there are three different scenarios:
    // 1) All tickets are checked-in; 2) all tickets are checked-out; 3) some
    // tickets are checked-in.
    
    if ( ticketsPurchased > 1 )
    {
        // 1) All tickets are checked-in;
        if ( ticketsRedeemed == ticketsPurchased )
        {
            // Display check-out button that will allow the user to pick a quantity
            // value.
            [self displayMultipleCheckOutButton];
        }
        
        // 2) All tickets are checked-out;
        else if ( 0 == ticketsRedeemed )
        {
            // Display a check-out button that will allow the user to pick a quantity
            // value.
            [self displayMultipleCheckInButton];
        }
        
        // 3) Some tickets are checked-in;
        else
        {
            // Display two buttons in a segmented control that will allow the user
            // to check-in or check-out multiple tickets.
            [self displayCheckInCheckOutButton];
        }
    }
    else
    {
        // In this case we assume we are NOT dealing with a group registration
        // so we only need to determine if the user is checked-in or checked
        // out.
        if ( ticketsPurchased == ticketsRedeemed )
        {
            [self displayCheckOutButton];
        }
        else
        {
            [self displayCheckInButton];
        }
    }
}

- (void)checkInQuantity:(NSUInteger)quantity ignorePaymentStatus:(BOOL)ignorePaymentStatus
{
    // Let the user know we are busy.
    [SVProgressHUD showWithStatus:@"Loading"];
    
    // Issue request to check in registered attendee.
    numTicketsPending = quantity;
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    __block EECheckInRequest* checkInRequest = [EECheckInRequest requestWithRegistrationID:self.registration.ID quantity:quantity ignorePaymentStatus:ignorePaymentStatus sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        
        if ( error )
        {
            MCLog(@"Check-in request failed with error: %@", error);
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-In Failed!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            ticketsRedeemed += numTicketsPending;
            self.registration = checkInRequest.returnedRegistrations[0];
            [self.delegate receivedUpdatedRegistration:self.registration];
            [self configureView];
            [self.attendeeInfoTableView reloadData];
        }
    }];
}

- (void)checkOutQuantity:(NSUInteger)quantity
{
    // Let the user know we are busy.
    [SVProgressHUD showWithStatus:@"Loading"];
    
    // Issue request to check out registered attendee.
    numTicketsPending = quantity;
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    __block EECheckOutRequest* checkOutRequest = [EECheckOutRequest requestWithRegistrationID:self.registration.ID quantity:quantity sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        
        if ( error )
        {
            MCLog(@"Check-out request failed with error: %@", error);
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-Out Failed!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            ticketsRedeemed -= numTicketsPending;
            self.registration = checkOutRequest.returnedRegistrations[0];
            [self.delegate receivedUpdatedRegistration:self.registration];
            [self configureView];
            [self.attendeeInfoTableView reloadData];
        }
    }];
}

- (void)dismissInOutQuantityView
{
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        // iPad uses a popover controller.
        [ticketQuantityPopover dismissPopoverAnimated:YES];
    }
    else
    {
        // iPhone uses a modal view controller.
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self enableControls];
}

- (void)displayCheckInCheckOutButton
{
    if ( nil == checkInCheckOutButton )
    {
        // Create and assign control for check-in/check-out function.
        checkInCheckOutSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Check-In", @"Check-Out"]];
        checkInCheckOutSegmentedControl.momentary = YES;
        checkInCheckOutSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        checkInCheckOutButton = [[UIBarButtonItem alloc] initWithCustomView:checkInCheckOutSegmentedControl];
        [checkInCheckOutSegmentedControl addTarget:self
                                            action:@selector(checkInCheckOutSegmentSelected:)
                                  forControlEvents:UIControlEventValueChanged];
    }
    
    self.navigationItem.rightBarButtonItem = checkInCheckOutButton;
    self.navigationItem.title = nil;
}

- (void)displayCheckInButton
{
    if ( EERegStatusComplete == self.registration.transaction.status )
    {
        self.checkInOutButton.title = @"Check-in";
    }
    else
    {
        self.checkInOutButton.title = @"Check-In (ignore payment)";
    }
    
    [self.checkInOutButton setAction:@selector(checkIn:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
    self.navigationItem.title = @"Attendee Info";
}

- (void)displayCheckOutButton
{
    self.checkInOutButton.title = @"Check-out";
    [self.checkInOutButton setAction:@selector(checkOut:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
    self.navigationItem.title = @"Attendee Info";
}

- (void)displayMultipleCheckInButton
{
    if ( EERegStatusComplete == self.registration.transaction.status )
    {
        self.checkInOutButton.title = @"Check-in";
        self.navigationItem.title = @"Attendee Info";
    }
    else
    {
        self.checkInOutButton.title = @"Check-In (ignore payment)";
        self.navigationItem.title = nil;
    }
    
    [self.checkInOutButton setAction:@selector(checkInWithQuantity:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
}

- (void)displayMultipleCheckOutButton
{
    self.checkInOutButton.title = @"Check-out";
    [self.checkInOutButton setAction:@selector(checkOutWithQuantity:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
    self.navigationItem.title = @"Attendee Info";
}

- (void)enableControls
{
    [self.checkInOutButton setEnabled:YES];
    [checkInCheckOutButton setEnabled:YES];
    [checkInCheckOutSegmentedControl setEnabled:YES];
}

- (void)fetchGroupedRegistrationsWithCode:(NSString *)registrationCode
{
    [SVProgressHUD showWithStatus:@"Loading"];
    
    // Issue a network request for all registrations/attendees with this matching
    // code and that are associated with the given event. Results will be displayed
    // in table when the request completes.
    NSString* queryParams = [NSString stringWithFormat:@"?code=%@", registrationCode];
    
    NSLog(@"Registrations query parameters: %@", queryParams);
    
    registrationsRequest = [EERegistrationsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
        if ( self.refreshControl.isRefreshing )
        {
            [self refreshCompleted];
        }
        
        if ( error )
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unable to fetch group Registrations" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            // Process for duplicate attendee-registrations, which means
            // additional tickets.
            NSMutableArray* returnedRegistrations = [NSMutableArray arrayWithArray:registrationsRequest.returnedRegistrations];
            [returnedRegistrations assignDuplicateAttendees];
            
            // Copy the additional ticket info, if present.
            NSUInteger index = [returnedRegistrations indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if ( [[obj ID] isEqualToNumber:self.registration.ID] )
                {
                    *stop = YES;
                    return YES;
                }
                
                return NO;
            }];
            
            NSAssert(index != NSNotFound,
                     @"Unabled to match registration to one returned from group fetch!");
            self.registration.additionalTickets = [returnedRegistrations[index] additionalTickets];
            
            // Now, create a group registration object in order to more easily
            // manage the complexity of EE group registration implementation.
            if ( returnedRegistrations.count > 1 )
            {
                self.groupRegistration = [EEGroupRegistration registrationWithRegistration:self.registration group:returnedRegistrations];
            }

            // Get the number of tickets purchased on this group registration.
            ticketsPurchased = self.registration.ticketsPurchased;
            ticketsRedeemed = self.registration.ticketsRedeemed;

            [self.tableView reloadData];
        }
        
        [self configureView];
        [SVProgressHUD dismiss];
    }];
}

- (void)refreshCompleted
{
    NSString* lastUpdated = [NSString stringWithFormat:@"Last updated on %@",
                             [lastUpdateDateFormatter stringFromDate:[NSDate date]]];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
    [self.refreshControl endRefreshing];
}

@end
