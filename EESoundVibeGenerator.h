//
//  EESoundVibeGenerator.h
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

#import <Foundation/Foundation.h>

@interface EESoundVibeGenerator : NSObject

- (id)initWithSoundURL:(NSURL *)soundURL;
- (void)play;

@end
