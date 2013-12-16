//
//  UIColor+ColourWheel.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/15/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (ColourWheel)

+(UIColor *)findNormalKeyColour:(CGFloat)colourWheelPosition withMinBright:(CGFloat)minBright;

@end
