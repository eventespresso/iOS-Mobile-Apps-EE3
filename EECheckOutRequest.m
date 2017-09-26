//
//  EECheckOutRequest.m
//  EventEspressoHD
//
//  Espresso-API request for checking-out an attendee via a registration ID.
//
//  Created by Michael A. Crawford on 12/20/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EERegistration.h"
#import "EECheckOutRequest.h"

@interface EECheckOutRequest ()
@property (strong, nonatomic) NSNumber* registrationID;
@end

@implementation EECheckOutRequest

#pragma mark - Properties

@synthesize quantity                = _quantity;
@synthesize registrationID          = _registrationID;
@synthesize returnedRegistrations   = _returnedRegistrations;

#pragma mark - Initialization

- (id)initWithRegistrationID:(NSNumber *)registrationID
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
                  completion:(EERestAPICompletion)completion
{
	return [self initWithRegistrationID:registrationID
                               quantity:1
                             sessionKey:sessionKey
                                    URL:URL
                       startImmediately:NO
                             completion:completion];
}

- (id)initWithRegistrationID:(NSNumber *)registrationID
                    quantity:(NSUInteger)quantity
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
            startImmediately:(BOOL)startImmediately
                  completion:(EERestAPICompletion)completion
{
	self = [super initWithEndpoint:[NSString stringWithFormat:@"espresso-api/v1/registrations/%@/checkout", registrationID]
                        sessionKey:sessionKey
                               URL:URL
                        completion:completion];
	
	if ( self )
	{
        self.quantity = quantity;

		if ( startImmediately )
		{
			[self start];
		}
	}
	
	return self;
}

+ (id)requestWithRegistrationID:(NSNumber *)registrationID
                       quantity:(NSUInteger)quantity
                     sessionKey:(NSString *)sessionKey
                            URL:(NSURL *)URL
                     completion:(EERestAPICompletion)completion
{
	return [[[self class] alloc] initWithRegistrationID:registrationID
                                               quantity:quantity
                                             sessionKey:sessionKey
                                                    URL:URL
                                       startImmediately:YES
                                             completion:completion];
}

- (void)start
{
    self.started = YES;

    // Build a standard HTTP GET request for the given endpoint and submit it to
    // the server.  If the ignore_payment flag is set, append it to the end of the
    // URL as a query parameter.
    NSString* endpointURL = [self.URL.description stringByAppendingPathComponent:self.endpoint];
    endpointURL = [endpointURL stringByAppendingPathComponent:self.sessionKey];
    endpointURL = [NSString stringWithFormat:@"%@?quantity=%d", endpointURL, self.quantity];
    
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

- (NSError *)processResultsForError:(NSMutableDictionary *)resultsDict
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
    
    // Get the resulting array of JSON registration objects.  If the array is
    // valid wrap each object in a class to make it easier to use within out
    // system.
    
    NSMutableArray* jsonRegistrationObjects = self.results[EEJSONBodyKey][@"Registrations"];
    
    if ( nil == jsonRegistrationObjects )
    {
        MCLog(@"%s: Results Dictionary: %@", __PRETTY_FUNCTION__, resultsDict);
        
        return [NSError errorWithDomain:EEErrorDomain
                                   code:EEErrorMalformedJSONResponse
                               userInfo:@{NSLocalizedDescriptionKey :
                @"API response is malformed or invalid."}];
    }
    
    _returnedRegistrations = [NSMutableArray arrayWithCapacity:jsonRegistrationObjects.count];
    
    for ( NSMutableDictionary* jsonRegistrationObject in jsonRegistrationObjects )
    {
        EERegistration* returnedRegistration = [EERegistration registrationWithJSONDictionary:jsonRegistrationObject];
        [_returnedRegistrations addObject:returnedRegistration];
    }

    return nil;
}

@end
