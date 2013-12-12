//
//  SettingsViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "SettingsViewController.h"
#import "DataModel.h"

@interface SettingsViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@end

@implementation SettingsViewController {
  BOOL _changesMade;
  NSArray *_allButtonArrays;
  NSArray *_tonesPerOctaveButtons;
  NSArray *_pickerTones;
  NSArray *_instrumentButtons;
  NSArray *_keyCharacterButtons;
  NSArray *_keyboardStyleButtons;
  NSArray *_colourStyleButtons;
  NSArray *_userButtons;
  
  NSUInteger _tonesPerOctave;
  NSString *_instrument;
  NSString *_keyboardStyle;
  NSString *_colourStyle;
  NSString *_keyCharacter;
  NSString *_userButtonsPosition;
}

#pragma mark - view methods

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

  // TODO: need to add images individually to buttons
-(void)viewDidLoad {
  [super viewDidLoad];
  
  _changesMade = NO;
  
  _tonesPerOctave = [self.dataModel.tonesPerOctave integerValue];
  _instrument = self.dataModel.instrument;
  _keyCharacter = self.dataModel.keyCharacter;
  _keyboardStyle = self.dataModel.keyboardStyle;
  _colourStyle = self.dataModel.colourStyle;
  _userButtonsPosition = self.dataModel.userButtonsPosition;
  
  NSMutableArray *pickerTonesTemp = [[NSMutableArray alloc] init];
  for (int i = 2; i <= 36; i++) {
    [pickerTonesTemp addObject:[NSNumber numberWithInt:i]];
  }
  _pickerTones = [NSArray arrayWithArray:pickerTonesTemp];
  self.tonesPerOctavePicker.delegate = self;
  [self.tonesPerOctavePicker selectRow:(_tonesPerOctave - 2) inComponent:0 animated:NO];

  _tonesPerOctaveButtons = @[self.twelveButton, self.fiveButton, self.sevenButton, self.fifteenButton, self.seventeenButton,
                             self.nineteenButton, self.twentyTwoButton, self.twentyFourButton, self.thirtyOneButton];
  _instrumentButtons = @[self.pianoButton, self.violinButton, self.steelpanButton];
  _keyCharacterButtons = @[self.numberedKeyButton, self.accidentalKeyButton, self.blankKeyButton];
  _keyboardStyleButtons = @[self.whiteBlackLayoutButton, self.justWhiteLayoutButton, self.gridLayoutButton];
  _colourStyleButtons = @[self.fifthWheelColourButton, self.stepwiseColourButton, self.noColourButton];
  _userButtons = @[self.userButtonsRightButton, self.userButtonsLeftButton];
  _allButtonArrays = @[_tonesPerOctaveButtons, _instrumentButtons, _keyCharacterButtons, _keyboardStyleButtons, _colourStyleButtons, _userButtons, _instrumentButtons];
  
  for (NSArray *buttonsArray in _allButtonArrays) {
    for (UIButton *button in buttonsArray) {
      [button addTarget:self action:@selector(musicButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
  }
  [self presentState];
}

-(void)musicButtonTapped:(UIButton *)sender {

  if ([_tonesPerOctaveButtons containsObject:sender]) {
    if (sender == self.fiveButton) {
      if (_tonesPerOctave != 5) {
        _tonesPerOctave = 5;
        _changesMade = YES;
      }
    } else if (sender == self.sevenButton) {
      if (_tonesPerOctave != 7) {
        _tonesPerOctave = 7;
        _changesMade = YES;
      }
    } else if (sender == self.twelveButton) {
      if (_tonesPerOctave != 12) {
        _tonesPerOctave = 12;
        
        _changesMade = YES;
      }
    } else if (sender == self.fifteenButton) {
      if (_tonesPerOctave != 15) {
        _tonesPerOctave = 15;
        _changesMade = YES;
      }
    } else if (sender == self.seventeenButton) {
      if (_tonesPerOctave != 17) {
        _tonesPerOctave = 17;
        _changesMade = YES;
      }
    } else if (sender == self.nineteenButton) {
      if (_tonesPerOctave != 19) {
        _tonesPerOctave = 19;
        _changesMade = YES;
      }
    } else if (sender == self.twentyTwoButton) {
      if (_tonesPerOctave != 22) {
        _tonesPerOctave = 22;
        _changesMade = YES;
      }
    } else if (sender == self.twentyFourButton) {
      if (_tonesPerOctave != 24) {
        _tonesPerOctave = 24;
        _changesMade = YES;
      }
    } else if (sender == self.thirtyOneButton) {
      if (_tonesPerOctave != 31) {
        _tonesPerOctave = 31;
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _tonesPerOctaveButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
        [self.tonesPerOctavePicker selectRow:(_tonesPerOctave - 2) inComponent:0 animated:YES];
      }
    }
  }
  
  if ([_instrumentButtons containsObject:sender]) {
    if (sender == self.pianoButton) {
      if (![_instrument isEqualToString:@"piano"]) {
        _instrument = @"piano";
        _changesMade = YES;
      }
    } else if (sender == self.violinButton) {
      if (![_instrument isEqualToString:@"violin"]) {
        _instrument = @"violin";
        _changesMade = YES;
      }
    } else if (sender == self.steelpanButton) {
      if (![_instrument isEqualToString:@"steelpan"]) {
        _instrument = @"steelpan";
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _instrumentButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
      }
    }
  }
  
  
  if ([_keyCharacterButtons containsObject:sender]) {
    if (sender == self.numberedKeyButton) {
      if (![_keyCharacter isEqualToString:@"numbered"]) {
        _keyCharacter = @"numbered";
        _changesMade = YES;
      }
    } else if (sender == self.accidentalKeyButton) {
      if (![_keyCharacter isEqualToString:@"accidental"]) {
        _keyCharacter = @"accidental";
        _changesMade = YES;
      }
    } else if (sender == self.blankKeyButton) {
      if (![_keyCharacter isEqualToString:@"blank"]) {
        _keyCharacter = @"blank";
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _keyCharacterButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
      }
    }
  }
  
  if ([_keyboardStyleButtons containsObject:sender]) {
    if (sender == self.whiteBlackLayoutButton) {
      if (![_keyboardStyle isEqualToString:@"whiteBlack"]) {
        _keyboardStyle = @"whiteBlack";
        _changesMade = YES;
      }
    } else if (sender == self.justWhiteLayoutButton) {
      if (![_keyboardStyle isEqualToString:@"justWhite"]) {
        _keyboardStyle = @"justWhite";
        _changesMade = YES;
      }
    } else if (sender == self.gridLayoutButton) {
      if (![_keyboardStyle isEqualToString:@"grid"]) {
        _keyboardStyle = @"grid";
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _keyboardStyleButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
      }
    }
  }

  if ([_colourStyleButtons containsObject:sender]) {
    if (sender == self.fifthWheelColourButton) {
      if (![_colourStyle isEqualToString:@"fifthWheel"]) {
        _colourStyle = @"fifthWheel";
        _changesMade = YES;
      }
    } else if (sender == self.stepwiseColourButton) {
      if (![_colourStyle isEqualToString:@"stepwise"]) {
        _colourStyle = @"stepwise";
        _changesMade = YES;
      }
    } else if (sender == self.noColourButton) {
      if (![_colourStyle isEqualToString:@"noColour"]) {
        _colourStyle = @"noColour";
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _colourStyleButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
      }
    }
  }

  if ([_userButtons containsObject:sender]) {
    if (sender == self.userButtonsRightButton) {
      if (![_userButtonsPosition isEqualToString:@"right"]) {
        _userButtonsPosition = @"right";
        _changesMade = YES;
      }
    } else if (sender == self.userButtonsLeftButton) {
      if (![_userButtonsPosition isEqualToString:@"left"]) {
        _userButtonsPosition = @"left";
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _userButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
      }
    }
  }

  NSLog(@"new settings: %i, %@, %@, %@, %@, %@", _tonesPerOctave, _instrument, _keyCharacter, _keyboardStyle, _colourStyle, _userButtonsPosition);
}

-(IBAction)doneButtonTapped:(id)sender {
  if (_changesMade) {
//    NSLog(@"Changes made");
    self.dataModel.tonesPerOctave = [NSNumber numberWithInteger:_tonesPerOctave ];
    self.dataModel.instrument = _instrument;
    self.dataModel.keyCharacter = _keyCharacter;
    self.dataModel.keyboardStyle = _keyboardStyle;
    self.dataModel.colourStyle = _colourStyle;
    self.dataModel.userButtonsPosition = _userButtonsPosition;
    [self.delegate updateKeyboardWithChangedDataModel:self.dataModel];
  }
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)presentState {
  [self presentPickerState];
  UIButton *tempChosenInstrument;
  if ([_instrument isEqualToString:@"piano"]) {
    tempChosenInstrument = self.pianoButton;
  } else if ([_instrument isEqualToString:@"violin"]) {
    tempChosenInstrument = self.violinButton;
  } else if ([_instrument isEqualToString:@"steelpan"]) {
    tempChosenInstrument = self.steelpanButton;
  }
  
  UIButton *tempChosenKeyCharacter;
  if ([_keyCharacter isEqualToString:@"numbered"]) {
    tempChosenKeyCharacter = self.numberedKeyButton;
  } else if ([_keyCharacter isEqualToString:@"accidental"]) {
    tempChosenKeyCharacter = self.accidentalKeyButton;
  } else if ([_keyCharacter isEqualToString:@"blank"]) {
    tempChosenKeyCharacter = self.blankKeyButton;
  }
  
  UIButton *tempChosenKeyboardStyle;
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    tempChosenKeyboardStyle = self.whiteBlackLayoutButton;
  } else if ([_keyboardStyle isEqualToString:@"justWhite"]) {
    tempChosenKeyboardStyle = self.justWhiteLayoutButton;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    tempChosenKeyboardStyle = self.gridLayoutButton;
  }
  
  UIButton *tempChosenColour;
  if ([_colourStyle isEqualToString:@"fifthWheel"]) {
    tempChosenColour = self.fifthWheelColourButton;
  } else if ([_colourStyle isEqualToString:@"stepwise"]) {
    tempChosenColour = self.stepwiseColourButton;
  } else if ([_colourStyle isEqualToString:@"noColour"]) {
    tempChosenColour = self.noColourButton;
  }
  
  UIButton *tempUserButton;
  if ([_userButtonsPosition isEqualToString:@"right"]) {
    tempUserButton = self.userButtonsRightButton;
  } else if ([_userButtonsPosition isEqualToString:@"left"]) {
    tempUserButton = self.userButtonsLeftButton;
  }
  
  for (UIButton *button in _instrumentButtons) {
    if (button == tempChosenInstrument) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
  for (UIButton *button in _keyCharacterButtons) {
    if (button == tempChosenKeyCharacter) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
  for (UIButton *button in _keyboardStyleButtons) {
    if (button == tempChosenKeyboardStyle) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
  for (UIButton *button in _colourStyleButtons) {
    if (button == tempChosenColour) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
  for (UIButton *button in _userButtons) {
    if (button == tempUserButton) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
}

#pragma mark - picker view methods

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  if (pickerView == self.tonesPerOctavePicker) {
    return 35;
  }
  return 0;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return [NSString stringWithFormat:@"%@", _pickerTones[row]];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  _changesMade = YES;
  _tonesPerOctave = row + 2;
  [self presentPickerState];
}

-(void)presentPickerState {
  UIButton *tempChosenButton;
  switch (_tonesPerOctave) {
    case 5:
      tempChosenButton = self.fiveButton;
      break;
    case 7:
      tempChosenButton = self.sevenButton;
      break;
    case 12:
      tempChosenButton = self.twelveButton;
      break;
    case 15:
      tempChosenButton = self.fifteenButton;
      break;
    case 17:
      tempChosenButton = self.seventeenButton;
      break;
    case 19:
      tempChosenButton = self.nineteenButton;
      break;
    case 22:
      tempChosenButton = self.twentyTwoButton;
      break;
    case 24:
      tempChosenButton = self.twentyFourButton;
      break;
    case 31:
      tempChosenButton = self.thirtyOneButton;
      break;
    default:
      tempChosenButton = nil;
      break;
  }
  for (UIButton *button in _tonesPerOctaveButtons) {
    if (button == tempChosenButton) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
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
