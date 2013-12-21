//
//  KeyGestureRecognizer.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyGestureRecognizer.h"
#import "NSObject+ObjectID.h"

@implementation KeyGestureRecognizer

  // gesture recogniser doesn't need to be added to view!
  // just have view declare its delegate!
-(id)init {
  self = [super init];
  if (self) {
    self.numberOfTapsRequired = 1;
  }
  return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate touchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate touchesCancelled:touches withEvent:event];
}

@end