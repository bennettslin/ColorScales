//
//  SettingsViewController.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsDelegate;

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *numberedKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *accidentalKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *blankKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *whiteBlackLayoutButton;
@property (weak, nonatomic) IBOutlet UIButton *justWhiteLayoutButton;
@property (weak, nonatomic) IBOutlet UIButton *gridLayoutButton;
@property (weak, nonatomic) IBOutlet UIButton *fifthWheelColourButton;
@property (weak, nonatomic) IBOutlet UIButton *stepwiseColourButton;
@property (weak, nonatomic) IBOutlet UIButton *noColourButton;
@property (weak, nonatomic) IBOutlet UIButton *userButtonsRightButton;
@property (weak, nonatomic) IBOutlet UIButton *userButtonsLeftButton;
@property (weak, nonatomic) id<SettingsDelegate> delegate;

-(IBAction)doneButtonTapped:(id)sender;

@end

@protocol SettingsDelegate <NSObject>

-(void)updateKeyCharacter:(NSString *)keyCharacter andKeyboardStyle:(NSString *)keyboardStyle andColourStyle:(NSString *)colourStyle andUserButtonsPosition:(NSString *)userButtonsPosition;

@end