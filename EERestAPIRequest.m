//
//  EERestAPIRequest.m
//  EventEspressoHD
//
//  This class/module hold common implementation details for all REST API request
//  types.  It is intended to be sub-classed in order to implement specific
//  request types.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEError.h"
#import "EERestAPIRequest.h"
#import "NSUserDefaults+EventEspresso.h"

NSTimeInterval const kMaxRestAPIResponseInterval = 30.0;

@implementation EERestAPIRequest

#pragma mark - Initialization

- (id)initWithURL:(NSURL *)URL
         completion:(EERestAPICompletion)completion
{
	return [self initWithURL:URL
            startImmediately:NO
                  completion:completion];
}

- (id)initWithURL:(NSURL *)URL
 startImmediately:(BOOL)startImmediately
       completion:(EERestAPICompletion)completion
{
	self = [super init];
	
	if ( self )
	{
		self.completion = completion;
        self.timeout    = [NSUserDefaults standardUserDefaults].restAPIRequestTimeout;
        self.URL        = URL;

        if ( 0.0 == self.timeout )
        {
            self.timeout = kMaxRestAPIResponseInterval;
        }
        
		if ( startImmediately )
		{
			[self start];
		}
	}
	
	return self;
}

+ (id)requestWithURL:(NSURL *)URL completion:(EERestAPICompletion)completion
{
	return [[[self class] alloc] initWithURL:URL
                            startImmediately:YES
                                  completion:completion];
}

#pragma mark - API

- (void)cancel
{
	if ( self.started )
	{
		[self.connection cancel];
	}
}

- (void)start
{
    NSAssert(NO == self.started,
             @"PROGAMMING ERROR: EERestAPIRequest restarted before completion");
    
    // This method may or may not be overridden, based on your needs.  If you
    // have already set the URL property and it is completed then simply invoke
    // this method without overriding it.  If you need to include a payload or
    // add arguments to the give URL, then override this method in order to
    // do so.  In that case, this method should not be invoked.
    if ( NO == self.started )
    {
        self.started = YES;
        NSMutableURLRequest* request = [NSMutableURLRequest new];
        request.URL = self.URL;
        request.timeoutInterval = self.timeout;
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    }
}

#pragma mark - NSURLConnection Delegate Methods

- (BOOL)connection:(NSURLConnection*)connection
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace
{
    MCLogFuncEntry();
    MCLog(@"    authenticationMethod: %@", protectionSpace.authenticationMethod);
    MCLog(@"      distinguishedNames: %@", protectionSpace.distinguishedNames);
    MCLog(@"                    host: %@", protectionSpace.host);
    MCLog(@"                    port: %d", protectionSpace.port);
    MCLog(@"                protocol: %@", protectionSpace.protocol);
    MCLog(@"               proxyType: %@", protectionSpace.proxyType);
    MCLog(@"                   realm: %@", protectionSpace.realm);
    
    // Here we determine what kind of authentication methods we support.  This
    // code can be overriden by the sub-class
	if ( NSURLAuthenticationMethodServerTrust == protectionSpace.authenticationMethod )
	{
		return YES;
	}
    else if ( NSURLAuthenticationMethodHTTPBasic == protectionSpace.authenticationMethod )
    {
        return YES;
    }
	
	return NO;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    // This method should be overridden by subclass in order to properly handle
    // a failed request.  Be sure to set change the state of 'started' to NO
    // when overriding this method, or to invoke this method as part of the over-
    // riding method call.
    MCLogFuncEntry();
    MCLog(@"    Error: %@", error);
	// Our web-service request failed.  Simply pass the connection error on to
	// our caller for processing.
	self.completion(error);
    self.started = NO;
}

- (void)connection:(NSURLConnection*)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
    // This method is deprecated with the addition of the more preemptive
    // -[willSendRequestForAuthenticationChallenge:] method call.
    MCLogFuncEntry();
    MCLog(@"                   error: %@", challenge.error);
    MCLog(@"          falureResponse: %@", challenge.failureResponse);
    MCLog(@"    previousFailureCount: %d", challenge.previousFailureCount);
    
    if ( challenge.previousFailureCount )
    {
#if 0
        // If something is wrong with the credentials, abort.
        [challenge.sender cancelAuthenticationChallenge:challenge];
#else
        // If something is wrong with the credentials, try again without it
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
#endif
    }
    else
    {
        NSURLCredential* credential =
        [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    // Incoming data is stored in memory until we have all of it.  If you are
    // expecting large amounts of data, don't use this object, instead use a
    // file-download URL-Connection.
    MCLogFuncEntry();
    MCLog(@"    length: %u", data.length);
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    MCLogFuncEntry();
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSString* stringForStatusCode = [NSString stringWithFormat:@"%d-%@",
                                     httpResponse.statusCode,
                                     [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode]];
    
    MCLogDebug(@"    expectedContentLength: %lld", response.expectedContentLength);
    MCLogDebug(@"                 MIMEType: %@", response.MIMEType);
    MCLogDebug(@"        suggestedFilename: %@", response.suggestedFilename);
    MCLogDebug(@"         textEncodingName: %@", response.textEncodingName);
    MCLogDebug(@"                      URL: %@", response.URL);
    MCLogDebug(@"               statusCode: %@", stringForStatusCode);
    MCLogDebug(@"          allHeaderFields: %@", httpResponse.allHeaderFields);
    
    // We automatically store the HTTP status code, response data and anty cookies
    // we receive.  The response-data storage is allocated here if needed.
    self.statusCode = httpResponse.statusCode;
    self.responseData = [NSMutableData new];
    
    // If the response status code is not 200 OK, we dump the connection without
    // continuing.  In order to override this behavior, override this method.
    if ( httpResponse.statusCode != 200 )
    {
        [self.connection cancel];
        NSDictionary* userInfo = @{ NSLocalizedDescriptionKey : stringForStatusCode };
        NSError* error = [NSError errorWithDomain:EEErrorDomain
                                             code:EEErrorBadHTTPStatusCode
                                         userInfo:userInfo];
        self.completion(error);
    }
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection
                 willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    MCLogFuncEntry();
    MCLog(@"    CachedResponse: %@", cachedResponse);
    return nil; // don't bother caching protocol specific responses
}

- (NSURLRequest*)connection:(NSURLConnection*)connection
            willSendRequest:(NSURLRequest*)request
           redirectResponse:(NSURLResponse*)redirectResponse
{
    MCLogFuncEntry();
    MCLog(@"             Request: %@", request);
    MCLog(@"    RedirectResponse: %@", redirectResponse);
    return request;
}

- (void)connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    // By supporting this new iOS 5.0 delegate method, we no longer receive the
    // callbacks for -[connection:didReceiveAuthenticationChallenge:] or
    // -[connection:didCancelAuthenticationChallenge:].
    
    MCLogFuncEntry();
    MCLog(@"                   error: %@", challenge.error);
    MCLog(@"          falureResponse: %@", challenge.failureResponse);
    MCLog(@"    previousFailureCount: %d", challenge.previousFailureCount);
    
    NSURLProtectionSpace* protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:self.URL.host port:self.URL.port.integerValue protocol:self.URL.scheme realm:nil authenticationMethod:nil];
    NSURLCredential* credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:protectionSpace];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    // This method should be overridden by subclass in order to properly handle
    // a successful request.  Be sure to set change the state of 'started' to NO
    // when overriding this method, or to invoke this method as part of the over-
    // riding method call.
	self.started = NO;
}

@end