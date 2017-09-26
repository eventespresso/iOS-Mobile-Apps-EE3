//
//  EEAppDelegate.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAppDelegate.h"
#import "NSUserDefaults+EventEspresso.h"

@implementation EEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Reset the fetch counter so that app peforms the first-fetch processing.
    [NSUserDefaults standardUserDefaults].fetchRequestCount = 0;
    [NSUserDefaults standardUserDefaults].fetchRequestSucceeded = NO;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        // Setup the master/detail views.
        UISplitViewController* splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController* navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
    return YES;
}
							
@end
