//
//  KeyboardViewController.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Stk.h"
#include "Mandolin.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"
@class Key;

using namespace stk;
struct AudioData {
  Mandolin *myMandolin;
};


@interface KeyboardViewController : UIViewController <SettingsDelegate, HelpDelegate>

@property (strong, nonatomic) NSNumber *inputTonesPerOctave;
@property (strong, nonatomic) NSNumber *rootTone;

-(void)removeDarkOverlay;

@end
