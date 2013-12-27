//
//  SettingsViewController.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DataModel;

@protocol SettingsDelegate;

@interface SettingsViewController : UIViewController

@property (strong, nonatomic) UIButton *saveButton;

@property (strong, nonatomic) UIButton *twelveButton;
@property (strong, nonatomic) UIButton *seventeenButton;
@property (strong, nonatomic) UIButton *nineteenButton;
@property (strong, nonatomic) UIButton *twentyFourButton;
@property (strong, nonatomic) UIButton *thirtyOneButton;
@property (strong, nonatomic) UIButton *fortyOneButton;
@property (strong, nonatomic) UIPickerView *tonesPerOctavePicker;

@property (strong, nonatomic) UIButton *numberedKeyButton;
@property (strong, nonatomic) UIButton *blankKeyButton;
@property (strong, nonatomic) UIButton *whiteBlackLayoutButton;
@property (strong, nonatomic) UIButton *gridLayoutButton;
@property (strong, nonatomic) UIPickerView *gridIntervalPicker;

@property (strong, nonatomic) UIButton *fifthWheelColourButton;
@property (strong, nonatomic) UIButton *stepwiseColourButton;
@property (strong, nonatomic) UIButton *noColourButton;
@property (strong, nonatomic) UIPickerView *colourPicker;

@property (strong, nonatomic) UIButton *userButtonsBottomLeftButton;
@property (strong, nonatomic) UIButton *userButtonsBottomRightButton;

@property (strong, nonatomic) UIButton *smallKeysButton;
@property (strong, nonatomic) UIButton *bigKeysButton;

@property (strong, nonatomic) UIButton *octaveLabel;
@property (strong, nonatomic) UIButton *rootColourLabel;
@property (strong, nonatomic) UIButton *gridButtonLabel;

@property (strong, nonatomic) UIView *gridPickerCover;
@property (strong, nonatomic) UIView *gridIntervalLabelCover;
@property (strong, nonatomic) UIView *colourPickerCover;
@property (strong, nonatomic) UIView *rootColourLabelCover;
@property (strong, nonatomic) UIView *fifthWheelButtonCover;
@property (strong, nonatomic) UIView *whiteBlackButtonCover;

@property (strong, nonatomic) DataModel *dataModel;
@property (weak, nonatomic) id<SettingsDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *iPadPopupView;

@end

@protocol SettingsDelegate <NSObject>

-(void)updateKeyboardWithChangedDataModel:(DataModel *)dataModel;
-(NSUInteger)findPerfectFifthWithTonesPerOctave:(NSUInteger)tonesPerOctave;
-(void)removeDarkOverlay;
-(void)hideStatusBar:(BOOL)shouldBeHidden;

@end