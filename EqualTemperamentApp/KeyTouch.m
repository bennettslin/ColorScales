//
//  KeyTouch.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyTouch.h"
#import "Key.h"

@implementation KeyTouch

-(id)init {
  self = [super init];
  if (self) {
    Key *key = [[Key alloc] init];
    self.myKey = key;
  }
  return self;
}

-(void)setKeyProperty:(Key *)key {
  _myKey = key;
}

@end
