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

@property (weak, nonatomic) IBOutlet UIButton *fiveButton;
@property (weak, nonatomic) IBOutlet UIButton *sevenButton;
@property (weak, nonatomic) IBOutlet UIButton *twelveButton;
@property (weak, nonatomic) IBOutlet UIButton *fifteenButton;
@property (weak, nonatomic) IBOutlet UIButton *seventeenButton;
@property (weak, nonatomic) IBOutlet UIButton *nineteenButton;
@property (weak, nonatomic) IBOutlet UIButton *twentyTwoButton;
@property (weak, nonatomic) IBOutlet UIButton *twentyFourButton;
@property (weak, nonatomic) IBOutlet UIButton *thirtyOneButton;
@property (weak, nonatomic) IBOutlet UIPickerView *tonesPerOctavePicker;

@property (weak, nonatomic) IBOutlet UIButton *pianoButton;
@property (weak, nonatomic) IBOutlet UIButton *violinButton;
@property (weak, nonatomic) IBOutlet UIButton *steelpanButton;

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

@property (strong, nonatomic) DataModel *dataModel;
@property (weak, nonatomic) id<SettingsDelegate> delegate;

-(IBAction)doneButtonTapped:(id)sender;

@end

@protocol SettingsDelegate <NSObject>

-(void)updateKeyboardWithChangedDataModel:(DataModel *)dataModel;

@end