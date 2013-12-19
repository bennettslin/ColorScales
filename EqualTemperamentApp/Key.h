//
//  Key.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/12/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KeyDelegate;

@interface Key : UIButton

@property (strong, nonatomic) UIColor *normalColour;
@property (strong, nonatomic) UIColor *highlightedColour;
@property (strong, nonatomic) UILabel *characterLabel;
@property NSUInteger noModScaleDegree;

@property (weak, nonatomic) id<KeyDelegate> delegate;

-(id)initWithFrame:(CGRect)frame givenColourStyle:(NSString *)colourStyle
                       andRootColourWheelPosition:(NSNumber *)rootColourWheelPosition
                                  andKeyCharacter:(NSString *)keyCharacter
                                     andKeyHeight:(CGFloat)keyHeight
                                andTonesPerOctave:(NSUInteger)tonesPerOctave
                                  andPerfectFifth:(NSUInteger)perfectFifth
                                   andScaleDegree:(NSNumber *)scaleDegreeObject;
@end

@protocol KeyDelegate <NSObject>

-(void)handleTapFromKey:(Key *)key;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key;
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key;
@end