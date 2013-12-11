//
//  SettingsViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController {
  BOOL _changesMade;
  NSArray *_allButtons;
  NSString *_keyboardStyle;
  NSString *_colourStyle;
  NSString *_keyCharacter;
  NSString *_userButtonsPosition;
}
  // TODO: add instrument
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {

  }
  return self;
}

  // TODO: Boolean only when changes are made
  // TODO: need to add images individually to buttons
-(void)viewDidLoad {
  [super viewDidLoad];
  _changesMade = NO;
  _keyCharacter = @"numbered";
  _keyboardStyle = @"whiteBlack";
  _colourStyle = @"fifthWheel";
  _userButtonsPosition = @"right";
  _allButtons = @[self.numberedKeyButton, self.accidentalKeyButton, self.blankKeyButton,
                  self.whiteBlackLayoutButton, self.justWhiteLayoutButton, self.gridLayoutButton,
                  self.fifthWheelColourButton, self.stepwiseColourButton, self.noColourButton,
                  self.userButtonsRightButton, self.userButtonsLeftButton];
  int i = 0;
  for (UIButton *button in _allButtons) {
    if (i % 3 == 0) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
    button.tag = 900 + i;
    [button addTarget:self action:@selector(musicButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    i++;
    NSLog(@"%i", i);
  }
}

-(void)musicButtonTapped:(UIButton *)sender {
  switch (sender.tag) {
    case 900:
      if (![_keyCharacter isEqualToString:@"numbered"]) {
        _keyCharacter = @"numbered";
        self.numberedKeyButton.selected = YES;
        self.accidentalKeyButton.selected = NO;
        self.blankKeyButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 901:
      if (![_keyCharacter isEqualToString:@"accidental"]) {
        _keyCharacter = @"accidental";
        self.numberedKeyButton.selected = NO;
        self.accidentalKeyButton.selected = YES;
        self.blankKeyButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 902:
      if (![_keyCharacter isEqualToString:@"blank"]) {
        _keyCharacter = @"blank";
        self.numberedKeyButton.selected = NO;
        self.accidentalKeyButton.selected = NO;
        self.blankKeyButton.selected = YES;
        _changesMade = YES;
      }
      break;
          //
    case 903:
      if (![_keyboardStyle isEqualToString:@"whiteBlack"]) {
        _keyboardStyle = @"whiteBlack";
        self.whiteBlackLayoutButton.selected = YES;
        self.justWhiteLayoutButton.selected = NO;
        self.gridLayoutButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 904:
      if (![_keyboardStyle isEqualToString:@"justWhite"]) {
        _keyboardStyle = @"justWhite";
        self.whiteBlackLayoutButton.selected = NO;
        self.justWhiteLayoutButton.selected = YES;
        self.gridLayoutButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 905:
      if (![_keyboardStyle isEqualToString:@"grid"]) {
          _keyboardStyle = @"grid";
          self.whiteBlackLayoutButton.selected = NO;
          self.justWhiteLayoutButton.selected = NO;
          self.gridLayoutButton.selected = YES;
        _changesMade = YES;
      }
      break;
          //
    case 906:
      if (![_colourStyle isEqualToString:@"fifthWheel"]) {
        _colourStyle = @"fifthWheel";
        self.fifthWheelColourButton.selected = YES;
        self.stepwiseColourButton.selected = NO;
        self.noColourButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 907:
      if (![_colourStyle isEqualToString:@"stepwise"]) {
        _colourStyle = @"stepwise";
        self.fifthWheelColourButton.selected = NO;
        self.stepwiseColourButton.selected = YES;
        self.noColourButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 908:
      if (![_colourStyle isEqualToString:@"noColour"]) {
        _colourStyle = @"noColour";
        self.fifthWheelColourButton.selected = NO;
        self.stepwiseColourButton.selected = NO;
        self.noColourButton.selected = YES;
        _changesMade = YES;
      }
      break;
          //
    case 909:
      if (![_userButtonsPosition isEqualToString:@"right"]) {
        _userButtonsPosition = @"right";
        self.userButtonsRightButton.selected = YES;
        self.userButtonsLeftButton.selected = NO;
        _changesMade = YES;
      }
      break;
    case 910:
      if (![_userButtonsPosition isEqualToString:@"left"]) {
        _userButtonsPosition = @"left";
        self.userButtonsRightButton.selected = NO;
        self.userButtonsLeftButton.selected = YES;
        _changesMade = YES;
      }
      break;
  }
  NSLog(@"new settings: %@, %@, %@, %@", _keyCharacter, _keyboardStyle, _colourStyle, _userButtonsPosition);
}

-(IBAction)doneButtonTapped:(id)sender {
  if (_changesMade) {
    NSLog(@"Changes made");
    [self.delegate updateKeyCharacter:_keyCharacter andKeyboardStyle:_keyboardStyle andColourStyle:_colourStyle andUserButtonsPosition:_userButtonsPosition];
  }
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - app methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
  NSLog(@"deallocated %@", self);
}

@end
