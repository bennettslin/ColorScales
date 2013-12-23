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
@property (strong, nonatomic) UITouch *mostRecentTouch;

@property (weak, nonatomic) id<KeyDelegate> delegate;

-(id)initWithFrame:(CGRect)frame givenColourStyle:(NSString *)colourStyle
                       andRootColourWheelPosition:(NSNumber *)rootColourWheelPosition
                                  andKeyCharacter:(NSString *)keyCharacter
                                     andKeyHeight:(CGFloat)keyHeight
                                andTonesPerOctave:(NSUInteger)tonesPerOctave
                                  andPerfectFifth:(NSUInteger)perfectFifth
                                   andScaleDegree:(NSNumber *)scaleDegreeObject;

-(void)addTouchToThisKey:(UITouch *)touch;
-(void)removeTouchFromThisKey:(UITouch *)touch;
-(void)removeThisKey;

@end

@protocol KeyDelegate <NSObject>

-(void)keyTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)keyTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)keyTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)keyTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)pressKey:(Key *)key;
-(void)liftKey:(Key *)key;
-(void)addKeyToKeysSounded:(Key *)key;
-(void)removeKeyFromKeysSounded:(Key *)key;
//-(UIScrollView *)tellKeyScrollview;

@end