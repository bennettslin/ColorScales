//
//  UIColor+ColourWheel.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/15/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "UIColor+ColourWheel.h"

@implementation UIColor (ColourWheel)

+(UIColor *)findNormalKeyColour:(CGFloat)colourWheelPosition withMinBright:(CGFloat)minBright {
  CGFloat redValue, greenValue, blueValue;
  CGFloat maxBright;
  
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
  return [self colorWithRed:redValue green:greenValue blue:blueValue alpha:1.f];
}

+(UIColor *)blackKeyboardBackground {
  return [self colorWithRed:0.12f green:0.12f blue:0.1f alpha:1.f];
}

+(UIColor *)darkGrayKeyboardBackground {
  return [self colorWithRed:0.35f green:0.35f blue:0.29f alpha:1.f];
}

+(UIColor *)orangeTint {
  return [UIColor colorWithRed:1.f green:0.65f blue:0.10f alpha:1.f];
}

+(UIColor *)orangeTintHighlighted {
  return [UIColor colorWithRed:1.f green:0.80f blue:0.47f alpha:1.f];
}

+(UIColor *)brownSettings {
  return [UIColor colorWithRed:0.3f green:0.3f blue:0.1f alpha:1.f];
}

+(UIColor *)lightYellowSettingsBackground {
  return [UIColor colorWithRed:0.88f green:0.88f blue:0.72f alpha:1.f];
}

+(UIColor *)lightYellowPickerCover {
  CGFloat red, green, blue, alpha;
  [[self lightYellowSettingsBackground] getRed:&red green:&green blue:&blue alpha:&alpha];
  return [UIColor colorWithRed:red green:green blue:blue alpha:0.8f];
}

+(UIColor *)lighterYellowSettingsBackground {
  return [UIColor colorWithRed:0.92f green:0.92f blue:0.76f alpha:1.f];
}

+(UIColor *)lighterYellowPickerCover {
  CGFloat red, green, blue, alpha;
  [[self lighterYellowSettingsBackground] getRed:&red green:&green blue:&blue alpha:&alpha];
  return [UIColor colorWithRed:red green:green blue:blue alpha:0.85f];
}

+(UIColor *)whiteKeyText {
  return [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.f];
}

+(UIColor *)colouredKeyText {
  return [UIColor colorWithRed:0.45 green:0.45f blue:0.45f alpha:1.f];
}

@end
