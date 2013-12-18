//
//  CustomScrollView.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/17/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomScrollViewDelegate;

@interface CustomScrollView : UIScrollView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<CustomScrollViewDelegate> customDelegate;

@end

@protocol CustomScrollViewDelegate <NSObject>

-(void)customScrollViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)customScrollViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)customScrollViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)customScrollViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end