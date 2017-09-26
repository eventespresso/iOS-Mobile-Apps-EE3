//
//  EERestAPIRequest.h
//  EventEspressoHD
//
//  This class/module hold common implementation details for all REST API request
//  types.  It is intended to be sub-classed in order to implement specific
//  request types.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

extern NSTimeInterval const kMaxRestAPIResponseInterval;

typedef void (^EERestAPICompletion)(NSError *error);

extern NSTimeInterval const kMaxRestAPIResponseInterval;

@interface EERestAPIRequest : NSObject <NSURLConnectionDelegate>

@property (strong, nonatomic) EERestAPICompletion completion;
@property (strong, nonatomic) NSURLConnection* connection;
@property (strong, nonatomic) NSMutableData* responseData;
@property (assign, nonatomic) BOOL started;
@property (assign, nonatomic) int statusCode;
@property (assign, nonatomic) NSTimeInterval timeout;
@property (strong, nonatomic) NSURL* URL;

- (void)cancel;

- (id)initWithURL:(NSURL *)URL completion:(EERestAPICompletion)completion;

- (id)initWithURL:(NSURL *)URL
 startImmediately:(BOOL)startImmediately
       completion:(EERestAPICompletion)completion;

+ (id)requestWithURL:(NSURL *)URL completion:(EERestAPICompletion)completion;

- (void)start;

@end