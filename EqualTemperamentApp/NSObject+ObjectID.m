//
//  NSObject+ObjectID.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "NSObject+ObjectID.h"

@implementation NSObject (ObjectID)

-(NSString *)objectID {
  
  NSUInteger numberOfSpaces = 0;
  NSUInteger iterator = 0;
  NSString *descriptionString = self.description;
  NSMutableString *objectIDString = [NSMutableString string];
  
  while (numberOfSpaces <= 1) {
    char character = [descriptionString characterAtIndex:iterator];
    if ([[NSString stringWithFormat:@"%c", character] isEqualToString:@" "]) {
      numberOfSpaces++;
    }
    if (numberOfSpaces < 2) {
      [objectIDString appendFormat:@"%c", character];
    }
    iterator++;
  }
  return objectIDString;
}

@end
