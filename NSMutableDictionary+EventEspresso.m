//
//  NSMutableDictionary+EventEspresso.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 1/19/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import "NSMutableDictionary+EventEspresso.h"

@implementation NSMutableDictionary (EventEspresso)

- (void)replaceNullValuesForKeys:(NSArray *)keys withValue:(id)newValue
{
    for ( NSString* key in [self allKeys] )
    {
        id value = [self objectForKey:key];
        
        if ( [NSNull null] == value )
        {
            MCLogDebug(@"WARNING: Found NULL value for key %@; replacing with %@.",
                  key, newValue);
            [self setObject:newValue forKey:key];
        }
    }
}

- (void)stripNullValues
{
    for ( NSString* key in [self allKeys])
    {
        // remove all NSNull values
        id value = [self objectForKey:key];
        
        if ( [NSNull null] == value )
        {
            MCLogDebug(@"WARNING: Striping NULL value for key %@.", key);
            [self removeObjectForKey:key];
        }
        else if ( [value isKindOfClass:[NSArray class]] ||
                 [value isKindOfClass:[NSDictionary class]] )
        {
            // for non-mutable container values, replace with mutable version and strip
            if ( NO == [value respondsToSelector:@selector(setObject:forKey:)] &&
                NO == [value respondsToSelector:@selector(addObject:)] )
            {
                MCLogDebug(@"WARNING: Replacing immutable container for key %@.", key);
                value = [value mutableCopy];
                [self setObject:value forKey:key];
            }
            
            [value stripNullValues];
        }
    }
}

@end
