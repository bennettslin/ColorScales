//
//  KeyGestureRecognizer.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KeyGestureRecognizerDelegate ;

@interface KeyGestureRecognizer : UITapGestureRecognizer

@property (weak, nonatomic) id<KeyGestureRecognizerDelegate> delegate;

@end

@protocol KeyGestureRecognizerDelegate <NSObject>

-(void)keyTouchesBegan:(NSSet *)keyTouches withEvent:(UIEvent *)event;
-(void)keyTouchesMoved:(NSSet *)keyTouches withEvent:(UIEvent *)event;
-(void)keyTouchesEnded:(NSSet *)keyTouches withEvent:(UIEvent *)event;
-(void)keyTouchesCancelled:(NSSet *)keyTouches withEvent:(UIEvent *)event;

@end
