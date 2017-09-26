//
//  EEMapViewController.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "EEMapViewController.h"
#import "EEVenue.h"


@interface EEMapViewController ()
{
    CLGeocoder* geocoder;
}

@end

@implementation EEMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // When this view loads its only task is to geocode and display the address
    // of the given venue.
    NSString* address = [NSString stringWithFormat:@"%@, %@, %@. %@",
                         self.venue.address,
                         self.venue.city,
                         self.venue.state,
                         self.venue.zip];
    geocoder = [CLGeocoder new];
    [geocoder geocodeAddressString:address
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     if ( error )
                     {
                         MCLog(@"Geocode failed with error: %@", error);

                         if ( kCLErrorGeocodeCanceled == error.code )
                         {
                             [self dismissViewControllerAnimated:YES completion:nil];
                         }
                         else
                         {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                 [alert show];
                             });
                         }
                     }
                     else
                     {
                         // Ideally a successful geocode result will be cingular.
                         // However, it doesn't hurt to make sure we handle all
                         // cases and display whatever data is returned.  Place-
                         // marks must be converted to displayable map placemarks,
                         // which are then converted into map annotation.  This
                         // is necessary in order to customize the title and sub-
                         // title for the annotation.
                         for ( CLPlacemark* placemark in placemarks )
                         {
                             MCLog(@"Placemark: %@", placemark);
                             MKPlacemark* mapPlacemark = [[MKPlacemark alloc] initWithPlacemark:placemark];
                             MKPointAnnotation* pointAnnotation = [MKPointAnnotation new];
                             pointAnnotation.coordinate = mapPlacemark.coordinate;
                             pointAnnotation.subtitle = mapPlacemark.title;
                             pointAnnotation.title = self.venue.name;
                             [self.mapView addAnnotation:pointAnnotation];
                         }
                         
                         [self zoomToRegionForPlacemark:placemarks[0]];
                     }
                 }];
}

#pragma mark - MKMapView Delegate Methods

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MKAnnotationView* annotationView = views[0];

    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [mapView selectAnnotation:annotationView.annotation animated:YES];
    });
}

#pragma mark - Target Actions

- (IBAction)done:(id)sender
{
    if ( geocoder.geocoding )
    {
        [sender setEnabled:NO]; // prevents multiple button events
        [geocoder cancelGeocode];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)mapTypeChanged:(id)sender
{
    [self.mapView setMapType:[sender selectedSegmentIndex]];
}

#pragma mark - Private Methods

- (void)zoomToRegionForPlacemark:(CLPlacemark *)placemark
{
    MKPlacemark* mapPlacemark = [[MKPlacemark alloc] initWithPlacemark:placemark];
    MKCoordinateRegion region = MKCoordinateRegionMake(mapPlacemark.coordinate,
                                                       MKCoordinateSpanMake(0.1, 0.1));
    [self.mapView setRegion:region animated:YES];
}

@end
