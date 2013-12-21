//
//  KeyGestureRecognizer.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyGestureRecognizer.h"
#import "NSObject+ObjectID.h"
#import "KeyTouch.h"

@implementation KeyGestureRecognizer

-(id)init {
  self = [super init];
  if (self) {
    self.numberOfTapsRequired = 1;
  }
  return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"gesture recognizer %@ sent touches began", self.objectID);
  NSSet *keyTouches = [self customiseTouchesIntoKeyTouches:touches];
  [self.delegate keyTouchesBegan:keyTouches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"gesture recognizer %@ sent touches moved", self.objectID);
  NSSet *keyTouches = [self customiseTouchesIntoKeyTouches:touches];
  [self.delegate keyTouchesMoved:keyTouches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"gesture recognizer %@ sent touches ended", self.objectID);
  NSSet *keyTouches = [self customiseTouchesIntoKeyTouches:touches];
  [self.delegate keyTouchesEnded:keyTouches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"gesture recognizer %@ sent touches cancelled", self.objectID);
  NSSet *keyTouches = [self customiseTouchesIntoKeyTouches:touches];
  [self.delegate keyTouchesCancelled:keyTouches withEvent:event];
}

-(NSSet *)customiseTouchesIntoKeyTouches:(NSSet *)touches; {
  NSMutableSet *keyTouches = [[NSMutableSet alloc] initWithCapacity:1];
  for (UITouch *touch in touches) {
    KeyTouch *keyTouch = (KeyTouch *)touch;
    [keyTouches addObject:(KeyTouch *)keyTouch];
  }
  return [NSSet setWithSet:keyTouches];
}

@end