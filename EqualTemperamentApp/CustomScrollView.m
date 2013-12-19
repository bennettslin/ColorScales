//
//  CustomScrollView.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/17/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "CustomScrollView.h"
#import "KeyboardOverlay.h"
#import "Key.h"

@implementation CustomScrollView

-(id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {

  }
  return self;
}

  // This was the magical method that fixed everything! Yay!
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if ([touch.view isKindOfClass:[KeyboardOverlay class]] || [touch.view isKindOfClass:[Key class]]) {
    return NO; // Darn tootin'!
  }
  return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate customScrollViewTouchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate customScrollViewTouchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate customScrollViewTouchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.customDelegate customScrollViewTouchesCancelled:touches withEvent:event];
}

@end
