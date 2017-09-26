//
//  EEMapViewController.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>


@class EEVenue;

@interface EEMapViewController : UIViewController <MKMapViewDelegate>

@property (assign, nonatomic) EEVenue* venue;

@property (strong, nonatomic) IBOutlet MKMapView* mapView;

- (IBAction)done:(id)sender;
- (IBAction)mapTypeChanged:(id)sender;

@end
