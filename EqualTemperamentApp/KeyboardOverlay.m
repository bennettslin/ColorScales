//
//  KeyboardOverlay.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/18/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyboardOverlay.h"

@implementation KeyboardOverlay

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
  }
  return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyboardOverlayTouchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyboardOverlayTouchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyboardOverlayTouchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyboardOverlayTouchesEnded:touches withEvent:event];
}

@end
