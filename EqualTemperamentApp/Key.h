//
//  Key.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/12/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Key : UIButton

@property (strong, nonatomic) UIColor *normalColour;
@property (strong, nonatomic) UIColor *highlightedColour;
@property (strong, nonatomic) UILabel *characterLabel;
@property (strong, nonatomic) UIColor *borderColour;

-(id)initWithFrame:(CGRect)frame
  givenColourStyle:(NSString *)colourStyle
   andKeyCharacter:(NSString *)keyCharacter
      andKeyHeight:(CGFloat)keyHeight
 andTonesPerOctave:(NSUInteger)tonesPerOctave
   andPerfectFifth:(NSUInteger)perfectFifth
    andScaleDegree:(NSNumber *)scaleDegreeObject;

@end