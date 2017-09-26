//
//  UIImage+iPhone5extension.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 5/10/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import "UIImage+iPhone5extension.h"

@implementation UIImage (iPhone5extension)

+ (UIImage *)imageNamedForDevice:(NSString*)name
{
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        if ( ([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale) >= 1136 )
        {
            return [UIImage imageNamed:[NSString stringWithFormat:@"%@-568h", name]];
        }
    }
    
    return [UIImage imageNamed:name];
}

@end