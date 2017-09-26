//
//  EEAddressViewController.m
//  EventEspressoHD
//
//  This view display two lines of address information with a detailed disclosure
//  that, when tapped, will segue into a map view displaying the address on the
//  map.
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "EEAddressViewController.h"
#import "EEVenue.h"


@implementation EEAddressViewController

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"MapView"] )
    {
        // Pass address into map-view for display on map.
        [segue.destinationViewController setVenue:self.venue];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nameLabel.text = self.venue.name;
    self.addressLine1Label.text = self.venue.address;
    self.addressLine2Label.text = [NSString stringWithFormat:@"%@, %@. %@",
                                   self.venue.city,
                                   self.venue.state,
                                   self.venue.zip];
}

@end
