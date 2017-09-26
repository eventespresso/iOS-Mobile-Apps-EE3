//
//  EEJSONObject.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/14/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEJSONObject.h"


@implementation EEJSONObject

@synthesize jsonDict = _jsonDict;

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super init];
    
    if ( self )
    {
        _jsonDict = jsonDict;
    }
    
    return self;
}

@end
