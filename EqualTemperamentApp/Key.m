//
//  Key.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/12/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "Key.h"

@implementation Key

-(id)initWithFrame:(CGRect)frame
  givenColourStyle:(NSString *)colourStyle
   andKeyCharacter:(NSString *)keyCharacter
      andKeyHeight:(CGFloat)keyHeight
 andTonesPerOctave:(NSUInteger)tonesPerOctave
   andPerfectFifth:(NSUInteger)perfectFifth
    andScaleDegree:(NSNumber *)scaleDegreeObject {
  self = [super initWithFrame:frame];
  if (self) {
    NSUInteger scaleDegree = [scaleDegreeObject unsignedIntegerValue];
    [self findColoursWithColourStyle:colourStyle
                     andKeyCharacter:keyCharacter
                        andKeyHeight:keyHeight
                 givenTonesPerOctave:tonesPerOctave
                     andPerfectFifth:perfectFifth
                      andScaleDegree:scaleDegree];
    if ([keyCharacter isEqualToString:@"numbered"]) {
      [self addLabelGivenColourStyle:colourStyle andBlackKeyHeight:(CGFloat)keyHeight forScaleDegree:scaleDegree];
    }
  }
  return self;
}

-(void)addLabelGivenColourStyle:(NSString *)colourStyle
              andBlackKeyHeight:(CGFloat)blackKeyHeight
                 forScaleDegree:(NSUInteger)scaleDegree {
  CGFloat keyWidth = self.frame.size.width; // also size of each square edge of label
  CGFloat whiteKeyHeight = self.frame.size.height;
  CGFloat labelHeight = 40.f;
  CGRect labelFrame = CGRectMake(0.f, whiteKeyHeight - labelHeight, keyWidth, labelHeight);
  self.characterLabel = [[UILabel alloc] initWithFrame:labelFrame];
  self.characterLabel.textAlignment = NSTextAlignmentCenter;
  
  if ([colourStyle isEqualToString:@"noColour"]) {
    if (blackKeyHeight == 1.f) {
        // this is a white key
      self.characterLabel.textColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1.f];
    } else {
        // this is a black key
      self.characterLabel.textColor = [UIColor whiteColor];
    }
  } else {
      // this is any coloured key
    self.characterLabel.textColor = [UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.f];
  }
  
  self.characterLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)scaleDegree];

  [self addSubview:self.characterLabel];
}

-(void)findColoursWithColourStyle:(NSString *)colourStyle
                  andKeyCharacter:(NSString *)keyCharacter
                     andKeyHeight:(CGFloat)keyHeight
              givenTonesPerOctave:(NSUInteger)tonesPerOctave
                  andPerfectFifth:(NSUInteger)perfectFifth
                   andScaleDegree:(NSUInteger)scaleDegree {

  float colourWheelPosition = 0;
  
    // border width depends on whether the key touches its neighbours
  if (keyHeight == 1.f) {
    self.layer.borderWidth = 0.5f;
  } else {
    self.layer.borderWidth = 1.f;
  }
  self.layer.borderColor = self.borderColour.CGColor;

    // find colour
  if ([colourStyle isEqualToString:@"noColour"]) {
      // adjust values for noColour keyboard
    if (keyHeight == 1.f) {
        // white key
      self.normalColour = [UIColor colorWithRed:19/20.f green:19/20.f blue:18/20.f alpha:1.f];
      self.highlightedColour = [UIColor colorWithRed:1.f green:1.f blue:19/20.f alpha:1.f];
    } else {
        // black key
      CGFloat minBright = 0.4f;
      CGFloat maxBright = 0.9f;
      CGFloat addition = (maxBright - minBright) * keyHeight;
      
      self.normalColour = [UIColor colorWithRed:minBright + addition
                                          green:minBright + addition
                                           blue:(minBright + addition) * 0.9f
                                          alpha:1.f];
      [self findColouredKeyHighlightedColour];
    }
  } else {
    if ([colourStyle isEqualToString:@"fifthWheel"]) {
      NSUInteger fifthWheelPosition = 0;
      for (int i = 0; i < tonesPerOctave; i++) {
        if ((i * perfectFifth) % tonesPerOctave == scaleDegree) {
          fifthWheelPosition = i;
            //      NSLog(@"Fifth wheel position is %i for scale degree %i", fifthWheelPosition, scaleDegree);
          break;
        }
      }
        // make colour wheel counter-clockwise
      colourWheelPosition = 1.f - ((float)fifthWheelPosition / tonesPerOctave);
    } else if ([colourStyle isEqualToString:@"stepwise"]) {
      colourWheelPosition = 1.f - ((float)scaleDegree / tonesPerOctave);
    }
    
    [self findNormalColourGivenColourWheelPosition:colourWheelPosition];
    [self findColouredKeyHighlightedColour];
  }
}

-(void)findNormalColourGivenColourWheelPosition:(float)colourWheelPosition {
  CGFloat redValue, greenValue, blueValue;
  CGFloat minBright, maxBright;
  
  minBright = 0.65f;
  maxBright = 1.f;
  
    // wheel positions may need adjusting, because colour wheel isn't perfectly symmetrical
    // red and green are perceived as being more opposite than red and cyan
  float p1 = 1/6.f;
  float p2 = 2/6.f;
  float p3 = 3/6.f;
  float p4 = 4/6.f;
  float p5 = 5/6.f;
  
  if (colourWheelPosition <= p1) {
    redValue = maxBright;
    greenValue = minBright + (1/p1) * (maxBright - minBright) * colourWheelPosition;
    blueValue = minBright;
  } else if (colourWheelPosition > p1 && colourWheelPosition <= p2) {
    redValue = minBright + (1/(p2-p1)) * (maxBright - minBright) * (p2 - colourWheelPosition);
    greenValue = maxBright;
    blueValue = minBright;
  } else if (colourWheelPosition > p2 && colourWheelPosition <= p3) {
    redValue = minBright;
    greenValue = maxBright;
    blueValue = minBright + (1/(p3-p2)) * (maxBright - minBright) * (colourWheelPosition - p2);
  } else if (colourWheelPosition > p3 && colourWheelPosition <= p4) {
    redValue = minBright;
    greenValue = minBright + (1/(p4-p3)) * (maxBright - minBright) * (p4 - colourWheelPosition);
    blueValue = maxBright;
  } else if (colourWheelPosition > p4 && colourWheelPosition <= p5) {
    redValue = minBright + (1/(p5-p4)) * (maxBright - minBright) * (colourWheelPosition - p4);
    greenValue = minBright;
    blueValue = maxBright;
  } else {
    redValue = maxBright;
    greenValue = minBright;
    blueValue = minBright + (1/(1.f-p5)) * (maxBright - minBright) * (1.f - colourWheelPosition);
  }
  self.normalColour = [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1.f];
}

-(void)findColouredKeyHighlightedColour {
  CGFloat normalRed, normalGreen, normalBlue, highlightedRed, highlightedGreen, highlightedBlue, alpha;
  [self.normalColour getRed:&normalRed green:&normalGreen blue:&normalBlue alpha:&alpha];
  
  highlightedRed = normalRed + ((1.f - normalRed) / 3.f);
  highlightedGreen = normalGreen + ((1.f - normalGreen) / 3.f);
  highlightedBlue = normalBlue + ((1.f - normalBlue) / 3.f);
  
  self.highlightedColour = [UIColor colorWithRed:highlightedRed green:highlightedGreen blue:highlightedBlue alpha:alpha];
}

@end