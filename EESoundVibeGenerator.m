//
//  EESoundVibeGenerator.m
//  EventEspresso
//
//  This class is intented to play a sound and vibrate the device simultaneously
//  and on command.  The sound and vibration output is periodic.  The duration
//  for the vibration function is fixed.  The duration for the sound playback is
//  dependent on the duration of the sound resource with which the class is
//  initialized.
//
//  Created by Michael A. Crawford on 9/7/12.
//  Copyright (c) 2012 EventEspresso. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "EESoundVibeGenerator.h"

@interface EESoundVibeGenerator ()
{
    SystemSoundID systemSoundID;
}
@end

@implementation EESoundVibeGenerator

#pragma mark - Initialization

- (id)initWithSoundURL:(NSURL *)soundURL
{
    self = [super init];
    
    if ( self )
    {
        if ( soundURL )
        {
            // registers this class as the delegate of the audio session
            [[AVAudioSession sharedInstance] setDelegate:self];
            
            // The SoloAmbient sound category allows will lower and pause the iPod output
            // while our app sound plays. This category also indicates that application
            // audio should stop playing if the Ring/Silent switch is set to "silent" or
            // the screen locks.
            NSError* audioError;
            BOOL audioAPISucceeded = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:&audioError];
            
            if ( NO == audioAPISucceeded )
            {
                NSLog(@"[APAudioSession setupApplicationAudio] failed: %@", audioError);
                return self;
            }
            
            // activates the audio session
            audioAPISucceeded = [[AVAudioSession sharedInstance] setActive:YES error:&audioError];
            
            if ( NO == audioAPISucceeded )
            {
                NSLog(@"[AVAudioSession setActive] failed: %@", audioError);
                return self;
            }
            
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &systemSoundID);
        }
    }
    
    return self;
}

#pragma mark - Memory Management

- (void)dealloc
{
    if ( systemSoundID != 0 )
    {
        AudioServicesDisposeSystemSoundID(systemSoundID);
    }

    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
}

#pragma mark - Public Methods (API)

- (void)play
{
    if ( systemSoundID != 0 )
    {
        // If the device is configured to allow vibration, this will both play
        // a sound and vibrate.
        AudioServicesPlayAlertSound(systemSoundID);
    }
    else
    {
        // If the sound ID is not valid, we'd still like to vibrate the device.
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    }
}

@end
