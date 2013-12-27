//
//  HelpViewController.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HelpDelegate;

@interface HelpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *popupView;
@property (weak, nonatomic) id<HelpDelegate> delegate;

@end

@protocol HelpDelegate <NSObject>

-(void)removeDarkOverlay;
-(void)hideStatusBar:(BOOL)shouldBeHidden;

@end