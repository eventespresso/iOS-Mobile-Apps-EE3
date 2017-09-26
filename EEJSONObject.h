//
//  EEJSONObject.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/14/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EEJSONObject : NSObject

@property (strong, nonatomic, readonly) NSMutableDictionary* jsonDict;

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
