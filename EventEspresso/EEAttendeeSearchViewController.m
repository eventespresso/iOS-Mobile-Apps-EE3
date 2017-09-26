//
//  EEAttendeeSearchViewController.m
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/17/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAttendeeSearchViewController.h"
#import "EEAttendeesRequest.h"
#import "EEEvent.h"
#import "UIView+EventEspresso.h"


static CGFloat const kKeyboardToolbarHeight = 40.0f;

@interface EEAttendeeSearchViewController ()
{
    EEAttendeesRequest* attendeeRequest;
	UIToolbar*          keyboardToolbar;
	UISegmentedControl* nextPrevControl;
}

@end

@implementation EEAttendeeSearchViewController

#pragma mark - View Lifecycle Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self dismissKeyboard:self];
    
    
    if ( [segue.identifier isEqualToString:@"AllAttendees"] ||
        [segue.identifier isEqualToString:@"FoundAttendees"] )
    {
        [segue.destinationViewController setEndpoint:self.endpoint];
        [segue.destinationViewController setEvent:self.event];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


#pragma mark - Target Actions

- (IBAction)dismissKeyboard:(id)sender
{
	[[self.view findFirstResponder] resignFirstResponder];
}

- (IBAction)fetchAllAttendees:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unimplemented Function"
                                                    message:@"This feature should be available in next build."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)searchAttendees:(id)sender
{
    if ( 0 == self.firstnameTextField.text.length &&
         0 == self.lastnameTextField.text.length &&
         0 == self.emailTextField.text.length &&
         0 == self.phoneTextField.text.length )
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Info Missing"
                                                        message:@"Please enter search terms or you can view all attendees."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unimplemented Function"
                                                        message:@"This feature should be available in next build."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)nextPrevious:(id)sender
{
	UIView* responder = [self.view findFirstResponder];
	
	switch( [(UISegmentedControl *)sender selectedSegmentIndex] )
    {
		case 1: // previous
			if ( responder == self.firstnameTextField )
            {
				[self.lastnameTextField becomeFirstResponder];
			}
            else if ( responder == self.lastnameTextField )
            {
				[self.emailTextField becomeFirstResponder];
			}
            else if ( responder == self.emailTextField )
            {
				[self.phoneTextField becomeFirstResponder];
			}
			else if ( responder == self.phoneTextField )
            {
				[self.firstnameTextField becomeFirstResponder];
			}
			break;
            
		case 0: // next
			if ( responder == self.firstnameTextField )
            {
				[self.phoneTextField becomeFirstResponder];
			}
            else if ( responder == self.lastnameTextField )
            {
				[self.firstnameTextField becomeFirstResponder];
			}
            else if ( responder == self.emailTextField )
            {
				[self.lastnameTextField becomeFirstResponder];
			}
			else if ( responder == self.phoneTextField )
            {
				[self.emailTextField becomeFirstResponder];
			}
			break;
	}
	
}

#pragma mark - UITextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	CGPoint textFiledOriginInWindow = [textField.superview convertPoint:textField.frame.origin toView:nil];
	[self.view moveUp:(int)(textFiledOriginInWindow.y - 84) withAnimation:YES];
    
	CGPoint textFieldOriginInWindow = [textField.superview convertPoint:textField.frame.origin toView:nil];
    [self.view moveUp:(int)(textFieldOriginInWindow.y - 84) withAnimation:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[self.view moveToOriginWithAnimation:YES];
}

#pragma mark - UIKeyboard Notification Handlers

- (void)keyboardWillHide:(NSNotification *)notification
{
    // If we are currently displaying a keyboard toolbar, we must animation it
    // away along with the keyboard that is about to hide.
    
	if ( keyboardToolbar != nil )
    {
        UIViewAnimationCurve animationCurve	= [[[notification userInfo] valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        NSTimeInterval animationDuration = [[[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [UIView beginAnimations:@"EEHideKeyboardAnimation" context:nil];
        [UIView setAnimationCurve:animationCurve];
        [UIView setAnimationDuration:animationDuration];
        
        keyboardToolbar.alpha = 0.0f;
        keyboardToolbar.frame = CGRectMake(0.0f,
                                           self.view.bounds.size.height + kKeyboardToolbarHeight,
                                           self.view.bounds.size.width,
                                           kKeyboardToolbarHeight);
        [UIView commitAnimations];
	}
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    // Animate in a toolbar on top of the virtual keyboard.  Create the toolbar
    // if needed.
    
    CGRect keyboardFrame = [[[notification userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	
    if ( nil == keyboardToolbar )
    {
        keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,
                                                                      0,
                                                                      self.view.bounds.size.width,
                                                                      kKeyboardToolbarHeight)];
        keyboardToolbar.barStyle = UIBarStyleBlackTranslucent;
        keyboardToolbar.tintColor = [UIColor darkGrayColor];
        
        UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard:)];
        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        nextPrevControl = [[UISegmentedControl alloc] initWithItems:
                           @[NSLocalizedString(@"Previous", @"Previous form field"),
                           NSLocalizedString(@"Next", @"Next form field")]];
        nextPrevControl.segmentedControlStyle = UISegmentedControlStyleBar;
        nextPrevControl.tintColor = [UIColor darkGrayColor];
        nextPrevControl.momentary = YES;
        [nextPrevControl addTarget:self
                            action:@selector(nextPrevious:)
                  forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem* segmentedControlItem = [[UIBarButtonItem alloc] initWithCustomView:nextPrevControl];
        
        NSArray* toolbarItems = @[segmentedControlItem, flexibleSpace, button];
        [keyboardToolbar setItems:toolbarItems];
        
        keyboardToolbar.frame = CGRectMake(keyboardFrame.origin.x,
                                           keyboardFrame.origin.y - keyboardToolbar.frame.size.height,
                                           keyboardToolbar.frame.size.width,
                                           keyboardToolbar.frame.size.height);
        
        [[UIApplication sharedApplication].keyWindow addSubview:keyboardToolbar];
    }
	
	UIViewAnimationCurve animationCurve	= [[[notification userInfo] valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	NSTimeInterval animationDuration = [[[notification userInfo] valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
	[UIView beginAnimations:@"EEShowKeyboardAnimation" context:nil];
	[UIView setAnimationCurve:animationCurve];
	[UIView setAnimationDuration:animationDuration];
	
	keyboardToolbar.alpha = 1.0;
	keyboardToolbar.frame = CGRectMake(0, 224, self.view.bounds.size.width, kKeyboardToolbarHeight);
	
	[UIView commitAnimations];
}

#pragma mark - Private Methods

-(NSString *)bhFormatNumberString:(NSString *)numberString withFormat:(NSString *)format
{
	NSString* formatString = [NSString stringWithString:format];
	NSUInteger formatStringLength = formatString.length;
	
	NSMutableString* returnString = [[NSMutableString alloc] initWithCapacity:formatStringLength];
	
	NSUInteger i = 0;        // represents the formatString character position/counter through the loop
	NSUInteger numberStringPosition = 0;
	
	unichar uniChar;
	
	for ( i = 0; i < formatStringLength; ++i )
	{
		uniChar = [formatString characterAtIndex:i];

		if ( '#' == uniChar )
		{
			uniChar = [numberString characterAtIndex:numberStringPosition++];
		}
        
		[returnString appendFormat:@"%C",uniChar];
	}
    
	return returnString;
}

@end
