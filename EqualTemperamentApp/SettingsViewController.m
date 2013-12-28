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

  NSArray *_tonesPerOctaveButtons;
  NSArray *_pickerTones;
  NSArray *_instrumentButtons;
  NSArray *_keyCharacterButtons;
  NSArray *_keyboardStyleButtons;
  NSArray *_colourStyleButtons;
  NSArray *_userButtons;
  NSArray *_keySizeButtons;
  NSArray *_allButtonArrays;
  NSArray *_allPickers;
  
  NSUInteger _rootColourWheelPosition;
  NSUInteger _tonesPerOctave;
  NSString *_instrument;
  NSString *_keyboardStyle;
  NSUInteger _gridInterval;
  NSString *_colourStyle;
  NSString *_keyCharacter;
  NSString *_userButtonsPosition;
  NSString *_keySize;
  
  CGFloat _pickerRowHeight;
  NSUInteger _coloursInPicker;
  
  UIView *_theView;
  CGFloat _screenWidth;
  CGFloat _screenHeight;
  CGFloat _viewSectionWidth;
  CGFloat _marginAroundTheView;
}

#pragma mark - init methods

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
//    self.modalPresentationStyle = UIModalTransitionStyleFlipHorizontal;
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  _coloursInPicker = 24;
  
  _screenWidth = [UIScreen mainScreen].bounds.size.height;
  _screenHeight = [UIScreen mainScreen].bounds.size.width;
  self.view.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
  
  _changesMade = YES; // to ensure view is loaded upon initial launch
  [self presentSettingsViewBasedOnDataModel];
}

-(void)presentSettingsViewBasedOnDataModel {
  if (_changesMade) {
    [self layoutTheView];
    _tonesPerOctave = [self.dataModel.tonesPerOctave unsignedIntegerValue];
    _instrument = self.dataModel.instrument;
    _keyCharacter = self.dataModel.keyCharacter;
    _keyboardStyle = self.dataModel.keyboardStyle;
    _gridInterval = [self.dataModel.gridInterval unsignedIntegerValue];
    _colourStyle = self.dataModel.colourStyle;
    _rootColourWheelPosition = [self.dataModel.rootColourWheelPosition unsignedIntegerValue];
    _userButtonsPosition = self.dataModel.userButtonsPosition;
    _keySize = self.dataModel.keySize;
    
    [self layoutLabels];
    [self layoutPickers];
    [self layoutButtons];
    [self establishAllPositions];
    [self layoutCovers];
    [self presentState];
    _changesMade = NO;
  }
}

-(void)layoutTheView {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _theView = self.view;
  } else { // iPad
    self.view.backgroundColor = [UIColor clearColor];
    self.view.userInteractionEnabled = YES;
    self.iPadPopupView.frame = CGRectMake(0, 0, _screenWidth * 2/3.f, _screenHeight * 3/5.f);
    _theView = self.iPadPopupView;
    [self.view addSubview:_theView];
    _theView.center = self.view.center;
    _theView.layer.cornerRadius = 10.f;
  }
  
  _theView.backgroundColor = [UIColor lightYellowSettingsBackground];
  
    // lay out sections of views
  _marginAroundTheView = 10.f;
  NSUInteger numberOfViewSections;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    numberOfViewSections = 3;
  } else { // iPad
    numberOfViewSections = 3;
  }
  _viewSectionWidth = (_theView.frame.size.width - (_marginAroundTheView * 2)) / numberOfViewSections;
  for (NSUInteger i = 0; i < numberOfViewSections; i++) {
    UIView *viewSection = [[UIView alloc] initWithFrame:CGRectMake(_marginAroundTheView + (_viewSectionWidth * i), _marginAroundTheView, _viewSectionWidth, _theView.frame.size.height - (_marginAroundTheView * 2))];
    if (i % 2 == 0) {
      viewSection.backgroundColor = [UIColor lightYellowSettingsBackground];
    } else {
      viewSection.backgroundColor = [UIColor lighterYellowSettingsBackground];
      
      UIColor *outerColour = [UIColor lightYellowSettingsBackground];
      UIColor *innerColour = [UIColor lighterYellowSettingsBackground];
      CAGradientLayer *gradientLayer = [CAGradientLayer layer];
      gradientLayer.frame = viewSection.layer.bounds;
      gradientLayer.colors = @[(id)outerColour.CGColor, (id)innerColour.CGColor, (id)innerColour.CGColor, (id)outerColour.CGColor];
      gradientLayer.locations = @[@0.0f, @0.1f, @0.9f, @1.f];
      [viewSection.layer addSublayer:gradientLayer];
    }
    [_theView addSubview:viewSection];
  }
}

-(void)layoutLabels {
  self.octaveLabel = [[UIButton alloc] init];
  self.octaveLabel.userInteractionEnabled = NO;
  [self.octaveLabel setImage:[UIImage imageNamed:@"OctaveLabel"] forState:UIControlStateNormal];
  [_theView addSubview:self.octaveLabel];
  self.rootColourLabel = [[UIButton alloc] init];
  self.rootColourLabel.userInteractionEnabled = NO;
  [self.rootColourLabel setImage:[UIImage imageNamed:@"RootColourLabel"] forState:UIControlStateNormal];
  [self.rootColourLabel setImage:[UIImage imageNamed:@"RootColourLabelDisabled"] forState:UIControlStateDisabled];
  [_theView addSubview:self.rootColourLabel];
  self.gridButtonLabel = [[UIButton alloc] init];
  self.gridButtonLabel.userInteractionEnabled = NO;
  [self.gridButtonLabel setImage:[UIImage imageNamed:@"GridButtonLabel"] forState:UIControlStateNormal];
  [self.gridButtonLabel setImage:[UIImage imageNamed:@"GridButtonLabelDisabled"] forState:UIControlStateDisabled];
  [_theView addSubview:self.gridButtonLabel];
}

-(void)layoutPickers {
  _pickerRowHeight = 24.f;
  self.tonesPerOctavePicker = [[UIPickerView alloc] init];
  self.colourPicker = [[UIPickerView alloc] init];
  self.gridIntervalPicker = [[UIPickerView alloc] init];
  
  _allPickers = @[self.tonesPerOctavePicker, self.colourPicker, self.gridIntervalPicker];
  
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
  });
  
  dispatch_async(dispatch_get_main_queue(), ^{
    self.colourPicker.delegate = self;
    [self.colourPicker selectRow:_rootColourWheelPosition + (_coloursInPicker * 2000) inComponent:0 animated:NO];
  });
}

-(void)layoutButtons {
    // can't instantiate through fast enumeration
  self.twelveButton = [[UIButton alloc] init];
  self.seventeenButton = [[UIButton alloc] init];
  self.nineteenButton = [[UIButton alloc] init];
  self.twentyFourButton = [[UIButton alloc] init];
  self.thirtyOneButton = [[UIButton alloc] init];
  self.fortyOneButton = [[UIButton alloc] init];
  self.numberedKeyButton = [[UIButton alloc] init];
  self.blankKeyButton = [[UIButton alloc] init];
  self.whiteBlackLayoutButton = [[UIButton alloc] init];
  self.gridLayoutButton = [[UIButton alloc] init];
  self.fifthWheelColourButton = [[UIButton alloc] init];
  self.stepwiseColourButton = [[UIButton alloc] init];
  self.noColourButton = [[UIButton alloc] init];
  self.userButtonsBottomLeftButton = [[UIButton alloc] init];
  self.userButtonsBottomRightButton = [[UIButton alloc] init];
  self.smallKeysButton = [[UIButton alloc] init];
  self.bigKeysButton = [[UIButton alloc] init];
  self.saveButton = [[UIButton alloc] init];
  
  _tonesPerOctaveButtons = @[self.twelveButton, self.seventeenButton, self.nineteenButton,
                             self.twentyFourButton, self.thirtyOneButton, self.fortyOneButton];
  _keyCharacterButtons = @[self.blankKeyButton, self.numberedKeyButton];
  _keyboardStyleButtons = @[self.gridLayoutButton, self.whiteBlackLayoutButton];
  _colourStyleButtons = @[self.noColourButton, self.stepwiseColourButton, self.fifthWheelColourButton];
  _userButtons = @[self.userButtonsBottomLeftButton, self.userButtonsBottomRightButton];
  _keySizeButtons = @[self.smallKeysButton, self.bigKeysButton];
  _allButtonArrays = @[_tonesPerOctaveButtons, _keyCharacterButtons, _keyboardStyleButtons,
                       _colourStyleButtons, _userButtons, _keySizeButtons];
  
  NSArray *tonesPerOctaveImages = @[@"TwelveButton", @"SeventeenButton", @"NineteenButton",
                                    @"TwentyFourButton", @"ThirtyOneButton", @"FortyOneButton"];
  NSArray *keyCharacterImages = @[@"BlankKeyButton", @"NumberedKeyButton"];
  NSArray *keyboardStyleImages = @[@"GridButton", @"WhiteBlackButton"];
  NSArray *colourStyleImages = @[@"NoColourButton", @"StepwiseButton", @"FifthWheelButton"];
  NSArray *userButtonImages = @[@"BottomLeftButton", @"BottomRightButton"];
  NSArray *keySizeImages = @[@"SmallKeysButton", @"BigKeysButton"];
  NSArray *allButtonImages = @[tonesPerOctaveImages, keyCharacterImages, keyboardStyleImages, colourStyleImages,
                               userButtonImages, keySizeImages];
  
  NSArray *tonesPerOctaveImagesSelected = @[@"TwelveButtonSelected", @"SeventeenButtonSelected", @"NineteenButtonSelected",
                                    @"TwentyFourButtonSelected", @"ThirtyOneButtonSelected", @"FortyOneButtonSelected"];
  NSArray *keyCharacterImagesSelected = @[@"BlankKeyButtonSelected", @"NumberedKeyButtonSelected"];
  NSArray *keyboardStyleImagesSelected = @[@"GridButtonSelected", @"WhiteBlackButtonSelected"];
  NSArray *colourStyleImagesSelected = @[@"NoColourButtonSelected", @"StepwiseButtonSelected", @"FifthWheelButtonSelected"];
  NSArray *userButtonImagesSelected = @[@"BottomLeftButtonSelected", @"BottomRightButtonSelected"];
  NSArray *keySizeImagesSelected = @[@"SmallKeysButtonSelected", @"BigKeysButtonSelected"];
  NSArray *allButtonImagesSelected = @[tonesPerOctaveImagesSelected, keyCharacterImagesSelected, keyboardStyleImagesSelected,
                                       colourStyleImagesSelected, userButtonImagesSelected, keySizeImagesSelected];
  
  for (NSArray *buttonsArray in _allButtonArrays) {
    NSUInteger arrayIndex = [_allButtonArrays indexOfObject:buttonsArray];
    for (UIButton *button in buttonsArray) {
      NSUInteger buttonIndex = [buttonsArray indexOfObject:button];
      UIImage *buttonImage = [UIImage imageNamed:allButtonImages[arrayIndex][buttonIndex]];
      UIImage *buttonImageSelected = [UIImage imageNamed:allButtonImagesSelected[arrayIndex][buttonIndex]];
      [button addTarget:self action:@selector(musicButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
      [button setImage:buttonImage forState:UIControlStateNormal];
      [button setImage:buttonImageSelected forState:UIControlStateSelected];
      [_theView addSubview:button];
    }
  }
  [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.saveButton setImage:[UIImage imageNamed:@"SaveButton"] forState:UIControlStateNormal];
  [self.saveButton setImage:[UIImage imageNamed:@"SaveButtonHighlighted"] forState:UIControlStateHighlighted];
  [_theView addSubview:self.saveButton];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    self.smallKeysButton.hidden = YES;
    self.bigKeysButton.hidden = YES;
    self.userButtonsBottomLeftButton.hidden = YES;
    self.userButtonsBottomRightButton.hidden = YES;
    self.numberedKeyButton.hidden = YES;
    self.blankKeyButton.hidden = YES;
  }
}

-(void)layoutCovers {
    // label covers
  self.rootColourLabelCover = [self createAndAddCoverToView:self.rootColourLabel
                                       withBackgroundColour:[UIColor lighterYellowPickerCover]];
  
  UIColor *outerColour = [UIColor lightYellowPickerCover];
  UIColor *innerColour = [UIColor lighterYellowPickerCover];
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.frame = self.rootColourLabelCover.layer.bounds;
  gradientLayer.colors = @[(id)outerColour.CGColor, (id)innerColour.CGColor, (id)innerColour.CGColor];
  gradientLayer.locations = @[@0.0f, @0.4285f, @1.f];
  self.rootColourLabelCover.backgroundColor = [UIColor clearColor];
  [self.rootColourLabelCover.layer addSublayer:gradientLayer];
  
  
  self.gridIntervalLabelCover = [self createAndAddCoverToView:self.gridButtonLabel
                                         withBackgroundColour:[UIColor lightYellowPickerCover]];
  
  if ([_colourStyle isEqualToString:@"noColour"]) {
    self.rootColourLabelCover.hidden = NO;
    self.rootColourLabel.enabled = NO;
  } else {
    self.rootColourLabelCover.hidden = YES;
    self.rootColourLabel.enabled = YES;
  }
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    self.gridIntervalLabelCover.hidden = NO;
    self.gridButtonLabel.enabled = NO;
  } else {
    self.gridIntervalLabelCover.hidden = YES;
    self.gridButtonLabel.enabled = YES;
  }
  
    // picker covers
  self.gridPickerCover = [self createAndAddCoverToView:self.gridIntervalPicker withBackgroundColour:[UIColor lightYellowPickerCover]];
  self.colourPickerCover = [self createAndAddCoverToView:self.colourPicker withBackgroundColour:[UIColor lighterYellowPickerCover]];
  
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    self.gridPickerCover.hidden = NO;
  } else {
    self.gridPickerCover.hidden = YES;
  }
  if ([_colourStyle isEqualToString:@"noColour"]) {
    self.colourPickerCover.hidden = NO;
  } else {
    self.colourPickerCover.hidden = YES;
  }
  
    // button covers
  self.whiteBlackButtonCover = [self createAndAddCoverToView:self.whiteBlackLayoutButton withBackgroundColour:[UIColor lightYellowPickerCover]];
  self.fifthWheelButtonCover = [self createAndAddCoverToView:self.fifthWheelColourButton withBackgroundColour:[UIColor lighterYellowPickerCover]];
    // whether they are hidden or not ultimately gets established during presentState method
  self.fifthWheelButtonCover.hidden = YES;
  self.whiteBlackButtonCover.hidden = YES;
}

-(void)establishAllPositions {
  CGFloat topPadding;
  CGFloat labelOriginY;
  CGFloat labelHeight;
  CGFloat gridLabelMinusXPadding;
  CGFloat pickerOriginY;
  CGFloat pickerWidth;
  CGFloat saveButtonWidth;
  CGFloat saveButtonOriginY;
  CGFloat narrowButtonSize;
  CGFloat wideButtonSize;
  CGFloat evenWiderButtonSize;
  NSArray *viewSectionXForButtons;
  NSArray *originYForButtons;
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    topPadding = 0.f;
    labelOriginY = 10.f;
    labelHeight = 70.f;
    gridLabelMinusXPadding = 57.f;
    pickerOriginY = 76.f;
    pickerWidth = 80.f;
    saveButtonWidth = 85.f;
    saveButtonOriginY = 247.f;
      // tonesPerOctave, keyCharacter, keyboardStyle, colourStyle, userButtons, keySize
    narrowButtonSize = 48.f;
    wideButtonSize = 54.f;
    viewSectionXForButtons = @[@0, @0, @2, @1, @0, @0];
    originYForButtons = @[@223.f, @0.f, @16.f, @247.f, @0.f, @0.f];
  } else { // iPad
    topPadding = 10.f;
    labelOriginY = 10.f;
    labelHeight = 70.f;
    gridLabelMinusXPadding = 57.f;
    pickerOriginY = 86.f;
    pickerWidth = 80.f;
    saveButtonWidth = 85.f;
    saveButtonOriginY = 389.f;
      // tonesPerOctave, keyCharacter, keyboardStyle, colourStyle, userButtons, keySize
    narrowButtonSize = 48.f;
    wideButtonSize = 54.f;
    evenWiderButtonSize = 60.f;
    viewSectionXForButtons = @[@0, @0, @2, @1, @1, @2];
    originYForButtons = @[@243.f, @381.f, @16.f, @267.f, @381.f, @267.f];
  }
  
    // frames
  self.octaveLabel.frame = CGRectMake(_marginAroundTheView, topPadding + labelOriginY, _viewSectionWidth, labelHeight);
  self.rootColourLabel.frame = CGRectMake(_marginAroundTheView + _viewSectionWidth, topPadding + labelOriginY, _viewSectionWidth, labelHeight);
  self.gridButtonLabel.frame = CGRectMake(_marginAroundTheView + (_viewSectionWidth * 2.5f) - gridLabelMinusXPadding, topPadding + 23.f, 20.f, labelHeight);
  
    // pickers and dividers
  for (int i = 0; i < [_allPickers count]; i++) {
    UIPickerView *thisPicker = _allPickers[i];
    thisPicker.frame = CGRectMake(_marginAroundTheView + (_viewSectionWidth * i) + ((_viewSectionWidth - pickerWidth) / 2),
                                  topPadding + pickerOriginY, pickerWidth, 162.f);
    [_theView insertSubview:thisPicker belowSubview:self.rootColourLabel];
    
    UIImageView *divider;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
      if (i % 2 == 0) {
        divider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DividerLighterYellow"]];
      } else {
        divider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DividerLightYellow"]];
      }
      divider.contentMode = UIViewContentModeCenter;
      divider.frame = CGRectMake(_marginAroundTheView + (_viewSectionWidth * i), 350.f, _viewSectionWidth, 30.f);
      [_theView addSubview:divider];
    }
  }
  
    // layout buttons
  for (NSArray *buttonsArray in _allButtonArrays) {
    NSUInteger arrayIndex = [_allButtonArrays indexOfObject:buttonsArray];
    NSUInteger numberOfButtons = [buttonsArray count];
    for (NSUInteger buttonIndex = 0; buttonIndex < numberOfButtons; buttonIndex++) {
      UIButton *thisButton = buttonsArray[buttonIndex];
//      thisButton.layer.borderColor = [UIColor blackColor].CGColor;
//      thisButton.layer.borderWidth = 1.f;
      
      NSUInteger numberInRow = numberOfButtons;
      if (numberOfButtons > 3) {
        numberInRow = numberOfButtons / 2;
      }
      NSUInteger buttonSize;
      if (numberInRow >= 3 || buttonsArray == _keyCharacterButtons) {
        buttonSize = narrowButtonSize;
      } else if (buttonsArray == _keySizeButtons || buttonsArray == _userButtons) {
        buttonSize = evenWiderButtonSize;
      } else {
        buttonSize = wideButtonSize;
      }
      CGFloat nextRowY = 0.f;
      if (buttonIndex >= numberOfButtons / 2 && numberOfButtons > 3) {
        nextRowY = buttonSize;
      }
      NSUInteger viewSectionMultiplierX = [viewSectionXForButtons[arrayIndex] unsignedIntegerValue];
      CGFloat originX = _marginAroundTheView + (_viewSectionWidth * viewSectionMultiplierX) +
        ((_viewSectionWidth - (buttonSize * numberInRow)) / 2.f) +
        (buttonSize * (buttonIndex % numberInRow));
      CGFloat originY = [originYForButtons[arrayIndex] floatValue];
      thisButton.frame = CGRectMake(originX, topPadding + originY + nextRowY, buttonSize, buttonSize);
    }
  }
  
    // layout save button
  self.saveButton.frame = CGRectMake(_marginAroundTheView + (_viewSectionWidth * 2) + ((_viewSectionWidth - saveButtonWidth) / 2.f), topPadding + saveButtonOriginY, saveButtonWidth, 48.f);
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
          if (self.whiteBlackLayoutButton.enabled == NO) {
            self.whiteBlackLayoutButton.enabled = YES;
            [self uncoverView:self.whiteBlackLayoutButton fromCover:_whiteBlackButtonCover];
          }
          
          [self.tonesPerOctavePicker selectRow:(_tonesPerOctave - 2) inComponent:0 animated:YES];
          [self presentGridPickerBasedOnLatestChange];
        } else {
          button.selected = NO;
        }
      }
    }
    [self determineWhetherToEnableFifthWheelButton];
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
        [self coverView:self.gridIntervalPicker withCover:self.gridPickerCover];
        [self coverView:self.gridButtonLabel withCover:self.gridIntervalLabelCover];
        self.gridButtonLabel.enabled = NO;
      }
    } else if (sender == self.gridLayoutButton) {
      if (![_keyboardStyle isEqualToString:@"grid"]) {
        _keyboardStyle = @"grid";
        _changesMade = YES;
        [self uncoverView:self.gridIntervalPicker fromCover:self.gridPickerCover];
        [self uncoverView:self.gridButtonLabel fromCover:self.gridIntervalLabelCover];
        self.gridButtonLabel.enabled = YES;
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
        [self uncoverView:self.colourPicker fromCover:_colourPickerCover];
        [self uncoverView:self.rootColourLabel fromCover:self.rootColourLabelCover];
        _rootColourLabel.enabled = YES;
      }
    } else if (sender == self.stepwiseColourButton) {
      if (![_colourStyle isEqualToString:@"stepwise"]) {
        _colourStyle = @"stepwise";
        _changesMade = YES;
        [self uncoverView:self.colourPicker fromCover:_colourPickerCover];
        [self uncoverView:self.rootColourLabel fromCover:self.rootColourLabelCover];
        _rootColourLabel.enabled = YES;
      }
    } else if (sender == self.noColourButton) {
      if (![_colourStyle isEqualToString:@"noColour"]) {
        _colourStyle = @"noColour";
        _changesMade = YES;
        [self coverView:self.colourPicker withCover:_colourPickerCover];
        [self coverView:self.rootColourLabel withCover:self.rootColourLabelCover];
        _rootColourLabel.enabled = NO;
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
    if (sender == self.userButtonsBottomRightButton) {
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
  
  if ([_keySizeButtons containsObject:sender]) {
    if (sender == self.smallKeysButton) {
      if (![_keySize isEqualToString:@"smallKeys"]) {
        _keySize = @"smallKeys";
        _changesMade = YES;
      }
    } else if (sender == self.bigKeysButton) {
      if (![_keySize isEqualToString:@"bigKeys"]) {
        _keySize = @"bigKeys";
        _changesMade = YES;
      }
    }
    if (_changesMade) {
      for (UIButton *button in _keySizeButtons) {
        if (button == sender) {
          button.selected = YES;
        } else {
          button.selected = NO;
        }
      }
    }
  }
}

-(void)saveButtonTapped {
  if (_changesMade) {
    self.dataModel.tonesPerOctave = [NSNumber numberWithUnsignedInteger:_tonesPerOctave ];
    self.dataModel.instrument = _instrument;
    self.dataModel.keyCharacter = _keyCharacter;
    self.dataModel.keyboardStyle = _keyboardStyle;
    self.dataModel.colourStyle = _colourStyle;
    self.dataModel.rootColourWheelPosition = [NSNumber numberWithUnsignedInteger:_rootColourWheelPosition];
    self.dataModel.userButtonsPosition = _userButtonsPosition;
    self.dataModel.gridInterval = [NSNumber numberWithUnsignedInteger:_gridInterval];
    self.dataModel.keySize = _keySize;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone || [_keyboardStyle isEqualToString:@"whiteBlack"]) {
      [self.delegate updateKeyboardWithChangedDataModel:self.dataModel];      
    } else { // iPad
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate updateKeyboardWithChangedDataModel:self.dataModel];
      });
    }
  }
  _changesMade = NO;
  [self returnToParentViewController];
}

-(void)returnToParentViewController {
  [self.delegate hideStatusBar:NO];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  } else { // iPad
    [self.delegate removeDarkOverlay];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
  }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    UITouch *touch = touches.anyObject;
    if (touch.view == self.view) {
      [self returnToParentViewController];
    }
  }
    // does not affect changesMade; this gets checked the next time settingsVC is presented
    // to determine whether view needs to be reloaded after closing without saving
}

#pragma mark - change view state methods

-(void)presentState {
  [self presentTonesButtonsBasedOnLatestChange];
  
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
  if ([_userButtonsPosition isEqualToString:@"bottomRight"]) {
    tempUserButton = self.userButtonsBottomRightButton;
  } else if ([_userButtonsPosition isEqualToString:@"bottomLeft"]) {
    tempUserButton = self.userButtonsBottomLeftButton;
  }
  
  UIButton *tempKeySizeButton;
  if ([_keySize isEqualToString:@"smallKeys"]) {
    tempKeySizeButton = self.smallKeysButton;
  } else if ([_keySize isEqualToString:@"bigKeys"]) {
    tempKeySizeButton = self.bigKeysButton;
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
  for (UIButton *button in _keySizeButtons) {
    if (button == tempKeySizeButton) {
      button.selected = YES;
    } else {
      button.selected = NO;
    }
  }
}

-(void)presentGridPickerBasedOnLatestChange {
  NSUInteger perfectFourth = _tonesPerOctave - [self.delegate findPerfectFifthWithTonesPerOctave:_tonesPerOctave];
  _gridInterval = perfectFourth;
  [self.gridIntervalPicker reloadAllComponents];
  [self.gridIntervalPicker selectRow:perfectFourth - 1 inComponent:0 animated:YES];
}

-(void)presentTonesButtonsBasedOnLatestChange {
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
      if (self.whiteBlackLayoutButton.enabled == NO) {
        self.whiteBlackLayoutButton.enabled = YES;
        [self uncoverView:self.whiteBlackLayoutButton fromCover:self.whiteBlackButtonCover];
      }
    } else {
      button.selected = NO;
    }
  }
  [self determineWhetherToEnableFifthWheelButton];
}

-(void)disableWhiteBlackButtonAndForceGrid {
    // no custom tonesPerOctave button selected
  self.whiteBlackLayoutButton.enabled = NO;
  [self coverView:self.whiteBlackLayoutButton withCover:self.whiteBlackButtonCover];
    // force grid selection if not a custom tone but whiteBlack still selected
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    self.whiteBlackLayoutButton.selected = NO;
    _keyboardStyle = @"grid";
    self.gridLayoutButton.selected = YES;
    [self uncoverView:self.gridIntervalPicker fromCover:self.gridPickerCover];
    [self uncoverView:self.gridButtonLabel fromCover:self.gridIntervalLabelCover];
    self.gridButtonLabel.enabled = YES;
  }
}

-(void)determineWhetherToEnableFifthWheelButton {
    // force stepwise selection ONLY if not relative prime and fifthWheel still selected
    // 24 is only custom button that is not relative prime
  if ([@[@4, @6, @10, @14, @15, @20, @21, @24, @25, @28, @30, @34, @35, @36, @38, @44, @48]
       containsObject:[NSNumber numberWithUnsignedInteger:_tonesPerOctave]]) {
    self.fifthWheelColourButton.enabled = NO;
    [self coverView:self.fifthWheelColourButton withCover:self.fifthWheelButtonCover];
    if ([_colourStyle isEqualToString:@"fifthWheel"]) {
      self.fifthWheelColourButton.selected = NO;
      _colourStyle = @"stepwise";
      self.stepwiseColourButton.selected = YES;
    }
  } else {
    self.fifthWheelColourButton.enabled = YES;
    [self uncoverView:self.fifthWheelColourButton fromCover:self.fifthWheelButtonCover];
  }
}

#pragma mark - cover methods

-(UIView *)createAndAddCoverToView:(UIView *)thisView withBackgroundColour:(UIColor *)colour {
  UIView *cover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thisView.frame.size.width, thisView.frame.size.height)];
  cover.backgroundColor = colour;
//  cover.layer.borderColor = [UIColor blackColor].CGColor;
//  cover.layer.borderWidth = 1.f;
  [thisView addSubview:cover];
  return cover;
}

-(void)coverView:(UIView *)thisView withCover:(UIView *)cover {
  thisView.userInteractionEnabled = NO;
  cover.hidden = NO;
  [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
    cover.alpha = 1.f;
    } completion:^(BOOL finished) {
//    if ([thisView isKindOfClass:[UIPickerView class]]) {
//      [(UIPickerView *)thisView reloadAllComponents];
//    }
  }];
}

-(void)uncoverView:(UIView *)thisView fromCover:(UIView *)cover {
  thisView.userInteractionEnabled = YES;
  [UIView animateWithDuration:0.15f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
    cover.alpha = 0.f;
  } completion:^(BOOL finished) {
    cover.hidden = YES;
    if ([thisView isKindOfClass:[UIPickerView class]]) {
      [(UIPickerView *)thisView reloadAllComponents];
    }
  }];
}

#pragma mark - picker view methods

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return _pickerRowHeight;
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
    UIView *thisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, _pickerRowHeight)];
    if (_colourPickerCover.isHidden) {
      thisView.backgroundColor = [UIColor findNormalKeyColour:((row % _coloursInPicker) / (CGFloat)_coloursInPicker) withMinBright:0.45f];
    } else {
      thisView.backgroundColor = [UIColor findNormalKeyColour:((row % _coloursInPicker) / (CGFloat)_coloursInPicker) withMinBright:0.7f];
    }
    thisView.layer.borderColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.25f alpha:1.f].CGColor;
    thisView.layer.borderWidth = 1.f;
    return thisView;

  } else {
    UIView *thisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, _pickerRowHeight)];
    UILabel *label = [[UILabel alloc] initWithFrame:thisView.frame];
    label.center = thisView.center;
    label.textAlignment = NSTextAlignmentCenter;
    [thisView addSubview:label];
    if (pickerView == self.tonesPerOctavePicker) {
      label.text = [NSString stringWithFormat:@"%@", _pickerTones[row]];
    } else if (pickerView == self.gridIntervalPicker) {
      label.text = [NSString stringWithFormat:@"%i", row + 1];
    }
    if (pickerView == self.gridIntervalPicker && !self.gridPickerCover.isHidden) {
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
    [self presentTonesButtonsBasedOnLatestChange];
      // choice of tones per interval also affects grid interval picker
    [self presentGridPickerBasedOnLatestChange];
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

-(BOOL)prefersStatusBarHidden {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    return YES;
  } else { // iPad
    return YES;
  }
}

@end
