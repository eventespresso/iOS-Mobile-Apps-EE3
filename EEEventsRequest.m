//
//  EEEventsRequest.m
//  EventEspressoHD
//
//  Espresso-API request for event information.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EEEvent.h"
#import "EEEventsRequest.h"

@interface EEEventsRequest ()
@property (strong, nonatomic) NSString* params;
@end

@implementation EEEventsRequest

#pragma mark - Properties

@synthesize returnedEvents = _returnedEvents;

#pragma mark - Initialization

- (id)initWithQueryParams:(NSString *)params
               sessionKey:(NSString *)sessionKey
                      URL:(NSURL *)URL
               completion:(EERestAPICompletion)completion
{
	return [self initWithQueryParams:params
                          sessionKey:sessionKey
                                 URL:URL
                    startImmediately:NO
                          completion:completion];
}

- (id)initWithQueryParams:(NSString *)params
               sessionKey:(NSString *)sessionKey
                      URL:(NSURL *)URL
         startImmediately:(BOOL)startImmediately
               completion:(EERestAPICompletion)completion
{
	self = [super initWithEndpoint:@"espresso-api/v1/events"
                        sessionKey:sessionKey
                               URL:URL
                        completion:completion];
	
	if ( self )
	{
        self.params = params;

		if ( startImmediately )
		{
			[self start];
		}
	}
	
	return self;
}

+ (id)requestWithQueryParams:(NSString *)params
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
                  completion:(EERestAPICompletion)completion
{
	return [[[self class] alloc] initWithQueryParams:params
                                          sessionKey:sessionKey
                                                 URL:URL
                                    startImmediately:YES
                                          completion:completion];
}

- (void)start
{
    self.started = YES;

    // Build a standard HTTP GET request for the given endpoint and submit it to
    // the server.  If parameters are included, append them to the end of the
    // URL as query parameters.
    NSString* endpointURL = [self.URL.description stringByAppendingPathComponent:self.endpoint];
    endpointURL = [endpointURL stringByAppendingPathComponent:self.sessionKey];
    
    if ( self.params )
    {
        endpointURL = [endpointURL stringByAppendingString:self.params];
    }
    
    NSURL* requestURL = [NSURL URLWithString:endpointURL];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:self.timeout];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    // Make sure the response we received meets basic validation checks.
    NSError* error = [self validateResponse];
    
    // After call to deserialize JSON data into object, error will either be nil
    // or a valid error pointer.    
    if ( nil == error )
    {
        self.results = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
        
        if ( self.results )
        {
            // If we have results we no longer need the data.
            self.responseData = nil;
            
            error = [self processResultsForError:self.results];
        }
    }
    
    self.completion(error);
	self.started = NO;
}

#pragma mark - Private Methods

- (NSError *)processResultsForError:(NSDictionary *)resultsDict
{
    NSString* status = resultsDict[EEJSONStatusKey];
    int statusCode = [resultsDict[EEJSONStatusCodeKey] intValue];
    
    if ( statusCode != 200 )
    {
        MCLog(@"%s: Results Dictionary: %@", __PRETTY_FUNCTION__, resultsDict);
        
        return [NSError errorWithDomain:EspressoAPIErrorDomain
                                   code:statusCode
                               userInfo:@{NSLocalizedDescriptionKey : status}];
    }
    
    // Get the resulting array of JSON event objects.  If the array is valid
    // wrap each object in a class to make it easier to use within out system.
    
    NSArray* jsonEventObjects = self.results[EEJSONBodyKey][EEJSONEventsKey];
    
    if ( nil == jsonEventObjects )
    {
        MCLog(@"%s: Results Dictionary: %@", __PRETTY_FUNCTION__, resultsDict);

        return [NSError errorWithDomain:EEErrorDomain
                                   code:EEErrorMalformedJSONResponse
                               userInfo:@{NSLocalizedDescriptionKey :
                @"API response is malformed or invalid."}];
    }
    
    NSMutableArray* events = [NSMutableArray new];
    
    for ( NSMutableDictionary* eventDict in jsonEventObjects )
    {
        EEEvent* event = [EEEvent eventWithJSONDictionary:eventDict];
        [events addObject:event];
    }
    
    _returnedEvents = events;
    
    return nil;
}

@end
