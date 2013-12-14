//
//  KeyboardViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyboardViewController.h"
#import "HelpViewController.h"
#import "mo_audio.h"
#import "DataModel.h"
#import "Key.h"

#define SRATE 44100
#define FRAMESIZE 128
#define NUMCHANNELS 2

  // fine-tune these as necessary
const CGFloat marginSide = 4.f;
const CGFloat marginTop = 20.f; // or the height of status bar
const CGFloat marginBetweenKeys = 1.f;
const CGFloat whiteKeyHeight = 240.f;
const CGFloat whiteBlackWhiteKeyWidth = 60.f;
const CGFloat justWhiteKeyWidth = 48.f;
const CGFloat gridKeyWidth = 54.f;

const CGFloat buttonSize = 44.f;
const CGFloat marginBetweenButtons = 5.f;

void audioCallback(Float32 *buffer, UInt32 framesize, void *userData) {
  AudioData *data = (AudioData *)userData;
  for(int i=0; i<framesize; i++) {
    SAMPLE out = data->myMandolin->tick();
    buffer[2*i] = buffer[2*i+1] = out;
  }
}

@interface KeyboardViewController () <UIScrollViewDelegate> {
  struct AudioData audioData;
}
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) DataModel *dataModel;

@end

@implementation KeyboardViewController {
  NSUInteger _numberOfOctaves;
  NSUInteger _totalKeysInKeyboard;
  NSUInteger _perfectFifth;
  
  NSUInteger _tonesPerOctave;
  NSString *_instrument;
  NSString *_keyCharacter;
  NSString *_keyboardStyle;
  NSString *_colourStyle;
  NSString *_userButtonsPosition;
  
  NSUInteger _gridInterval;
  NSUInteger _numberOfGridRows; // set this in viewDidLoad, as it's dependent on iPad or iPhone
  
  CGFloat _totalKeysPerGridRow;
  
  float _semitoneInterval;
  float _lowestTone;
  UIColor *_backgroundColour;
  
  NSArray *_theBlackKeys; // can't think of better way than to make this an instance variable
  NSArray *_initialExtraMultipliers; // same here
}

#pragma mark - view methods

-(void)viewDidLoad {
  _backgroundColour = [UIColor colorWithRed:.25f green:.25f blue:.25f alpha:1.f];
  [super viewDidLoad];
  
    // Bennett-tweaked constants
  _numberOfOctaves = 4;
  _lowestTone = 110.f;
  _numberOfGridRows = 3; // for now, but will change based on iPad or iPhone
  _gridInterval = 5; // for now, will later be based on user Input
  
    // instantiates self.dataModel only on very first launch
  NSString *path = [self dataFilePath];
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    [self loadSettingsFromPath:path];
  } else {
    self.dataModel = [[DataModel alloc] init];
    self.dataModel.tonesPerOctave = @12;
    self.dataModel.instrument = @"piano";
    self.dataModel.keyCharacter = @"numbered";
    self.dataModel.keyboardStyle = @"whiteBlack";
    self.dataModel.colourStyle = @"fifthWheel";
    self.dataModel.userButtonsPosition = @"bottomRight";
  }
  [self updateKeyboardWithChangedDataModel:self.dataModel];
  
  audioData.myMandolin = new Mandolin(20);
    // init the MoAudio layer
  MoAudio::init(SRATE, FRAMESIZE, NUMCHANNELS);
    // start the audio layer, registering a callback method
  MoAudio::start(audioCallback, &audioData);
  
//  NSLog(@"Documents folder is %@", [self documentsDirectory]);
//  NSLog(@"Data file path is %@", [self dataFilePath]);
}

#pragma mark - custom view methods

-(void)updateKeyboardWithChangedDataModel:(DataModel *)dataModel {
  if (self.scrollView) {
    [self.scrollView removeFromSuperview];
  }
  _tonesPerOctave = [self.dataModel.tonesPerOctave integerValue];
  _instrument = self.dataModel.instrument;
  _keyCharacter = self.dataModel.keyCharacter;
  _keyboardStyle = self.dataModel.keyboardStyle;
  _colourStyle = self.dataModel.colourStyle;
  _userButtonsPosition = self.dataModel.userButtonsPosition;
  
  [self saveSettings];
  [self establishValuesFromTonesPerOctave];
  [self placeScrollView];
  [self layoutKeysBasedOnKeyboardStyle];
  [self layoutUserButtons];
}

-(void)placeScrollView {
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
  self.scrollView.backgroundColor = _backgroundColour;
  CGFloat keyWidth = 0;
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    keyWidth = whiteBlackWhiteKeyWidth;
  } else if ([_keyboardStyle isEqualToString:@"justWhite"]) {
    keyWidth = justWhiteKeyWidth;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    keyWidth = gridKeyWidth;
  }
  
  NSUInteger numberOfKeysMultiplier = 0;
  NSArray *customTonesPerOctave = @[@5, @7, @12, @15, @17, @19, @22, @24, @31];
  NSArray *whiteTonesPerOctave = @[@3, @4, @7, @7, @7, @7, @7, @7, @7];
  NSNumber *tonesPerOctaveObject = [NSNumber numberWithInteger:_tonesPerOctave];
  if ([_keyboardStyle isEqualToString:@"whiteBlack"] &&
      [customTonesPerOctave containsObject:tonesPerOctaveObject]) {
    NSInteger row = [customTonesPerOctave indexOfObject:tonesPerOctaveObject];
    numberOfKeysMultiplier = ([whiteTonesPerOctave[row] unsignedIntegerValue] * _numberOfOctaves) + 1;
  } else if ([_keyboardStyle isEqualToString:@"justWhite"]) {
    numberOfKeysMultiplier = _totalKeysInKeyboard;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    _totalKeysPerGridRow = _totalKeysInKeyboard - (_gridInterval * (_numberOfGridRows - 1));
    numberOfKeysMultiplier = _totalKeysPerGridRow;
  }
  self.scrollView.contentSize = CGSizeMake((marginSide * 2) + (keyWidth * numberOfKeysMultiplier),
                                           self.scrollView.bounds.size.height);
  
  [self.scrollView setMultipleTouchEnabled:YES];
  UITapGestureRecognizer *multipleTapsRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keysPressed:)];
  [multipleTapsRecognizer setNumberOfTouchesRequired:2];
  [self.scrollView addGestureRecognizer:multipleTapsRecognizer];
  
  self.scrollView.delegate = self;
  [self.view addSubview:self.scrollView];
}

-(void)layoutKeysBasedOnKeyboardStyle {
    // nmsd means noModScaleDegree
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    [self layoutWhiteBlackKeyboardStyle];
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    [self layoutGridKeyboardStyle];
  }
}

-(void)layoutWhiteBlackKeyboardStyle {
      // first add white keys
  NSInteger whiteKeyCount = 0;
  for (NSInteger nmsd = 0; nmsd < _totalKeysInKeyboard; nmsd++) {
    NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
    if ([self isWhiteKeyGivenScaleDegree:scaleDegree]) {
      CGRect frame = CGRectMake(marginSide + (whiteKeyCount * whiteBlackWhiteKeyWidth), marginTop, whiteBlackWhiteKeyWidth, whiteKeyHeight);
      Key *thisKey = [[Key alloc] initWithFrame:frame
                               givenColourStyle:_colourStyle
                                andKeyCharacter:_keyCharacter
                                   andKeyHeight:1.f
                              andTonesPerOctave:_tonesPerOctave
                                andPerfectFifth:_perfectFifth
                                 andScaleDegree:scaleDegree];
      [self finalizeThisKey:thisKey withThisNoModScaleDegree:nmsd];
      whiteKeyCount++;
    }
  }
  
  _theBlackKeys = [self figureOutBlackKeys];
  _initialExtraMultipliers = [self figureOutInitialExtraMultipliers];
  
    // now add however many rows of black keys
  CGFloat blackKeyWidth = whiteBlackWhiteKeyWidth * 3/4;
  CGFloat blackKeyOffsetMultiplier;
  for (NSArray *thisBlackKeyRow in _theBlackKeys) {
    NSInteger blackKeyIndexRow = [_theBlackKeys indexOfObject:thisBlackKeyRow];
    CGFloat blackKeyType = [self getBlackKeyTypeGivenIndexRow:blackKeyIndexRow];
    NSLog(@"black key type is %f for row %i", blackKeyType, blackKeyIndexRow);
    CGFloat blackKeyHeightMultiplier = [self getBlackKeyHeightMultiplierGivenBlackKeyType:blackKeyType];
    CGFloat blackKeyHeight = blackKeyHeightMultiplier * whiteKeyHeight;
    NSLog(@"black Key height is %f", blackKeyHeight);
    
    if (blackKeyType == 11/18.f + 0.00001f) {
      blackKeyOffsetMultiplier = 1/2.f;
    } else {
      blackKeyOffsetMultiplier = blackKeyType;
    }
    CGFloat blackKeyOffset = blackKeyOffsetMultiplier * whiteBlackWhiteKeyWidth + 1.f;
    CGFloat initialExtraMultiplier = [_initialExtraMultipliers[blackKeyIndexRow] floatValue];
    NSInteger blackKeyCount = 0;
    CGFloat blackKeyGapSpace = 0;
    for (NSInteger nmsd = 0; nmsd < _totalKeysInKeyboard; nmsd++) {
      NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
      if ([thisBlackKeyRow containsObject:scaleDegree]) {
        CGRect frame = CGRectMake((initialExtraMultiplier * whiteBlackWhiteKeyWidth) + marginSide +
                                  ((whiteBlackWhiteKeyWidth - blackKeyWidth) / 2) + blackKeyOffset +
                                  (blackKeyCount * whiteBlackWhiteKeyWidth) + blackKeyGapSpace, marginTop,
                                  blackKeyWidth, blackKeyHeight);
        Key *thisKey = [[Key alloc] initWithFrame:frame
                                 givenColourStyle:_colourStyle
                                  andKeyCharacter:_keyCharacter
                                     andKeyHeight:blackKeyHeightMultiplier
                                andTonesPerOctave:_tonesPerOctave
                                  andPerfectFifth:_perfectFifth
                                   andScaleDegree:scaleDegree];
        [self finalizeThisKey:thisKey withThisNoModScaleDegree:nmsd];
        blackKeyCount++;
          // calculates the added gap space for the next black key
        CGFloat multiplier = [self getGapSizeGivenScaleDegree:scaleDegree];
        if (multiplier != 0.f) {
          blackKeyGapSpace += multiplier * whiteBlackWhiteKeyWidth;
        }
      }
    }
  }
}

-(void)layoutGridKeyboardStyle {

  CGFloat gridKeyHeight = whiteKeyHeight / _numberOfGridRows;
  for (int thisRow = 0; thisRow < _numberOfGridRows; thisRow++) {
    for (NSInteger nmsd = thisRow * _gridInterval; nmsd < _totalKeysInKeyboard - (_gridInterval * (_numberOfGridRows - (thisRow + 1))); nmsd++) {
      
      NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
      CGRect frame = CGRectMake(marginSide + ((nmsd - (_gridInterval * thisRow)) * gridKeyWidth),
                                 marginTop + (gridKeyHeight * (_numberOfGridRows - (thisRow + 1))), gridKeyWidth, gridKeyHeight);
      Key *thisKey = [[Key alloc] initWithFrame:frame
                               givenColourStyle:_colourStyle
                                andKeyCharacter:_keyCharacter
                                   andKeyHeight:1.f // this just sets its border width, nothing more
                              andTonesPerOctave:_tonesPerOctave
                                andPerfectFifth:_perfectFifth
                                 andScaleDegree:scaleDegree];
      [self finalizeThisKey:thisKey withThisNoModScaleDegree:nmsd];
    }
  }
}

-(void)finalizeThisKey:(Key *)thisKey withThisNoModScaleDegree:(NSInteger)nmsd {
  thisKey.borderColour = _backgroundColour;
  thisKey.backgroundColor = thisKey.normalColour;
  thisKey.tag = 1000 + nmsd;
  [thisKey addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchDown];
  [thisKey addTarget:self action:@selector(keyLifted:) forControlEvents:UIControlEventTouchUpInside];
  [self.scrollView addSubview:thisKey];
}

-(void)layoutUserButtons {
  CGFloat buttonsViewWidth = (buttonSize * 2) + (marginBetweenButtons * 3);
  CGFloat buttonsViewHeight = buttonSize + (marginBetweenButtons * 2);
  
  CGFloat xOrigin = 0.f;
  CGFloat yOrigin = marginTop;
  CGFloat xFillX = 0.f;
  CGFloat yFillX = marginTop;
  CGFloat xFillY = 0.f;
  CGFloat yFillY = marginTop;
  
  if ([_userButtonsPosition isEqualToString:@"topLeft"]) {
  } else if ([_userButtonsPosition isEqualToString:@"topRight"]) {
    xOrigin = self.view.bounds.size.width - buttonsViewWidth;
    xFillX = self.view.bounds.size.width - (buttonsViewWidth / 2);
    xFillY = self.view.bounds.size.width - buttonsViewWidth;
  } else if ([_userButtonsPosition isEqualToString:@"bottomLeft"]) {
    yOrigin = self.view.bounds.size.height - buttonsViewHeight;
    yFillX = self.view.bounds.size.height - buttonsViewHeight;
    yFillY = self.view.bounds.size.height - (buttonsViewHeight / 2);
  } else if ([_userButtonsPosition isEqualToString:@"bottomRight"]) {
    xOrigin = self.view.bounds.size.width - buttonsViewWidth;
    yOrigin = self.view.bounds.size.height - buttonsViewHeight;
    xFillX = self.view.bounds.size.width - (buttonsViewWidth / 2);
    yFillX = self.view.bounds.size.height - buttonsViewHeight;
    xFillY = self.view.bounds.size.width - buttonsViewWidth;
    yFillY = self.view.bounds.size.height - (buttonsViewHeight / 2);
  }
  
  UIView *roundedButtonsView = [[UIView alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, buttonsViewWidth, buttonsViewHeight)];
  roundedButtonsView.backgroundColor = _backgroundColour;
  roundedButtonsView.layer.cornerRadius = buttonSize / 2.f;
  
  UIView *buttonsViewFillXCurve = [[UIView alloc] initWithFrame:CGRectMake(xFillX, yFillX, buttonsViewWidth / 2, buttonsViewHeight)];
  buttonsViewFillXCurve.backgroundColor = _backgroundColour;
  
  UIView *buttonsViewFillYCurve = [[UIView alloc] initWithFrame:CGRectMake(xFillY, yFillY, buttonsViewWidth, buttonsViewHeight / 2)];
  buttonsViewFillYCurve.backgroundColor = _backgroundColour;
  
  [self.view addSubview:buttonsViewFillYCurve];
  [self.view addSubview:buttonsViewFillXCurve];
  [self.view addSubview:roundedButtonsView];
  
  UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(marginBetweenButtons, marginBetweenButtons, buttonSize, buttonSize)];
  settingsButton.backgroundColor = [UIColor whiteColor];
  settingsButton.layer.cornerRadius = buttonSize / 2;
  [settingsButton addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [roundedButtonsView addSubview:settingsButton];
  
  UIButton *helpButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonSize + (marginBetweenButtons * 2), marginBetweenButtons, buttonSize, buttonSize)];
  helpButton.backgroundColor = [UIColor whiteColor];
  helpButton.layer.cornerRadius = buttonSize / 2;
  [helpButton addTarget:self action:@selector(helpButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [roundedButtonsView addSubview:helpButton];
}

#pragma mark - presenting other views methods

-(void)settingsButtonPressed:(UIButton *)sender {
  SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
  settingsVC.dataModel = self.dataModel;
  settingsVC.delegate = self;
  [self presentViewController:settingsVC animated:YES completion:nil];
}

-(void)helpButtonPressed:(UIButton *)sender {
  HelpViewController *helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
  [self presentViewController:helpVC animated:YES completion:nil];
}

#pragma mark - musical logic

-(void)establishValuesFromTonesPerOctave {
  _totalKeysInKeyboard = (_numberOfOctaves * _tonesPerOctave) + 1;
  _semitoneInterval = pow(2.f, (1.f / _tonesPerOctave));
  [self findPerfectFifth];
}

-(void)findPerfectFifth {
  int sd = 1;
  float tempRatio = _semitoneInterval;
    // find scale degree that results in first ratio greater than 1.5
  while (tempRatio < 1.5f) {
    tempRatio *= _semitoneInterval;
      //    NSLog(@"%f", tempRatio);
    sd += 1;
  }
    // compare the two ratio to see which is closer to 1.5
  float lowerRatioDiff = 1.5 - (tempRatio / _semitoneInterval);
  float higherRatioDiff = tempRatio - 1.5;
  if (lowerRatioDiff < higherRatioDiff) {
    _perfectFifth = sd - 1;
  } else {
    _perfectFifth = sd;
  }
    //  NSLog(@"lowRatio diff %f, highRatio diff %f", lowerRatioDiff, higherRatioDiff);
    //  NSLog(@"this is the perfect fifth %lu", (unsigned long)_perfectFifth);
}

#pragma mark - key button logic

-(BOOL)isWhiteKeyGivenScaleDegree:(NSNumber *)scaleDegree {
  NSArray *theWhiteKeys;
  switch (_tonesPerOctave) {
    case 12:
      theWhiteKeys = @[@0, @2, @4, @5, @7, @9, @11];
      break;
    case 17:
      theWhiteKeys = @[@0, @3, @6, @7, @10, @13, @16];
      break;
    case 19:
      theWhiteKeys = @[@0, @3, @6, @8, @11, @14, @17];
      break;
    case 24:
      theWhiteKeys = @[@0, @4, @8, @10, @14, @18, @22];
      break;
    case 31:
      theWhiteKeys = @[@0, @5, @10, @13, @18, @23, @28];
      break;
    case 41:
      theWhiteKeys = @[@0, @7, @14, @17, @24, @31, @38];
      break;
  }
  if ([theWhiteKeys containsObject:scaleDegree]) {
    return YES;
  } else {
    return NO;
  }
}

-(NSArray *)figureOutBlackKeys {
  NSArray *theBlackKeys = @[@[]];
  switch (_tonesPerOctave) {
    case 12:
      theBlackKeys = @[@[@1, @3, @6, @8, @10]];
      break;
    case 17:
      theBlackKeys = @[@[@2, @5, @9, @12, @15], @[@1, @4, @8, @11, @14]];
      break;
    case 19:
      theBlackKeys = @[@[@7, @18], @[@2, @5, @10, @13, @16], @[@1, @4, @9, @12, @15]];
      break;
    case 24:
      theBlackKeys = @[@[@9, @23], @[@3, @7, @13, @17, @21], @[@2, @6, @12, @16, @20], @[@1, @5, @11, @15, @19]];
      break;
    case 31:
      theBlackKeys = @[@[@4, @9, @17, @22, @27], @[@12, @30], @[@3, @8, @16, @21, @26], @[@2, @7, @15, @20, @25], @[@11, @29], @[@1, @6, @14, @19, @24]];
      break;
    case 41:
      theBlackKeys = @[@[@6, @13, @23, @30, @37], @[@5, @12, @22, @29, @36], @[@16, @40], @[@4, @11, @21, @28, @35], @[@3, @10, @20, @27, @34], @[@15, @39], @[@2, @9, @19, @26, @33], @[@1, @8, @18, @25, @32]];
      break;
  }
  return theBlackKeys;
}

-(CGFloat)getBlackKeyTypeGivenIndexRow:(NSUInteger)indexRow {
  NSArray *blackKeyTypes;
  switch (_tonesPerOctave) {
    case 12:
      blackKeyTypes = @[@(11/18.f + 0.00001f)]; // regular black key
      break;
    case 17:
      blackKeyTypes = @[@(2/3.f), @(1/3.f)];
      break;
    case 19:
      blackKeyTypes = @[@(11/18.f + 0.00001f), @(2/3.f - 1/15.f - 0.00001f), @(1/3.f + 1/15.f + 0.00001f)];
      break;
    case 24:
      blackKeyTypes = @[@(11/18.f + 0.00001f), @(3/4.f - 1/12.f - 0.00001f), @(2/4.f), @(1/4.f + 1/12.f + 0.00001f)];
      break;
    case 31:
      blackKeyTypes = @[@(4/5.f), @(2/3.f - 1/15.f - 0.00001f), @(3/5.f), @(2/5.f), @(1/3.f + 1/15.f + 0.00001f), @(1/5.f)];
      break;
    case 41:
      blackKeyTypes = @[@(6/7.f - 3/42.f - 0.00002f), @(5/7.f - 2/42.f - 0.00002f), @(2/3.f - 1/9.f - 0.00001f),
                        @(4/7.f - 1/42.f - 0.00002f), @(3/7.f + 1/42.f + 0.00002f), @(1/3.f + 1/9.f + 0.00001f),
                        @(2/7.f + 2/42.f + 0.00002f), @(1/7.f + 3/42.f + 0.00002f)];
      break;
  }
  return [blackKeyTypes[indexRow] floatValue];
}

-(CGFloat)getBlackKeyHeightMultiplierGivenBlackKeyType:(CGFloat)blackKeyType {
  if (blackKeyType == 11/18.f + 0.00001f) {
    return 11/18.f;
  } else if (blackKeyType == 2/3.f - 1/15.f - 0.00001f) {
    return 2/3.f;
  } else if (blackKeyType == 1/3.f + 1/15.f + 0.00001f) {
    return 1/3.f;
  } else if (blackKeyType == 3/4.f - 1/12.f - 0.00001f) {
    return 3/4.f;
  } else if (blackKeyType == 1/4.f + 1/12.f + 0.00001f) {
    return 1/4.f;
  } else if (blackKeyType == 6/7.f - 3/42.f - 0.00002f) {
    return 6/7.f;
  } else if (blackKeyType == 5/7.f - 2/42.f - 0.00002f) {
    return 5/7.f;
  } else if (blackKeyType == 4/7.f - 1/42.f - 0.00002f) {
    return 4/7.f;
  } else if (blackKeyType == 3/7.f + 1/42.f + 0.00002f) {
    return 3/7.f;
  } else if (blackKeyType == 2/7.f + 2/42.f + 0.00002f) {
    return 2/7.f;
  } else if (blackKeyType == 1/7.f + 3/42.f + 0.00002f) {
    return 1/7.f;
  } else if (blackKeyType == 2/3.f - 1/9.f - 0.00001f) {
      return 2/3.f;
  } else if (blackKeyType == 1/3.f + 1/9.f + 0.00001f) {
      return 1/3.f;
  }
  return blackKeyType;
}

-(NSArray *)figureOutInitialExtraMultipliers {
  NSArray *initialExtraMultipliers = @[];
  switch (_tonesPerOctave) {
    case 12:
      initialExtraMultipliers = @[@0];
      break;
    case 17:
      initialExtraMultipliers = @[@0, @0];
      break;
    case 19:
      initialExtraMultipliers = @[@2, @0, @0];
      break;
    case 24:
      initialExtraMultipliers = @[@2, @0, @0, @0];
      break;
    case 31:
      initialExtraMultipliers = @[@0, @2, @0, @0, @2, @0];
      break;
    case 41:
      initialExtraMultipliers = @[@0, @0, @2, @0, @0, @2, @0, @0];
      break;
  }
  return initialExtraMultipliers;
}

-(CGFloat)getGapSizeGivenScaleDegree:(NSNumber *)scaleDegree {
  NSArray *lastBlackKeysBeforeGap;
  NSArray *gapSizes = @[];
  switch (_tonesPerOctave) {
    case 12:
      lastBlackKeysBeforeGap = @[@3, @10];
      gapSizes = @[@1, @1];
      break;
    case 17:
      lastBlackKeysBeforeGap = @[@4, @5, @14, @15];
      gapSizes = @[@1, @1, @1, @1];
      break;
    case 19:
      lastBlackKeysBeforeGap = @[@4, @5, @7, @15, @16, @18];
      gapSizes = @[@1, @1, @3, @1, @1, @2];
      break;
    case 24:
      lastBlackKeysBeforeGap = @[@5, @6, @7, @9, @19, @20, @21, @23];
      gapSizes = @[@1, @1, @1, @3, @1, @1, @1, @2];
      break;
    case 31:
      lastBlackKeysBeforeGap = @[@6, @7, @8, @9, @11, @12, @24, @25, @26, @27, @29, @30];
      gapSizes = @[@1, @1, @1, @1, @3, @3, @1, @1, @1, @1, @2, @2];
      break;
    case 41:
      lastBlackKeysBeforeGap = @[@8, @9, @10, @11, @12, @13, @15, @16, @32, @33, @34, @35, @36, @37, @39, @40];
      gapSizes = @[@1, @1, @1, @1, @1, @1, @3, @3, @1, @1, @1, @1, @1, @1, @2, @2];
  }
  if ([lastBlackKeysBeforeGap containsObject:scaleDegree]) {
    NSInteger gapRowIndex = [lastBlackKeysBeforeGap indexOfObject:scaleDegree];
    return [gapSizes[gapRowIndex] floatValue];
  }
  return 0.f;
}

#pragma mark - keyboard methods

-(void)keyPressed:(Key *)sender {
  float frequency = _lowestTone * pow(2.f, (sender.tag - 1000.f) / _tonesPerOctave);
    //  NSLog(@"frequency %f", frequency);
  audioData.myMandolin->setFrequency(frequency);
  audioData.myMandolin->pluck(0.7f);
  
  sender.backgroundColor = sender.highlightedColour;
}

-(void)keyLifted:(Key *)sender {
  sender.backgroundColor = sender.normalColour;
}

-(void)keysPressed:(UIGestureRecognizer *)tapGesture {
  if (tapGesture.state == UIGestureRecognizerStateEnded) {
    NSInteger numberOfTaps = tapGesture.numberOfTouches;
    for (int i=0; i<numberOfTaps; i++) {
      for (Key *key in self.scrollView.subviews) {
        CGPoint point = [tapGesture locationInView:self.scrollView];
        if (CGRectContainsPoint(key.bounds, point)) {
          NSLog(@"Two touches");
          [self keyPressed:key];
        }
      }
    }
  }
}

#pragma mark - archiver methods

-(NSString *)documentsDirectory {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  return [paths firstObject];
}

-(NSString *)dataFilePath {
  return [[self documentsDirectory] stringByAppendingPathComponent:@"EqualTemperament.plist"];
}

-(void)saveSettings {
  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:self.dataModel forKey:@"dataModel"];
  [archiver finishEncoding];
  [data writeToFile:[self dataFilePath] atomically:YES];
}
   
-(void)loadSettingsFromPath:(NSString *)path {
  NSData *data = [[NSData alloc] initWithContentsOfFile:path];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  self.dataModel = [unarchiver decodeObjectForKey:@"dataModel"];
  [unarchiver finishDecoding];
}

#pragma mark - app methods

-(UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end