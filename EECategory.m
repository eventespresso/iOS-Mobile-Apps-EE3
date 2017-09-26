//
//  EECategory.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EECategory.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kCategoryDescriptionKey = @"description";
NSString* const kCategoryIdentifierKey  = @"identifier";
NSString* const kCategoryIDKey          = @"id";
NSString* const kCategoryNameKey        = @"name";
NSString* const kCategoryUserKey        = @"user";

@implementation EECategory

#pragma mark - Initialization

+ (id)categoryWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kCategoryDescriptionKey, kCategoryNameKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return self.name;
}

#pragma mark - Properties

- (NSString *)description
{
    return self.jsonDict[kCategoryDescriptionKey];
}

- (NSNumber *)ID
{
    return self.jsonDict[kCategoryIDKey];
}

- (NSString *)identifier
{
    return self.jsonDict[kCategoryIdentifierKey];
}

- (NSString *)name
{
    return self.jsonDict[kCategoryNameKey];
}

- (NSInteger)user
{
    return [self.jsonDict[kCategoryUserKey] integerValue];
}

@end
