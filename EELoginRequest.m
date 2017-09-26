//
//  EELoginRequest.m
//  EventEspressoHD
//
//  This class/module hold common implementation details for all REST API request
//  types.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EELoginRequest.h"


@interface EELoginRequest ()
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) NSString* sessionKey;
@property (strong, nonatomic) NSString* username;
@end

@implementation EELoginRequest

#pragma mark - Properties

@synthesize password    = _password;
@synthesize sessionKey  = _sessionKey;
@synthesize username    = _username;

#pragma mark - Initialization

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                   URL:(NSURL *)URL
            completion:(EERestAPICompletion)completion
{
	return [self initWithUsername:username
                         password:password
                              URL:URL
                 startImmediately:NO
                       completion:completion];
}

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                   URL:(NSURL *)URL
      startImmediately:(BOOL)startImmediately
            completion:(EERestAPICompletion)completion
{
	self = [super initWithURL:URL completion:completion];
	
	if ( self )
	{
        self.password = password;
        self.username = username;

		if ( startImmediately )
		{
			[self start];
		}
	}
	
	return self;
}

+ (id)requestWithUsername:(NSString *)username
                 password:(NSString *)password
                      URL:(NSURL *)URL
               completion:(EERestAPICompletion)completion
{
	return [[[self class] alloc] initWithUsername:username
                                         password:password
                                              URL:URL
                                 startImmediately:YES
                                       completion:completion];
}

- (void)start
{
    self.started = YES;

#ifdef USE_POST
    // build an HTTP POST request for logging into the Wordpress endpoint
    NSDictionary* dict = @{ @"username" : self.username, @"password" : self.password };
    NSData* postData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONReadingMutableContainers error:nil];
    NSString* postLength = [NSString stringWithFormat:@"%d", postData.length];
    NSMutableURLRequest* request = [NSMutableURLRequest new];
    request.HTTPMethod = @"POST";
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/jsonrequest" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    // submit the request to the server
    NSString* loginURL = [self.URL.description stringByAppendingPathComponent:@"espresso-api/v1/authenticate"];
    request.URL = [NSURL URLWithString:loginURL];
#else
    // build an HTTP GET request for logging into the Wordpress endpoint
    NSString* endpointURL = [self.URL.description stringByAppendingPathComponent:@"espresso-api/v1/authenticate"];
    endpointURL = [endpointURL stringByAppendingFormat:@"?username=%@&password=%@",
                   self.username, self.password];
    endpointURL = [endpointURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* requestURL = [NSURL URLWithString:endpointURL];
    NSURLRequest* request = [NSURLRequest requestWithURL:requestURL
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:self.timeout];
#endif
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
    
    self.sessionKey = self.results[EEJSONBodyKey][EEJSONSessionKeyKey];
    
    if ( nil == self.sessionKey )
    {
        MCLog(@"%s: Results Dictionary: %@", __PRETTY_FUNCTION__, resultsDict);

        return [NSError errorWithDomain:EEErrorDomain
                                   code:EEErrorInvalidSessionKey
                               userInfo:@{NSLocalizedDescriptionKey :
                @"A valid session key was not returned from the server. Access denied."}];
    }
    
    return nil;
}

@end
