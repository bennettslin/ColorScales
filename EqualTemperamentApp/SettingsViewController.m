//
//  SettingsViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "SettingsViewController.h"
#import "DataModel.h"
#import "UIColor+ColourWheel.h"

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
  NSUInteger _rootColourWheelPosition;

  NSUInteger _tonesPerOctave;
  NSString *_instrument;
  NSString *_keyboardStyle;
  NSUInteger _gridInterval;
  NSString *_colourStyle;
  NSString *_keyCharacter;
  NSString *_userButtonsPosition;
  
  UIColor *_backgroundColour;
  UIColor *_pickerCoverColour;
  
  UIView *_gridPickerCover;
  UIView *_colourPickerCover;
  
  NSUInteger _coloursInPicker;
}

#pragma mark - init methods

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
//    self.modalPresentationStyle = UIModalTransitionStyleFlipHorizontal;
  }
  return self;
}

-(void)presentInParentViewController:(UIViewController *)parentVC {
  self.view.frame = parentVC.view.bounds;
  [parentVC.view addSubview:self.view];
  [parentVC addChildViewController:self];
  [self didMoveToParentViewController:self.parentViewController];
}

-(void)dismissFromParentViewController {
  [self willMoveToParentViewController:nil];
  [self.view removeFromSuperview];
  [self removeFromParentViewController];
}

  // TODO: need to add images individually to buttons
-(void)viewDidLoad {
  [super viewDidLoad];
  _coloursInPicker = 24;
  _backgroundColour = [UIColor colorWithRed:0.92f green:0.92f blue:0.8f alpha:1.f];
  _pickerCoverColour = [UIColor colorWithRed:0.92f green:0.92f blue:0.8f alpha:0.6f];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    self.view.backgroundColor = _backgroundColour;
  } else { // iPad
    self.view.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.5f];
    self.iPadPopupView.backgroundColor = _backgroundColour;
    self.iPadPopupView.layer.cornerRadius = 10.f;
  }


  _changesMade = NO;
  _tonesPerOctave = [self.dataModel.tonesPerOctave unsignedIntegerValue];
  _instrument = self.dataModel.instrument;
  _keyCharacter = self.dataModel.keyCharacter;
  _keyboardStyle = self.dataModel.keyboardStyle;
  _gridInterval = [self.dataModel.gridInterval unsignedIntegerValue];
  _colourStyle = self.dataModel.colourStyle;
  _rootColourWheelPosition = [self.dataModel.rootColourWheelPosition unsignedIntegerValue];
  _userButtonsPosition = self.dataModel.userButtonsPosition;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray *pickerTonesTemp = [[NSMutableArray alloc] init];
    for (int i = 2; i <= 48; i++) {
      [pickerTonesTemp addObject:[NSNumber numberWithInt:i]];
    }
    _pickerTones = [NSArray arrayWithArray:pickerTonesTemp];
    self.tonesPerOctavePicker.delegate = self;
    [self.tonesPerOctavePicker selectRow:_tonesPerOctave - 2 inComponent:0 animated:NO];
  });

  dispatch_async(dispatch_get_main_queue(), ^{
    self.gridIntervalPicker.delegate = self;
    [self.gridIntervalPicker selectRow:_gridInterval - 1 inComponent:0 animated:NO];
    _gridPickerCover = [self createAndAddCoverToPicker:self.gridIntervalPicker];
    if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
      [self coverPicker:self.gridIntervalPicker];
    } else {
      [self uncoverPicker:self.gridIntervalPicker];
    }
  });
  
  dispatch_async(dispatch_get_main_queue(), ^{
    self.colourPicker.delegate = self;
    [self.colourPicker selectRow:_rootColourWheelPosition + (_coloursInPicker * 2000) inComponent:0 animated:NO];
    _colourPickerCover = [self createAndAddCoverToPicker:self.colourPicker];
    if ([_colourStyle isEqualToString:@"noColour"]) {
      [self coverPicker:self.colourPicker];
    } else {
      [self uncoverPicker:self.colourPicker];
    }
  });

  _tonesPerOctaveButtons = @[self.twelveButton, self.seventeenButton, self.nineteenButton,
                             self.twentyFourButton, self.thirtyOneButton, self.fortyOneButton];
  _instrumentButtons = @[self.pianoButton, self.violinButton, self.steelpanButton];
  _keyCharacterButtons = @[self.numberedKeyButton, self.blankKeyButton];
  _keyboardStyleButtons = @[self.whiteBlackLayoutButton, self.gridLayoutButton];
  _colourStyleButtons = @[self.fifthWheelColourButton, self.stepwiseColourButton, self.noColourButton];
  _userButtons = @[self.userButtonsTopRightButton, self.userButtonsTopLeftButton, self.userButtonsBottomRightButton, self.userButtonsBottomLeftButton];
  _allButtonArrays = @[_tonesPerOctaveButtons, _instrumentButtons, _keyCharacterButtons, _keyboardStyleButtons, _colourStyleButtons, _userButtons, _instrumentButtons];
  
  for (NSArray *buttonsArray in _allButtonArrays) {
    for (UIButton *button in buttonsArray) {
      [button addTarget:self action:@selector(musicButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
  }
  [self presentState];
}

#pragma mark - button methods

-(void)musicButtonTapped:(UIButton *)sender {

  if ([_tonesPerOctaveButtons containsObject:sender]) {
    if (sender == self.twelveButton) {
      if (_tonesPerOctave != 12) {
        _tonesPerOctave = 12;
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
    } else if (sender == self.fortyOneButton) {
      if (_tonesPerOctave != 41) {
        _tonesPerOctave = 41;
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _tonesPerOctaveButtons) {
        if (button == sender) {
          button.selected = YES;
            // a custom tonesPerOctave button selected
          self.whiteBlackLayoutButton.enabled = YES;
          [self.tonesPerOctavePicker selectRow:(_tonesPerOctave - 2) inComponent:0 animated:YES];
          [self presentGridPickerState];
        } else {
          button.selected = NO;
        }
      }
    }
    [self determineFifthWheelButtonEnabled];
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
        [self coverPicker:self.gridIntervalPicker];
      }
    } else if (sender == self.gridLayoutButton) {
      if (![_keyboardStyle isEqualToString:@"grid"]) {
        _keyboardStyle = @"grid";
        _changesMade = YES;
        [self uncoverPicker:self.gridIntervalPicker];
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
        [self uncoverPicker:self.colourPicker];
      }
    } else if (sender == self.stepwiseColourButton) {
      if (![_colourStyle isEqualToString:@"stepwise"]) {
        _colourStyle = @"stepwise";
        _changesMade = YES;
        [self uncoverPicker:self.colourPicker];
      }
    } else if (sender == self.noColourButton) {
      if (![_colourStyle isEqualToString:@"noColour"]) {
        _colourStyle = @"noColour";
        _changesMade = YES;
        [self coverPicker:self.colourPicker];
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
    if (sender == self.userButtonsTopRightButton) {
      if (![_userButtonsPosition isEqualToString:@"topRight"]) {
        _userButtonsPosition = @"topRight";
        _changesMade = YES;
      }
    } else if (sender == self.userButtonsTopLeftButton) {
      if (![_userButtonsPosition isEqualToString:@"topLeft"]) {
        _userButtonsPosition = @"topLeft";
        _changesMade = YES;
      }
    } else if (sender == self.userButtonsBottomRightButton) {
      if (![_userButtonsPosition isEqualToString:@"bottomRight"]) {
        _userButtonsPosition = @"bottomRight";
        _changesMade = YES;
      }
    } else if (sender == self.userButtonsBottomLeftButton) {
      if (![_userButtonsPosition isEqualToString:@"bottomLeft"]) {
        _userButtonsPosition = @"bottomLeft";
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
//  NSLog(@"new settings: %lu, %@, %@, %@, %@, %@", (unsigned long)_tonesPerOctave, _instrument, _keyCharacter, _keyboardStyle, _colourStyle, _userButtonsPosition);
}

-(IBAction)doneButtonTapped:(id)sender {
  if (_changesMade) {
//    NSLog(@"Changes made");
    self.dataModel.tonesPerOctave = [NSNumber numberWithUnsignedInteger:_tonesPerOctave ];
    self.dataModel.instrument = _instrument;
    self.dataModel.keyCharacter = _keyCharacter;
    self.dataModel.keyboardStyle = _keyboardStyle;
    self.dataModel.colourStyle = _colourStyle;
    self.dataModel.rootColourWheelPosition = [NSNumber numberWithUnsignedInteger:_rootColourWheelPosition];
    self.dataModel.userButtonsPosition = _userButtonsPosition;
    self.dataModel.gridInterval = [NSNumber numberWithUnsignedInteger:_gridInterval];
    [self.delegate updateKeyboardWithChangedDataModel:self.dataModel];
  }
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  } else { // iPad
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
  }
}

#pragma mark - change view state methods

-(void)presentState {
  [self presentTonesPickerState];
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
  } else if ([_keyCharacter isEqualToString:@"blank"]) {
    tempChosenKeyCharacter = self.blankKeyButton;
  }
  
  UIButton *tempChosenKeyboardStyle;
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    tempChosenKeyboardStyle = self.whiteBlackLayoutButton;
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
  if ([_userButtonsPosition isEqualToString:@"topRight"]) {
    tempUserButton = self.userButtonsTopRightButton;
  } else if ([_userButtonsPosition isEqualToString:@"topLeft"]) {
    tempUserButton = self.userButtonsTopLeftButton;
  } else if ([_userButtonsPosition isEqualToString:@"bottomRight"]) {
    tempUserButton = self.userButtonsBottomRightButton;
  } else if ([_userButtonsPosition isEqualToString:@"bottomLeft"]) {
    tempUserButton = self.userButtonsBottomLeftButton;
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

-(void)presentGridPickerState {
  NSUInteger perfectFourth = _tonesPerOctave - [self.delegate findPerfectFifthWithTonesPerOctave:_tonesPerOctave];
  _gridInterval = perfectFourth;
  [self.gridIntervalPicker reloadAllComponents];
  [self.gridIntervalPicker selectRow:perfectFourth - 1 inComponent:0 animated:YES];
}

-(void)presentTonesPickerState {
  UIButton *tempChosenButton;
  switch (_tonesPerOctave) {
    case 12:
      tempChosenButton = self.twelveButton;
      break;
    case 17:
      tempChosenButton = self.seventeenButton;
      break;
    case 19:
      tempChosenButton = self.nineteenButton;
      break;
    case 24:
      tempChosenButton = self.twentyFourButton;
      break;
    case 31:
      tempChosenButton = self.thirtyOneButton;
      break;
    case 41:
      tempChosenButton = self.fortyOneButton;
      break;
    default:
      tempChosenButton = nil;
        // if not a custom tone, there is no whiteBlack layout
      [self disableWhiteBlackButtonAndForceGrid];
      break;
  }
  
  for (UIButton *button in _tonesPerOctaveButtons) {
    if (button == tempChosenButton) {
      button.selected = YES;
        // a custom tonesPerOctave button selected
      self.whiteBlackLayoutButton.enabled = YES;
    } else {
      button.selected = NO;
    }
  }
  [self determineFifthWheelButtonEnabled];
}

-(void)disableWhiteBlackButtonAndForceGrid {
    // no custom tonesPerOctave button selected
  self.whiteBlackLayoutButton.enabled = NO;
    // force grid selection if not a custom tone but whiteBlack still selected
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    self.whiteBlackLayoutButton.selected = NO;
    _keyboardStyle = @"grid";
    self.gridLayoutButton.selected = YES;
    [self uncoverPicker:self.gridIntervalPicker];
  }
}

-(void)determineFifthWheelButtonEnabled {
  self.fifthWheelColourButton.enabled = NO;
    // force stepwise selection ONLY if not relative prime and fifthWheel still selected
    // 24 is only custom button that is not relative prime
  if ([@[@4, @6, @10, @14, @15, @20, @21, @24, @25, @28, @30, @34, @35, @36, @38, @44, @48]
       containsObject:[NSNumber numberWithUnsignedInteger:_tonesPerOctave ]]) {
    self.fifthWheelColourButton.enabled = NO;
    if ([_colourStyle isEqualToString:@"fifthWheel"]) {
      self.fifthWheelColourButton.selected = NO;
      _colourStyle = @"stepwise";
      self.stepwiseColourButton.selected = YES;
    }
  } else {
    self.fifthWheelColourButton.enabled = YES;
  }
}

-(UIView *)createAndAddCoverToPicker:(UIPickerView *)picker {
  UIView *cover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, picker.frame.size.width, picker.frame.size.height)];
  cover.backgroundColor = _pickerCoverColour;
  [picker addSubview:cover];
  return cover;
}

-(void)coverPicker:(UIPickerView *)picker {
  picker.userInteractionEnabled = NO;
  if (picker == self.gridIntervalPicker) {
    [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
      _gridPickerCover.hidden = NO;
      _gridPickerCover.alpha = 1.f;
    } completion:^(BOOL finished) {
      [picker reloadAllComponents];
    }];
  } else if (picker == self.colourPicker) {
    [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
      _colourPickerCover.hidden = NO;
      _colourPickerCover.alpha = 1.f;
    } completion:^(BOOL finished) {
      [picker reloadAllComponents];
    }];
  }
}

-(void)uncoverPicker:(UIPickerView *)picker {
  picker.userInteractionEnabled = YES;
  if (picker == self.gridIntervalPicker) {
    [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
      _gridPickerCover.alpha = 0.1f;
    } completion:^(BOOL finished) {
      _gridPickerCover.hidden = YES;
      [picker reloadAllComponents];
    }];
  } else if (picker == self.colourPicker) {
    [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
      _colourPickerCover.alpha = 0.1f;
    } completion:^(BOOL finished) {
      _colourPickerCover.hidden = YES;
      [picker reloadAllComponents];
    }];
  }
}

#pragma mark - picker view methods

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return 24.f;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  if (pickerView == self.tonesPerOctavePicker) {
    return 48 - 1;
  } else if (pickerView == self.gridIntervalPicker) {
  return _tonesPerOctave;
  } else if (pickerView == self.colourPicker) {
    return 100000;
  }
  return 0;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
  if (pickerView == self.colourPicker) {
    UIView *thisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 24)];
    if (_colourPickerCover.isHidden) {
      thisView.backgroundColor = [UIColor findNormalKeyColour:((row % _coloursInPicker) / (CGFloat)_coloursInPicker) withMinBright:0.45f];
    } else {
      thisView.backgroundColor = [UIColor findNormalKeyColour:((row % _coloursInPicker) / (CGFloat)_coloursInPicker) withMinBright:0.7f];
    }
    thisView.layer.borderColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.25f alpha:1.f].CGColor;
    thisView.layer.borderWidth = 1.f;
    return thisView;

  } else {
    UIView *thisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 24)];
    UILabel *label = [[UILabel alloc] initWithFrame:thisView.frame];
    label.center = thisView.center;
    label.textAlignment = NSTextAlignmentCenter;
    [thisView addSubview:label];
    if (pickerView == self.tonesPerOctavePicker) {
      label.text = [NSString stringWithFormat:@"%@", _pickerTones[row]];
    } else if (pickerView == self.gridIntervalPicker) {
      label.text = [NSString stringWithFormat:@"%i", row + 1];
    }
    if (pickerView == self.gridIntervalPicker && !_gridPickerCover.isHidden) {
      label.textColor = [UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:0.9f];
    } else {
      label.textColor = [UIColor blackColor];
    }
    return thisView;

  }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  if (pickerView == self.tonesPerOctavePicker) {
    _changesMade = YES;
    _tonesPerOctave = row + 2;
    [self presentTonesPickerState];
      // choice of tones per interval also affects grid interval picker
      [self presentGridPickerState];
  } else if (pickerView == self.gridIntervalPicker) {
    _changesMade = YES;
    _gridInterval = row + 1;
  } else if (pickerView == self.colourPicker) {
    _changesMade = YES;
    _rootColourWheelPosition = row % _coloursInPicker;
  }
}

#pragma mark - app methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
