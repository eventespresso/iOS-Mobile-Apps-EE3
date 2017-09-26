//
//  EEJSONRequest.m
//  EventEspressoHD
//
//  This class/module hold common implementation details for all REST API request
//  types carying a JSON payload for the request and response.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EEJSONRequest.h"

// These are the significant keys we use to decode the JSON objects returned
// from the Espresso-API.
NSString* const EEJSONAttendeesKey      = @"attendees";
NSString* const EEJSONBodyKey           = @"body";
NSString* const EEJSONEventsKey         = @"Events";
NSString* const EEJSONRegistrationsKey  = @"Registrations";
NSString* const EEJSONSessionKeyKey     = @"session_key";
NSString* const EEJSONStatusKey         = @"status";
NSString* const EEJSONStatusCodeKey     = @"status_code";

@interface EEJSONRequest ()
@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) NSString* sessionKey;
@end

@implementation EEJSONRequest

#pragma mark - Initialization

- (id)initWithEndpoint:(NSString *)endpoint
            sessionKey:(NSString *)sessionKey
                   URL:(NSURL *)URL
            completion:(EERestAPICompletion)completion
{
	return [self initWithEndpoint:endpoint
                       sessionKey:(NSString *)sessionKey
                              URL:URL
                 startImmediately:NO
                       completion:completion];
}

- (id)initWithEndpoint:(NSString *)endpoint
            sessionKey:(NSString *)sessionKey
                   URL:(NSURL *)URL
      startImmediately:(BOOL)startImmediately
            completion:(EERestAPICompletion)completion
{
	self = [super initWithURL:URL completion:completion];
	
	if ( self )
	{
        self.endpoint   = endpoint;
        self.sessionKey = sessionKey;

		if ( startImmediately )
		{
			[self start];
		}
	}
	
	return self;
}

+ (id)requestWithEndpoint:(NSString *)endpoint
               sessionKey:(NSString *)sessionKey
                      URL:(NSURL *)URL
               completion:(EERestAPICompletion)completion
{
	return [[[self class] alloc] initWithEndpoint:endpoint
                                       sessionKey:(NSString *)sessionKey
                                              URL:URL
                                 startImmediately:YES
                                       completion:completion];
}

- (void)start
{
    self.started = YES;

    // Build a standard HTTP GET request for the given endpoint and submit it to
    // the server.  Since JSON endpoints in this application domain require an
    // authentication cookie, we are sure to include it as well.
    NSString* endpointURL = [self.URL.description stringByAppendingPathComponent:self.endpoint];
    NSURL* requestURL = [NSURL URLWithString:endpointURL];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:self.timeout];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    // After call to deserialize JSON data into object, error will either be nil
    // or a valid error pointer.
    NSError* error = nil;
    self.results = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                   options:NSJSONReadingMutableContainers
                                                     error:&error];
    
    if ( self.results )
    {
        // If we have results we no longer need the data.
        self.responseData = nil;
        
        error = [self processResultsForError:self.results];
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
    
    return nil;
}

- (NSError *)validateResponse
{
    // For now the only validation rule we have is that the response not be
    // zero length.
    if ( 0 == self.responseData.length )
    {
        return [NSError errorWithDomain:EEErrorDomain
                                   code:EEErrorZeroLengthResponse
                               userInfo:@{NSLocalizedDescriptionKey: @"Server response is zero-length; no data."}];
    }
    
    return nil;
}

@end
