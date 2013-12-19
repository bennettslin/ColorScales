//
//  KeyboardOverlay.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/18/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KeyboardOverlayDelegate;

@interface KeyboardOverlay : UIView

@property (weak, nonatomic) id<KeyboardOverlayDelegate> delegate;

@end

@protocol KeyboardOverlayDelegate <NSObject>

-(void)keyboardOverlayTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)keyboardOverlayTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)keyboardOverlayTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)keyboardOverlayTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end