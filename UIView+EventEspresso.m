//
//  UIView+EventEspresso.m
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/3/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "UIView+EventEspresso.h"


static NSTimeInterval const kMoveDuration = 0.4;

@implementation UIView (EventEspresso)

- (UIView *)findFirstResponder
{
	if ( self.isFirstResponder )
    {
		return self;
	}
	
	for ( UIView* subview in self.subviews )
    {
		UIView* firstResponder = [subview findFirstResponder];
        
		if ( firstResponder != nil )
        {
			return firstResponder;
		}
	}
	
	return nil;
}

-(void)moveUp:(NSInteger)distance withAnimation:(BOOL)animated
{
	if ( animated )
    {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:kMoveDuration];		
	}
    
	self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y - distance,
                            self.frame.size.width,
                            self.frame.size.height);
    
	if ( animated )
    {
		[UIView commitAnimations];
	}
}

- (void)moveToOriginWithAnimation:(BOOL)animated
{
	if ( animated )
    {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:kMoveDuration];		
	}
    
	self.frame = CGRectMake(self.frame.origin.x,
                            0.0f,
                            self.frame.size.width,
                            self.frame.size.height);
    
	if ( animated )
    {
		[UIView commitAnimations];
	}
}

@end
