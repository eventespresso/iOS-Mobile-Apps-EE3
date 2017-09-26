//
//  EECategory.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kCategoryDescriptionKey;
extern NSString* const kCategoryIdentifierKey;
extern NSString* const kCategoryIDKey;
extern NSString* const kCategoryNameKey;
extern NSString* const kCategoryUserKey;

@interface EECategory : EEJSONObject

@property (strong, nonatomic, readonly) NSString* description;
@property (assign, nonatomic, readonly) NSNumber* ID;
@property (strong, nonatomic, readonly) NSString* identifier;
@property (strong, nonatomic, readonly) NSString* name;
@property (assign, nonatomic, readonly) NSInteger user;

+ (id)categoryWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
