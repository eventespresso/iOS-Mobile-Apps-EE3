//
//  EEScannerViewController.m
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/17/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAdditionalAttendeeViewController.h"
#import "EEAttendee.h"
#import "EECheckInRequest.h"
#import "EECurrencyFormatter.h"
#import "EEDateFormatter.h"
#import "EEDateTime.h"
#import "EEEvent.h"
#import "EEGroupRegistration.h"
#import "EERegistration.h"
#import "EERegistrationsRequest.h"
#import "EEScannerViewController.h"
#import "EESoundVibeGenerator.h"
#import "EETicket.h"
#import "EETransaction.h"
#import "NSMutableArray+EventEspresso.h"
#import "NSUserDefaults+EventEspresso.h"
#import "SVProgressHUD.h"
#import "UIImage+iPhone5extension.h"


@interface EEScannerViewController ()
{
    ZBarImageScanner*       barcodeImageScanner;
    ZBarReaderView*         barcodeReaderView;
    EECheckInRequest*       checkInRequest;
    CGPoint                 couponDescriptionLabelCenter;
    BOOL                    paymentIncomplete;
    EERegistration*         registration;
    EERegistrationsRequest* registrationsRequest;
    EESoundVibeGenerator*   soundVibeGenerator;
    EETicket*               ticket;
    NSInteger               ticketsPurchased;
    NSInteger               ticketsRedeemed;
}

@property (nonatomic, strong) EEGroupRegistration* groupRegistration;

@end

@implementation EEScannerViewController

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if ( self )
    {
        // Initialize sound/vibration generator.
        NSURL* soundURL = [[NSBundle mainBundle] URLForResource: @"tick" withExtension:@"caf"];
        soundVibeGenerator = [[EESoundVibeGenerator alloc] initWithSoundURL:soundURL];
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"AttendeeDetail"] )
    {
        // Since we are re-using the additional-attendee view in order to display
        // details about the registrant of the scanned ticket, we need to disable
        // certain features that don't make sense in the context of the scanner
        // view.
        [segue.destinationViewController setDisableCheckInCheckOut:YES];
        [segue.destinationViewController setDisableDoneButton:YES];
        [segue.destinationViewController setRegistration:registration];
        
        if ( registration.additionalTickets && registration.additionalTickets.count > 0 )
        {
            [segue.destinationViewController setTicketsPurchased:registration.ticketsPurchased];
            [segue.destinationViewController setTicketsRedeemed:registration.ticketsRedeemed];
        }
        
        // We also need to remove the toolbar at the bottom since it is not
        // needed in the next view.
        self.navigationController.toolbarHidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    // Whether or not we display the toolbar depends upon the payment status.
    // If the payment is incomplete, we need to provide and override to allow
    // the user to check-in the attendee without payment.  The button for this
    // action is on the navigation toolbar at the bottom of the view.
    if ( paymentIncomplete )
    {
        [self moveDescriptionUp];
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    else
    {
        [self resetDescriptionLocation];
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Allocate and initialize the barcode scanner.
    barcodeImageScanner = [ZBarImageScanner new];
    [barcodeImageScanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
    barcodeReaderView = [[ZBarReaderView alloc] initWithImageScanner:barcodeImageScanner];
    barcodeReaderView.readerDelegate = self;
    barcodeReaderView.frame = self.view.bounds;
    [self.view insertSubview:barcodeReaderView belowSubview:self.scanResultView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Configure the nav bar.
    self.navigationController.toolbarHidden = YES;
    
    [barcodeReaderView start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [barcodeReaderView stop];
}

#pragma mark - Target Actions

- (IBAction)checkInWithoutPayment:(id)sender
{
    // If we are dealing with a group registration, fetch the group so we
    // have the correct count of tickets purchased.
    if ( registration.isGroupRegistration )
    {
        [self fetchGroupedRegistrationsWithCode:registration.code ignorePaymentStatus:YES];
    }
    else
    {
        ticketsPurchased = 1;
        ticketsRedeemed = (registration.isCheckedIn ? 1 : 0);
        [self checkInAttendeeWithQuantity:1 ignorePaymentStatus:YES];
    }
}

- (IBAction)displayAttendeeDetail:(id)sender
{
    [self performSegueWithIdentifier:@"AttendeeDetail" sender:self];
}

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)handleTapGesture:(id)sender
{
    // If the scan-result view is tapped go back to scanning for barcodes.
    UIGestureRecognizer* gestureRecognizer = sender;
    
    if ( gestureRecognizer.view == self.scanResultView )
    {
        [self.navigationController setToolbarHidden:YES animated:YES];
        self.scanResultView.hidden = YES;
        [barcodeReaderView flushCache];
        [barcodeReaderView start];
    }
}

#pragma mark - ZBarReaderView Delegate Methods

- (void)readerView:(ZBarReaderView *)readerView
    didReadSymbols:(ZBarSymbolSet *)symbols
         fromImage:(UIImage*)image
{
    // The only apparent way to get at the resulting bar-code data (payload) is
    // to use the NSFastEnumeration protocol; odd API design.
    for( ZBarSymbol* symbol in symbols)
    {
        MCLog(@"Raw bar-code data: %@",symbol.data);
        
        NSString* barcodeData = [symbol.data stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        barcodeData = [barcodeData stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"Cooked bar-code data: %@", barcodeData);
        
        NSError* error = nil;
        
        id jsonObject = [NSJSONSerialization JSONObjectWithData:[barcodeData dataUsingEncoding:NSUTF8StringEncoding]
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
        
        if ( jsonObject )
        {
            if ( [jsonObject isKindOfClass:[NSDictionary class]] )
            {
                // The dictionary must contain the event-ID, registration-ID and
                // attendee-ID.
                if ( [[jsonObject allKeys] count] >= 3 )
                {
                    [soundVibeGenerator play];
                    
                    ticket = [EETicket ticketWithJSONDictionary:jsonObject];
                    
                    // If an event is provided with this controller, then only
                    // tickets matching the provided event will be accepted.
                    // If an event is not provided, then we will attempt to lookup
                    // the associated event based on the ticket information and
                    // make sure the attendee and registration are valid.
                    if ( [ticket.eventCode isEqualToString:self.event.code] )
                    {
                        // Make sure returned ticket payload is valid.
                        if ( ticket.eventCode.length > 0 &&
                            ticket.attendeeID.length > 0 &&
                            ticket.registrationID.length > 0 )
                        {
                            [self fetchRegistrationForTicket];
                        }
                        else
                        {
                            [self showUnrecognizedBarcodeAlert];
                        }
                    }
                    else
                    {
                        if ( nil == self.event )
                        {
                            [self fetchRegistrationForTicket];
                        }
                        else
                        {
                            [self displayRejectedTicket];
                        }
                    }
                }
                else
                {
                    [self showUnrecognizedBarcodeAlert];
                }
            }
        }
        else
        {
            NSLog(@"Unrecognized barcode due to JSON deserialization error: %@", error);
            [self showUnrecognizedBarcodeAlert];
        }
        
        // We are only interested in the first symbol (apparently) so we return
        // here.  If never find one, then we end up alerting the user that this
        // ticket is invalid.
        return;
    }
 
    MCLog(@"Unrecognized barcode due to invalid or missing data");
    [self showUnrecognizedBarcodeAlert];
}

#pragma mark - EEInOutQuantityViewController Delegate Methods

- (void)controller:(EEInOutQuantityViewController *)controller didSelectQuantity:(NSInteger)quantity
{
    // Perform requested operation with requested count and then dismiss controller.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkInAttendeeWithQuantity:quantity ignorePaymentStatus:controller.ignorePaymentStatus];
    });
    
    [self dismissInOutQuantityView];
}

- (void)controllerDidCancelQuantitySelection:(EEInOutQuantityViewController *)controller
{
    // Assume only one ticket should be checked-in and continue.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkInAttendeeWithQuantity:1 ignorePaymentStatus:controller.ignorePaymentStatus];
    });
    
    [self dismissInOutQuantityView];
}

#pragma mark - Private Methods

- (void)checkInAttendeeWithQuantity:(NSInteger)quantity
                ignorePaymentStatus:(BOOL)ignorePaymentStatus
{
    if ( ignorePaymentStatus )
    {
        [self resetDescriptionLocation];
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
    
    [SVProgressHUD showWithStatus:@"Loading"];
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    checkInRequest = [EECheckInRequest requestWithRegistrationID:[registration ID] quantity:quantity ignorePaymentStatus:ignorePaymentStatus sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        
        if ( error )
        {
            if ( 500 == error.code )
            {
                [self displayAlreadyCheckedIn];
            }
            else
            {
                MCLog(@"Check-in request failed with error: %@", error);
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-In Failed!" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
        else
        {
            EERegistration* returnedRegistration = checkInRequest.returnedRegistrations[0];
            MCLog(@"%@", returnedRegistration);
            [self displayCheckInSuccess];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate receivedUpdatedRegistration:registration];
            });

            // For registrations with multiple tickets for a user, we need to
            // refresh our ticket information to know what the current redeemed
            // count is (this is painful because the updated redeemed count is
            // not returned from the API).
            if ( registration.additionalTickets != 0 )
            {
                [SVProgressHUD showWithStatus:@"Loading"];
                
                // In this context registrationID is the same as the registration.code.
                NSString* queryParams = [NSString stringWithFormat:@"?Event.code=%@&code=%@&Attendee.id=%@", ticket.eventCode, ticket.registrationID, ticket.attendeeID];
                
                NSLog(@"Registrations query parameters: %@", queryParams);
                
                registrationsRequest = [EERegistrationsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
                    [SVProgressHUD dismiss];
                    
                    if ( error )
                    {
                        [self showRegistrationErrorAlert:error];
                    }
                    else
                    {
                        NSMutableArray* registrations = [NSMutableArray arrayWithArray:registrationsRequest.returnedRegistrations];
                        [registrations assignDuplicateAttendees];
                        registration = registrations[0];
                    }
                }];
            }
            else
            {
                registration = returnedRegistration;
            }
        }
    }];
}

- (void)dismissInOutQuantityView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)displayAlreadyCheckedIn
{
    [self displayRegistrationInfo];
    self.couponDescriptionLabel.textColor   = [UIColor redColor];
    self.resultImageView.image              = [UIImage imageNamedForDevice:@"declined"];
    
    if ( registration.ticketsPurchased > 1 )
    {
        self.couponDescriptionLabel.text    = @"All Tickets Already Checked In";
    }
    else
    {
        self.couponDescriptionLabel.text    = @"Attendee Already Checked In";
    }
}

- (void)displayCheckInSuccess
{
    [self displayRegistrationInfo];
    self.couponDescriptionLabel.text        = @"SUCCESS";
    self.couponDescriptionLabel.textColor   = [UIColor greenColor];
    self.resultImageView.image              = [UIImage imageNamedForDevice:@"accepted"];
}

- (void)displayPaymentIncomplete
{
    [self displayRegistrationInfo];
    self.couponDescriptionLabel.text        = @"Payment Incomplete";
    self.couponDescriptionLabel.textColor   = [UIColor redColor];
    self.resultImageView.image              = [UIImage imageNamedForDevice:@"declined"];
    [self moveDescriptionUp];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)displayRegistrationInfo
{
    self.attendeNameLabel.text      = registration.attendee.fullname;
    self.eventTimeLabel.text        = [NSString stringWithFormat:@"Time: %@", [[EEDateFormatter sharedFormatter] timeStringFromBackEndDateString:registration.datetime.eventStart]];
    self.registrationCodeLabel.text = registration.code;
    self.priceLabel.text            = [NSString stringWithFormat:@"Price: %@", [[EECurrencyFormatter sharedFormatter] stringFromNumber:registration.finalPrice]];
    self.priceOptionLabel.text      = [NSString stringWithFormat:@"Price Option: %@", registration.transaction.paymentGateway];
    self.ticketCountLabel.text      = [NSString stringWithFormat:@"Tkts: %d", registration.ticketsPurchased];
    self.scanResultView.hidden      = NO;
}

- (void)displayRegistrationNotFound
{
    self.attendeNameLabel.text              = @"";
    self.eventTimeLabel.text                = @"";
    self.registrationCodeLabel.text         = ticket.registrationID;
    self.priceLabel.text                    = @"";
    self.priceOptionLabel.text              = @"";
    self.ticketCountLabel.text              = @"";
    self.couponDescriptionLabel.text        = @"Registration not found!";
    self.couponDescriptionLabel.textColor   = [UIColor redColor];
    self.resultImageView.image              = [UIImage imageNamedForDevice:@"declined"];
    self.scanResultView.hidden              = NO;
}

- (void)displayRejectedTicket
{
    self.attendeNameLabel.text              = @"";
    self.eventTimeLabel.text                = @"";
    self.registrationCodeLabel.text         = ticket.registrationID;
    self.priceLabel.text                    = @"";
    self.priceOptionLabel.text              = @"";
    self.ticketCountLabel.text              = @"";
    self.couponDescriptionLabel.text        = @"Ticket is for a different event!";
    self.couponDescriptionLabel.textColor   = [UIColor redColor];
    self.resultImageView.image              = [UIImage imageNamedForDevice:@"declined"];
    self.scanResultView.hidden              = NO;
}

- (void)fetchGroupedRegistrationsWithCode:(NSString *)registrationCode
                      ignorePaymentStatus:(BOOL)ignorePaymentStatus
{
    [SVProgressHUD showWithStatus:@"Loading"];
    
    // Issue a network request for all registrations/attendees with this matching
    // code and that are associated with the given event. Results will be displayed
    // in table when the request completes.
    NSString* queryParams = [NSString stringWithFormat:@"?code=%@", registrationCode];
    
    NSLog(@"Registrations query parameters: %@", queryParams);
    
    registrationsRequest = [EERegistrationsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
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
                if ( [[obj ID] isEqualToNumber:registration.ID] )
                {
                    *stop = YES;
                    return YES;
                }
                
                return NO;
            }];
            
            NSAssert(index != NSNotFound,
                     @"Unabled to match registration to one returned from group fetch!");
            registration.additionalTickets = [returnedRegistrations[index] additionalTickets];
            
            // Now, create a group registration object in order to more easily
            // manage the complexity of EE group registration implementation.
            if ( returnedRegistrations.count > 1 )
            {
                self.groupRegistration = [EEGroupRegistration registrationWithRegistration:registration group:returnedRegistrations];
            }
            
            // Get the number of tickets purchased on this group registration.
            ticketsPurchased = registration.ticketsPurchased;
            ticketsRedeemed = registration.ticketsRedeemed;
            
            // Now that we have the group registration info, ask the user how
            // many tickets they want to check in, unless of course, there is
            // only one left.
            NSUInteger ticketsRemaining = ticketsPurchased - ticketsRedeemed;
            
            if ( ticketsPurchased > 1 && ticketsRemaining > 1 )
            {
                [self displayRegistrationInfo];
                
                EEInOutQuantityViewController* viewController = [[EEInOutQuantityViewController alloc] initWithNibName:@"EEInOutQuantityView" bundle:nil];
                viewController.delegate = self;
                viewController.ignorePaymentStatus = ignorePaymentStatus;
                viewController.in = YES;
                viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                viewController.ticketCount = ticketsRemaining;
                
                [self presentViewController:viewController
                                   animated:YES
                                 completion:nil];
            }
            else
            {
                [self checkInAttendeeWithQuantity:1 ignorePaymentStatus:ignorePaymentStatus];
            }
        }
        
        [SVProgressHUD dismiss];
    }];
}

- (void)fetchRegistrationForTicket
{
    [SVProgressHUD showWithStatus:@"Loading"];
    
    // In this context registrationID is the same as the registration.code.
    NSString* queryParams = [NSString stringWithFormat:@"?Event.code=%@&code=%@&Attendee.id=%@", ticket.eventCode, ticket.registrationID, ticket.attendeeID];
    
    NSLog(@"Registrations query parameters: %@", queryParams);
    
    registrationsRequest = [EERegistrationsRequest requestWithQueryParams:queryParams sessionKey:[NSUserDefaults standardUserDefaults].sessionKey URL:[NSURL URLWithString:self.endpoint] completion:^(NSError *error) {
        [SVProgressHUD dismiss];

        if ( error )
        {
            [self showRegistrationErrorAlert:error];
        }
        else
        {
            [barcodeReaderView stop];
            NSMutableArray* registrations = [NSMutableArray arrayWithArray:registrationsRequest.returnedRegistrations];
            MCLog(@"%@", registrationsRequest.returnedRegistrations);
            
            // If we have multiple tickts, use the -assignDuplicateAttendees method
            // as a convenience for determining how many there are and how many
            // have been redeemed.
            if ( registrations.count > 1 )
            {
                [registrations assignDuplicateAttendees];
            }
            
            if ( 1 == registrations.count )
            {
                registration = registrations[0];
                [self processRegistrationAndDisplayResult];
            }
            else
            {
                [self displayRegistrationNotFound];
            }
        }
    }];
}

- (void)moveDescriptionUp
{
    // We initialize the starting location on the fly for convenience.
    if ( CGPointEqualToPoint(couponDescriptionLabelCenter, CGPointZero) )
    {
        couponDescriptionLabelCenter = self.couponDescriptionLabel.center;
    }
    
    // If the description label is in it original location, animate it up so
    // that it may be read while the bottom toolbar is displayed.
    //
    // We need to introduce a slight delay because of some internal race-condition
    // with showing the label in its new location.  Apple's getting sloppy.
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ( CGPointEqualToPoint(self.couponDescriptionLabel.center, couponDescriptionLabelCenter) )
        {
            self.couponDescriptionLabel.center = CGPointMake(couponDescriptionLabelCenter.x,
                                                             couponDescriptionLabelCenter.y - 19.0f);
        }
    });
}

- (void)processRegistrationAndDisplayResult
{
    // Now that we have a registration to go with the ticket, enable the detail
    // button.
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    // If the registration is already checked-in or the payment status is not
    // completed, thumb-down.  Otherwise, try and check-in the attendee using
    // the registration information.
    if ( EERegStatusComplete != registration.transaction.status )
    {
        paymentIncomplete = YES;
        [self displayPaymentIncomplete];
    }
    else
    {
        // If we are dealing with a group registration, fetch the group so we
        // have the correct count of tickets purchased.
        if ( registration.isGroupRegistration )
        {
            [self fetchGroupedRegistrationsWithCode:registration.code
                                ignorePaymentStatus:NO];
        }
        else
        {
            paymentIncomplete = NO;
            
            ticketsPurchased = 1;
            ticketsRedeemed = (registration.isCheckedIn ? 1 : 0);
            [self checkInAttendeeWithQuantity:1 ignorePaymentStatus:NO];
        }
    }
}

- (void)resetDescriptionLocation
{
    // We initialize the starting location on the fly for convenience.
    if ( CGPointEqualToPoint(couponDescriptionLabelCenter, CGPointZero) )
    {
        couponDescriptionLabelCenter = self.couponDescriptionLabel.center;
    }
    
    // If the description label is not in its original location, animate it down
    // so that it is properly vertically centered for a view that does not have
    // a navigation toolbar.
    else if ( !CGPointEqualToPoint(self.couponDescriptionLabel.center, couponDescriptionLabelCenter) )
    {
        self.couponDescriptionLabel.center = couponDescriptionLabelCenter;
    }
}

- (void)showRegistrationErrorAlert:(NSError *)error
{
    [barcodeReaderView stop];
    // It is important that we use a delegate here in order to prevent multiple
    // reads of the barcode without the user first acknowledging the alert.
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Registration Error"
                                                    message:[error localizedDescription]
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
	[alert show];
}

- (void)showUnrecognizedBarcodeAlert
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Unrecognized barcode"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
	[alert show];
}

@end
