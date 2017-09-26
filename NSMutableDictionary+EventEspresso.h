//
//  NSMutableDictionary+EventEspresso.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 1/19/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (EventEspresso)

- (void)replaceNullValuesForKeys:(NSArray *)keys withValue:(id)newValue;
- (void)stripNullValues;

@end
