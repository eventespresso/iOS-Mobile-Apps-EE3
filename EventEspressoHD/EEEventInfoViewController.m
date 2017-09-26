//
//  EEEventInfoViewController.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAddressViewController.h"
#import "EEDateTime.h"
#import "EEDetailViewController.h"
#import "EEEvent.h"
#import "EEEventInfoViewController.h"
#import "EEEventTicketStats.h"
#import "EEVenue.h"


@interface EEEventInfoViewController ()
{
    EEVenue* venue;
}

@end

@implementation EEEventInfoViewController

#pragma mark - Cleanup

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTicketStatsUpdatedNotification
                                                  object:self.detailViewController];
}

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"AddressView"] )
    {
        [segue.destinationViewController setVenue:venue];
        UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
        popoverSegue.popoverController.popoverContentSize = CGSizeMake(280, 85);
    }
    else if ( [segue.identifier isEqualToString:@"ScanView"] )
    {
        [segue.destinationViewController setEndpoint:self.endpoint];
        [segue.destinationViewController setEvent:self.event];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kTicketStatsUpdatedNotification
                                                      object:_detailViewController
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* notification) {
                                                      [self updateTicketStats];
                                                  }];
    
    self.nameLabel.text             = self.event.name;
    EEDateTime* datetime            = [EEDateTime datetimeWithJSONDictionary:self.event.datetimes[0]];
    self.endDateLabel.text          = datetime.eventEndDate;
    self.endTimeLabel.text          = datetime.eventEndTime;
    self.startDateLabel.text        = datetime.eventStartDate;
    self.startTimeLabel.text        = datetime.eventStartTime;    
    self.capacityLabel.text         = [NSString stringWithFormat:@"%d", self.event.limit];

    if ( 0 == self.event.venues.count || [self.event.venues[0][kVenueNameKey] isEqualToString:@""] )
    {
        self.venueLabel.text = @"N/A";
        self.venueCell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        venue = [EEVenue venueWithJSONDictionary:self.event.venues[0]];
        self.venueLabel.text = self.event.venues[0][kVenueNameKey];
        self.venueCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self updateTicketStats];
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Display address details popover.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"AddressView" sender:self];
}

- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only the venue cell is selectable.  We use this to display detailed map
    // information.  Currently that cell is located at the table coordiates 1,0.
    if ( 1 == indexPath.section && 0 == indexPath.row )
    {
        if ( self.event.venues.count > 0 && [self.event.venues[0][kVenueNameKey] length] > 0 )
        {
            return indexPath;
        }
    }
    
    return nil;
}

#pragma mark - Private Methods

- (void)updateTicketStats
{
    EEEventTicketStats* stats = self.detailViewController.ticketStats;
    
    self.ticketsSoldLabel.text      = [NSString stringWithFormat:@"%d", stats.numTicketsSold];
    self.ticketsPaidLabel.text      = [NSString stringWithFormat:@"%d", stats.numTicketsPaid];
    self.ticketsRedeemedLabel.text  = [NSString stringWithFormat:@"%d", stats.numTicketsRedeemed];
    self.ticketsUnpaidLabel.text    = [NSString stringWithFormat:@"%d", stats.numTicketsUnpaid];
    self.freeAdmissionLabel.text    = [NSString stringWithFormat:@"%d", stats.numFreeAdmissionTickets];
    
    if ( self.event.limit >= 99999 )
    {
        self.ticketsAvailableLabel.text = @"Unlimited";
    }
    else
    {
        self.ticketsAvailableLabel.text = [NSString stringWithFormat:@"%d",
                                           self.event.limit - stats.numTicketsSold];
    }
}

@end
