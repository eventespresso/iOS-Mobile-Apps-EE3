//
//  EELoginRequest.h
//  EventEspressoHD
//
//  This class/module hold common implementation details for all REST API request
//  types.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEJSONRequest.h"

@interface EELoginRequest : EEJSONRequest

@property (strong, nonatomic, readonly) NSString* sessionKey;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                   URL:(NSURL *)URL
            completion:(EERestAPICompletion)completion;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                   URL:(NSURL *)URL
      startImmediately:(BOOL)startImmediately
            completion:(EERestAPICompletion)completion;

+ (id)requestWithUsername:(NSString *)username
                 password:(NSString *)password
                      URL:(NSURL *)URL
               completion:(EERestAPICompletion)completion;

- (void)start;

@end
