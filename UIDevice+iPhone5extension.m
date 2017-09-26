//
//  UIDevice+iPhone5extension.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 5/10/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import "UIDevice+iPhone5extension.h"

@implementation UIDevice (iPhone5extension)

- (BOOL)iPhone5
{
    if( [self userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
    {
        if ( [UIScreen mainScreen].bounds.size.height == 568.0f )
        {
            return YES;
        }
    }
    
    return NO;
}

@end
