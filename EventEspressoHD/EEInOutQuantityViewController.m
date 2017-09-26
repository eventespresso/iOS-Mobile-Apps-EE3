//
//  EEInOutQuantityViewController.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 2/4/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import "EEInOutQuantityViewController.h"

@interface EEInOutQuantityViewController ()

@end

@implementation EEInOutQuantityViewController

#pragma mark - UIViewController Overrides

- (CGSize)contentSizeForViewInPopover
{
    return CGSizeMake(320, 260);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.pickerView.showsSelectionIndicator = YES;
}

#pragma mark UIPickerView DataSource Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.ticketCount;
}

#pragma mark UIPickerView Delegate Methods

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%d", row + 1];
}

#pragma mark - Target Actions

- (IBAction)done:(id)sender
{
    [self.delegate controller:self didSelectQuantity:[self.pickerView selectedRowInComponent:0] + 1];
}

- (IBAction)cancel:(id)sender
{
    [self.delegate controllerDidCancelQuantitySelection:self];
}

@end
