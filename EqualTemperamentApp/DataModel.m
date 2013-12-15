//
//  DataModel.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/11/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "DataModel.h"

@implementation DataModel

#pragma mark - archiver methods

-(void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.tonesPerOctave];
  [aCoder encodeObject:self.tonesPerOctave forKey:@"tonesPerOctave"];
  [aCoder encodeObject:self.instrument forKey:@"instrument"];
  [aCoder encodeObject:self.keyCharacter forKey:@"keyCharacter"];
  [aCoder encodeObject:self.keyboardStyle forKey:@"keyboardStyle"];
  [aCoder encodeObject:self.gridInterval forKey:@"gridInterval"];
  [aCoder encodeObject:self.colourStyle forKey:@"colourStyle"];
  [aCoder encodeObject:self.userButtonsPosition forKey:@"userButtonsPosition"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
  if ((self = [super init])) {
    self.tonesPerOctave = [aDecoder decodeObjectForKey:@"tonesPerOctave"];
    self.instrument = [aDecoder decodeObjectForKey:@"instrument"];
    self.keyCharacter = [aDecoder decodeObjectForKey:@"keyCharacter"];
    self.keyboardStyle = [aDecoder decodeObjectForKey:@"keyboardStyle"];
    self.gridInterval = [aDecoder decodeObjectForKey:@"gridInterval"];
    self.colourStyle = [aDecoder decodeObjectForKey:@"colourStyle"];
    self.userButtonsPosition = [aDecoder decodeObjectForKey:@"userButtonsPosition"];
  }
  return self;
}

@end
