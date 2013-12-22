//
//  Key.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/12/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "Key.h"
#import "UIColor+ColourWheel.h"
#import "NSObject+ObjectID.h"

const NSUInteger coloursInPicker = 24;

@interface Key () <UIGestureRecognizerDelegate>

@end

@implementation Key {
  UIColor *_backgroundColour;
}

#pragma mark - instantiation methods

-(id)initWithFrame:(CGRect)frame givenColourStyle:(NSString *)colourStyle
                       andRootColourWheelPosition:(NSNumber *)rootColourWheelPosition
                                  andKeyCharacter:(NSString *)keyCharacter
                                     andKeyHeight:(CGFloat)keyHeight
                                andTonesPerOctave:(NSUInteger)tonesPerOctave
                                  andPerfectFifth:(NSUInteger)perfectFifth
                                   andScaleDegree:(NSNumber *)scaleDegreeObject {
  self = [super initWithFrame:frame];
  if (self) {
    self.layer.drawsAsynchronously = YES;
    self.multipleTouchEnabled = NO;
    
      // ugh... turns out it didn't even need the custom gesture recognizer!
    
    NSUInteger scaleDegree = [scaleDegreeObject unsignedIntegerValue];
    [self findColoursWithColourStyle:colourStyle
          andRootColourWheelPosition:[rootColourWheelPosition unsignedIntegerValue]
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
  CGFloat labelHeight = 32.f;
  CGRect labelFrame = CGRectMake(0.f, whiteKeyHeight - labelHeight, keyWidth, labelHeight);
  self.characterLabel = [[UILabel alloc] initWithFrame:labelFrame];
  self.characterLabel.textAlignment = NSTextAlignmentCenter;
  
  if ([colourStyle isEqualToString:@"noColour"]) {
    if (blackKeyHeight == 1.f) {
        // this is a white key
      self.characterLabel.textColor = [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.f];
    } else {
        // this is a black key
      self.characterLabel.textColor = [UIColor whiteColor];
    }
  } else {
      // this is any coloured key
    self.characterLabel.textColor = [UIColor colorWithRed:0.45 green:0.45f blue:0.45f alpha:1.f];
  }
  
  self.characterLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)scaleDegree];

  [self addSubview:self.characterLabel];
}

-(void)findColoursWithColourStyle:(NSString *)colourStyle
       andRootColourWheelPosition:(NSUInteger)rootColourWheelPosition
                  andKeyCharacter:(NSString *)keyCharacter
                     andKeyHeight:(CGFloat)keyHeight
              givenTonesPerOctave:(NSUInteger)tonesPerOctave
                  andPerfectFifth:(NSUInteger)perfectFifth
                   andScaleDegree:(NSUInteger)scaleDegree {

  _backgroundColour = [UIColor colorWithRed:0.3f green:0.3f blue:0.25f alpha:1.f];
  float colourWheelPosition = 0;
  
    // border width depends on whether the key touches its neighbours
  if (keyHeight == 1.f) {
    self.layer.borderWidth = 0.5f;
  } else {
    self.layer.borderWidth = 1.f;
  }
  self.layer.borderColor = _backgroundColour.CGColor;

  CGFloat redValue;
  CGFloat greenValue;
  CGFloat blueValue;
  
    // find colour
  if ([colourStyle isEqualToString:@"noColour"]) {
      // adjust values for noColour keyboard
    if (keyHeight == 1.f) {
        // white key
      
      redValue = 39/40.f;
      greenValue = 39/40.f;
      blueValue = 36/40.f;
      
      CGFloat redHighlight = 1.f;
      CGFloat greenHighlight = 1.f;
      CGFloat blueHighlight = 76/80.f;
      
      self.normalColour = [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1.f];
      [self addGradientToKeyWithColour:self.normalColour givenColourStyle:@"whiteKey"];
      self.highlightedColour = [UIColor colorWithRed:redHighlight green:greenHighlight blue:blueHighlight alpha:1.f];
    } else {
        // black key
      CGFloat minBright = 0.3f;
      CGFloat maxBright = 0.8f;
      CGFloat addition = (maxBright - minBright) * keyHeight;

      redValue = minBright + addition;
      greenValue = minBright + addition;
      blueValue = (minBright + addition) * 0.85f;
      
      self.normalColour = [UIColor colorWithRed:redValue
                                          green:greenValue
                                           blue:blueValue
                                          alpha:1.f];
      [self findColouredKeyHighlightedColourGivenColourStyle:colourStyle];
      [self addShadow];
    }
      [self addGradientToKeyWithColour:self.normalColour givenColourStyle:colourStyle];
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
      colourWheelPosition = fmodf((1.f - ((float)fifthWheelPosition / tonesPerOctave) + (rootColourWheelPosition / (CGFloat)coloursInPicker)), 1.f);
    } else if ([colourStyle isEqualToString:@"stepwise"]) {
      colourWheelPosition = fmodf((1.f - ((float)scaleDegree / tonesPerOctave) + (rootColourWheelPosition / (CGFloat)coloursInPicker)), 1.f);
    }
    
    self.normalColour = [UIColor findNormalKeyColour:colourWheelPosition withMinBright:0.6f];
    [self findColouredKeyHighlightedColourGivenColourStyle:@"coloured"]; // for both fifthWheel and stepwise
    [self addGradientToKeyWithColour:self.normalColour givenColourStyle:@"coloured"];
    if (keyHeight != 1.f) { // only adds shadow if not a white key
      [self addShadow];
    }
  }
}

-(void)addGradientToKeyWithColour:(UIColor *)colour givenColourStyle:(NSString *)colourStyle {

  CGFloat redValue, greenValue, blueValue, alpha;
  [colour getRed:&redValue green:&greenValue blue:&blueValue alpha:&alpha];
  
  CGFloat gradientRed;
  CGFloat gradientGreen;
  CGFloat gradientBlue;
  UIColor *topGradient;
  UIColor *bottomGradient;
  
    // no colour gradient lightens up, colour gradient darkens up
  if ([colourStyle isEqualToString:@"noColour"]) {
    gradientRed = redValue + ((1.f - redValue) / 4.f);
    gradientGreen = greenValue + ((1.f - greenValue) / 4.f);
    gradientBlue = blueValue + ((1.f - blueValue) / 4.f);
  } else {
    gradientRed = redValue * 9/20.f;
    gradientGreen = greenValue * 9/20.f;
    gradientBlue = blueValue * 9/20.f;
  }
  topGradient = [UIColor colorWithRed:gradientRed green:gradientGreen blue:gradientBlue alpha:0.5f];
  bottomGradient = [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:0.5f];
  
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.frame = self.layer.bounds;
  gradientLayer.colors = @[(id)topGradient.CGColor, (id)bottomGradient.CGColor];
  
  gradientLayer.locations = @[@0.f, @1.f];
  
  [self.layer addSublayer:gradientLayer];
}

-(void)addShadow {
//  self.layer.shadowColor = _backgroundColour.CGColor;
//  self.layer.shadowOpacity = 0.45f;
//  self.layer.shadowOffset = CGSizeMake(2.f, 2.f);
}

-(void)findColouredKeyHighlightedColourGivenColourStyle:(NSString *)colourStyle {
  CGFloat normalRed, normalGreen, normalBlue, highlightedRed, highlightedGreen, highlightedBlue, alpha;
  [self.normalColour getRed:&normalRed green:&normalGreen blue:&normalBlue alpha:&alpha];
  
  if ([colourStyle isEqualToString:@"coloured"]) {
    highlightedRed = normalRed + ((1.f - normalRed) * 4/5.f) + 0.2f;
    highlightedGreen = normalGreen + ((1.f - normalGreen) * 4/5.f) + 0.2f;
    highlightedBlue = normalBlue + ((1.f - normalBlue) * 4/5.f) + 0.2f;
  } else {
      // for noColour
    highlightedRed = normalRed + ((1.f - normalRed) / 4.f);
    highlightedGreen = normalGreen + ((1.f - normalGreen) / 4.f);
    highlightedBlue = normalBlue + ((1.f - normalBlue) / 4.f);
  }
  
  self.highlightedColour = [UIColor colorWithRed:highlightedRed green:highlightedGreen blue:highlightedBlue alpha:alpha];
}

#pragma mark - touch methods

-(void)addTouchToThisKey:(UITouch *)touch {
  if (self.mostRecentTouch != touch) {
    [self.delegate pressKey:self];
    self.backgroundColor = self.highlightedColour;
  }
  self.mostRecentTouch = touch;
  [self.delegate addKeyToKeysSounded:self];
}

-(void)removeTouchFromThisKey:(UITouch *)touch {
  if (self.mostRecentTouch == touch) {
    [self.delegate liftKey:self];
    self.backgroundColor = self.normalColour;
    self.mostRecentTouch = nil;
    [self.delegate removeKeyFromKeysSounded:self];
  }
}

-(void)removeThisKey {
  [self.delegate liftKey:self];
  self.backgroundColor = self.normalColour;
  self.mostRecentTouch = nil;
  [self.delegate removeKeyFromKeysSounded:self];
  
}

#pragma mark - gesture recognizer delegate methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyTouchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyTouchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyTouchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate keyTouchesCancelled:touches withEvent:event];
}

@end









