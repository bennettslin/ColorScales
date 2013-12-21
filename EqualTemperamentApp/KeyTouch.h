//
//  KeyTouch.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/19/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Key;

@interface KeyTouch : UITouch

@property (weak, nonatomic) Key *myKey;

-(void)setKeyProperty:(Key *)key;

@end
