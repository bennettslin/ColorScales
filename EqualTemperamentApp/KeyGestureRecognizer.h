//
//  KeyGestureRecognizer.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KeyGestureRecognizerDelegate;

@interface KeyGestureRecognizer : UITapGestureRecognizer

@property (weak, nonatomic) id<KeyGestureRecognizerDelegate> delegate;

@end

@protocol KeyGestureRecognizerDelegate <NSObject>

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
