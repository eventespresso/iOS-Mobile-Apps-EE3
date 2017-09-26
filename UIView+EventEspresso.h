//
//  UIView+EventEspresso.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/3/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIView (EventEspresso)

- (UIView *)findFirstResponder;
- (void)moveUp:(NSInteger)distance withAnimation:(BOOL)animated;
- (void)moveToOriginWithAnimation:(BOOL)animated;

@end
