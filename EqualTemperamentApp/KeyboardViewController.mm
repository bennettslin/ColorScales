//
//  KeyboardViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyboardViewController.h"
#import "mo_audio.h"
#import "DataModel.h"
#import "Key.h"
#import "KeyboardLogic.h"
#import "CustomScrollView.h"
#import "NSObject+ObjectID.h"

#define SRATE 44100
#define FRAMESIZE 128
#define NUMCHANNELS 2

void audioCallback(Float32 *buffer, UInt32 framesize, void *userData) {
  AudioData *data = (AudioData *)userData;
  for(int i=0; i<framesize; i++) {
    SAMPLE out = data->myMandolin->tick();
    buffer[2*i] = buffer[2*i+1] = out;
  }
}

@interface KeyboardViewController () <UIScrollViewDelegate, KeyDelegate, CustomScrollViewDelegate> {
  struct AudioData audioData;
}
@property (strong, nonatomic) CustomScrollView *scrollView;
@property (strong, nonatomic) DataModel *dataModel;

@end

@implementation KeyboardViewController {
  
    // view constants, differ between iPhone and iPad;
  CGFloat _screenMarginSide;
  CGFloat _whiteKeyHeight;
  CGFloat _whiteBlackWhiteKeyWidth;
  CGFloat _gridKeyWidth;
  CGFloat _buttonSize;
  CGFloat _marginBetweenButtons;
    // view variables
  CGFloat _statusBarHeight;
  CGFloat _scrollViewMargin;
  NSUInteger _gridInterval;
  NSUInteger _numberOfGridRows; // set this in viewDidLoad, as it's dependent on iPad or iPhone
  CGFloat _totalKeysPerGridRow;
  UIColor *_backgroundColour;
  
  CGFloat _screenWidth;
  CGFloat _screenHeight;
  UIView *_darkOverlay;
  
    // musical variables
  NSUInteger _numberOfOctaves;
  NSUInteger _totalKeysInKeyboard;
  NSUInteger _perfectFifth;
  float _lowestTone;
  
    // user-defined variables
  NSUInteger _tonesPerOctave;
  NSString *_instrument;
  NSString *_keyCharacter;
  NSString *_keyboardStyle;
  NSString *_colourStyle;
  NSNumber *_rootColourWheelPosition;
  NSString *_userButtonsPosition;
  NSString *_keySize;

  UIEvent *_event; // this is only for the scrollview to know the event
  NSMutableSet *_allSoundedKeys; // added and removed in keyPressed and keyLifted methods only
}

#pragma mark - view methods

-(void)viewDidLoad {
  [super viewDidLoad];
  
  _screenWidth = [UIScreen mainScreen].bounds.size.height;
  _screenHeight = [UIScreen mainScreen].bounds.size.width;
  _screenMarginSide = 1.f;
  
    // for landscape statusBarHeight is width?! Whatever...
  _statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
  _backgroundColour = [UIColor colorWithRed:0.3f green:0.3f blue:0.25f alpha:1.f];
  
    // Bennett-tweaked constants
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _numberOfOctaves = 3;
    _lowestTone = 130.8127826f; // C3
  } else { // iPad
    _numberOfOctaves = 5;
    _lowestTone = 130.8127826f / 2.f; // C2
  }
  
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
    self.dataModel.gridInterval = @7;
    self.dataModel.colourStyle = @"fifthWheel";
    self.dataModel.rootColourWheelPosition = @0;
    self.dataModel.userButtonsPosition = @"bottomRight";
    self.dataModel.keySize = @"bigKeys";
  }
  [self updateKeyboardWithChangedDataModel:self.dataModel];
  
  audioData.myMandolin = new Mandolin(20);
    // init the MoAudio layer
  MoAudio::init(SRATE, FRAMESIZE, NUMCHANNELS);
    // start the audio layer, registering a callback method
  MoAudio::start(audioCallback, &audioData);
}

-(void)updateKeyboardWithChangedDataModel:(DataModel *)dataModel {
  
  if (self.scrollView) {
    [self.scrollView removeFromSuperview];
  }
  _tonesPerOctave = [self.dataModel.tonesPerOctave unsignedIntegerValue];
  _instrument = self.dataModel.instrument;
  _keyCharacter = self.dataModel.keyCharacter;
  _keyboardStyle = self.dataModel.keyboardStyle;
  _gridInterval = [self.dataModel.gridInterval unsignedIntegerValue];
  _colourStyle = self.dataModel.colourStyle;
  _rootColourWheelPosition = self.dataModel.rootColourWheelPosition;
  _userButtonsPosition = self.dataModel.userButtonsPosition;
  _keySize = self.dataModel.keySize;
  
  [self saveSettings];
  [self establishValuesFromTonesPerOctave];
  [self placeScrollView];
  
  UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  activityIndicator.center = CGPointMake(_screenWidth / 2.f, _screenHeight / 2.f);

  [self.scrollView addSubview:activityIndicator];
  [activityIndicator startAnimating];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self layoutKeysBasedOnKeyboardStyle];
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
  });

  [self layoutUserButtons];
  [self defaultScrollViewPosition];
}

-(void)placeScrollView {
  self.scrollView = [[CustomScrollView alloc] init];
  self.scrollView.frame = CGRectMake(0, 0,
                                     _screenWidth, _screenHeight);
  self.scrollView.backgroundColor = _backgroundColour;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  CGFloat keyWidth = 0;
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    keyWidth = _whiteBlackWhiteKeyWidth;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    keyWidth = _gridKeyWidth;
  }
  
  NSUInteger numberOfKeysMultiplier = 0;

  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    // all whiteBlack keyboard layouts have seven white notes per octave
    numberOfKeysMultiplier = (7 * _numberOfOctaves) + 1;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    _totalKeysPerGridRow = _totalKeysInKeyboard - (_gridInterval * (_numberOfGridRows - 1));
    numberOfKeysMultiplier = _totalKeysPerGridRow;
  }
  
  self.scrollView.contentSize = CGSizeMake((_screenMarginSide * 2) + (keyWidth * numberOfKeysMultiplier),
                                           _screenHeight);
  _scrollViewMargin = [self findScrollViewMargin];
  self.scrollView.delegate = self;
  self.scrollView.customDelegate = self;
  self.scrollView.delaysContentTouches = NO;
  self.scrollView.multipleTouchEnabled = NO;
  [self.view addSubview:self.scrollView];
}

-(void)layoutKeysBasedOnKeyboardStyle {
    // nmsd means noModScaleDegree
  _allSoundedKeys = [[NSMutableSet alloc] initWithCapacity:5];
  
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    [self layoutWhiteBlackKeyboardStyle];
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    [self layoutGridKeyboardStyle];
  }
}

-(CGFloat)findScrollViewMargin {
  CGFloat scrollViewWidth = self.scrollView.contentSize.width;
  CGFloat viewWidth = _screenWidth;
  if (viewWidth > scrollViewWidth) {
    return (viewWidth - scrollViewWidth) / 2;
  }
  return 0.f;
}

-(void)layoutWhiteBlackKeyboardStyle {
  CGFloat smallKeysHeightMargin;
  if ([_keySize isEqualToString:@"smallKeys"]) {
    smallKeysHeightMargin = (_screenHeight - _whiteKeyHeight) / 2.f;
  } else { // bigKeys
    smallKeysHeightMargin = 0.f;
  }
  
      // first add white keys
  NSInteger whiteKeyCount = 0;
  for (NSInteger nmsd = 0; nmsd < _totalKeysInKeyboard; nmsd++) {
    NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
    if ([KeyboardLogic isWhiteKeyGivenScaleDegree:scaleDegree andTonesPerOctave:_tonesPerOctave]) {
      CGRect frame = CGRectMake(_scrollViewMargin + _screenMarginSide + (whiteKeyCount * _whiteBlackWhiteKeyWidth),
                                smallKeysHeightMargin, _whiteBlackWhiteKeyWidth, _whiteKeyHeight + _statusBarHeight);
      Key *thisKey = [[Key alloc] initWithFrame:frame
                               givenColourStyle:_colourStyle
                     andRootColourWheelPosition:_rootColourWheelPosition
                                andKeyCharacter:_keyCharacter
                                   andKeyHeight:1.f
                              andTonesPerOctave:_tonesPerOctave
                                andPerfectFifth:_perfectFifth
                                 andScaleDegree:scaleDegree];
      [self finalizeThisKey:thisKey withThisNoModScaleDegree:nmsd];
      whiteKeyCount++;
    }
  }
  
  NSArray *theBlackKeys = [KeyboardLogic figureOutBlackKeysGivenTonesPerOctave:_tonesPerOctave];
  NSArray *initialExtraMultipliers = [KeyboardLogic figureOutInitialExtraMultipliersGivenTonesPerOctave:_tonesPerOctave];
  
    // now add however many rows of black keys
  CGFloat blackKeyWidth = _whiteBlackWhiteKeyWidth * 3/4;
  CGFloat blackKeyOffsetMultiplier;
  for (NSArray *thisBlackKeyRow in theBlackKeys) {
    NSInteger blackKeyIndexRow = [theBlackKeys indexOfObject:thisBlackKeyRow];
    CGFloat blackKeyType = [KeyboardLogic getBlackKeyTypeGivenIndexRow:blackKeyIndexRow andTonesPerOctave:_tonesPerOctave];
    CGFloat blackKeyHeightMultiplier = [KeyboardLogic getBlackKeyHeightMultiplierGivenBlackKeyType:blackKeyType];
    CGFloat blackKeyHeight = blackKeyHeightMultiplier * (_whiteKeyHeight * 9/10.f); // give white keys a little more space
    
    if (blackKeyType == 11/18.f + 0.00001f) {
      blackKeyOffsetMultiplier = 1/2.f;
    } else {
      blackKeyOffsetMultiplier = blackKeyType;
    }
    CGFloat blackKeyOffset = blackKeyOffsetMultiplier * _whiteBlackWhiteKeyWidth + 1.f;
    CGFloat initialExtraMultiplier = [initialExtraMultipliers[blackKeyIndexRow] floatValue];
    NSInteger blackKeyCount = 0;
    CGFloat blackKeyGapSpace = 0;
    for (NSInteger nmsd = 0; nmsd < _totalKeysInKeyboard; nmsd++) {
      NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
      if ([thisBlackKeyRow containsObject:scaleDegree]) {
        CGRect frame = CGRectMake(_scrollViewMargin + (initialExtraMultiplier * _whiteBlackWhiteKeyWidth) + _screenMarginSide + ((_whiteBlackWhiteKeyWidth - blackKeyWidth) / 2) + blackKeyOffset + (blackKeyCount * _whiteBlackWhiteKeyWidth) + blackKeyGapSpace, smallKeysHeightMargin, blackKeyWidth, blackKeyHeight + _statusBarHeight);
        Key *thisKey = [[Key alloc] initWithFrame:frame
                                 givenColourStyle:_colourStyle
                       andRootColourWheelPosition:_rootColourWheelPosition
                                  andKeyCharacter:_keyCharacter
                                     andKeyHeight:blackKeyHeightMultiplier
                                andTonesPerOctave:_tonesPerOctave
                                  andPerfectFifth:_perfectFifth
                                   andScaleDegree:scaleDegree];
        [self finalizeThisKey:thisKey withThisNoModScaleDegree:nmsd];
        blackKeyCount++;
          // calculates the added gap space for the next black key
        CGFloat multiplier = [KeyboardLogic getGapSizeGivenScaleDegree:scaleDegree andTonesPerOctave:_tonesPerOctave];
        if (multiplier != 0.f) {
          blackKeyGapSpace += multiplier * _whiteBlackWhiteKeyWidth;
        }
      }
    }
  }
}

-(void)layoutGridKeyboardStyle {
  CGFloat gridKeyHeight = _whiteKeyHeight / _numberOfGridRows;
  for (int thisRow = 0; thisRow < _numberOfGridRows; thisRow++) {
    for (NSInteger nmsd = thisRow * _gridInterval; nmsd < _totalKeysInKeyboard - (_gridInterval * (_numberOfGridRows - (thisRow + 1))); nmsd++) {

      NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
      CGRect frame;
      frame = CGRectMake(_scrollViewMargin + _screenMarginSide + ((nmsd - (_gridInterval * thisRow)) * _gridKeyWidth),
                                  _statusBarHeight + (gridKeyHeight * (_numberOfGridRows - (thisRow + 1))), _gridKeyWidth, gridKeyHeight);
      Key *thisKey = [[Key alloc] initWithFrame:frame
                               givenColourStyle:_colourStyle
                     andRootColourWheelPosition:_rootColourWheelPosition
                                andKeyCharacter:_keyCharacter
                                   andKeyHeight:1.f // this just sets its border width, nothing more
                              andTonesPerOctave:_tonesPerOctave
                                andPerfectFifth:_perfectFifth
                                 andScaleDegree:scaleDegree];
      [self finalizeThisKey:thisKey withThisNoModScaleDegree:nmsd];
    }
  }
}


-(void)finalizeThisKey:(Key *)thisKey withThisNoModScaleDegree:(NSUInteger)nmsd {
  thisKey.backgroundColor = thisKey.normalColour;
  thisKey.noModScaleDegree = nmsd;
  thisKey.delegate = self;
  [self.scrollView addSubview:thisKey];
}

-(void)layoutUserButtons {
  
    // gets width of screen in landscape
  
  CGFloat buttonsViewWidth = (_buttonSize * 2) + (_marginBetweenButtons * 3);
  CGFloat buttonsViewHeight = _buttonSize + (_marginBetweenButtons * 2);
  
  CGFloat xOrigin = 0.f;
  CGFloat yOrigin = _statusBarHeight;
  CGFloat xFillX = 0.f;
  CGFloat yFillX = _statusBarHeight;
  CGFloat xFillY = 0.f;
  CGFloat yFillY = _statusBarHeight;
  
  if ([_userButtonsPosition isEqualToString:@"topLeft"]) {
  } else if ([_userButtonsPosition isEqualToString:@"topRight"]) {
    xOrigin = _screenWidth - buttonsViewWidth;
    xFillX = _screenWidth - (buttonsViewWidth / 2);
    xFillY = _screenWidth - buttonsViewWidth;
  } else if ([_userButtonsPosition isEqualToString:@"bottomLeft"]) {
    yOrigin = self.view.bounds.size.height - buttonsViewHeight;
    yFillX = self.view.bounds.size.height - buttonsViewHeight;
    yFillY = self.view.bounds.size.height - (buttonsViewHeight / 2);
  } else if ([_userButtonsPosition isEqualToString:@"bottomRight"]) {
    xOrigin = _screenWidth - buttonsViewWidth;
    yOrigin = self.view.bounds.size.height - buttonsViewHeight;
    xFillX = _screenWidth - (buttonsViewWidth / 2);
    yFillX = self.view.bounds.size.height - buttonsViewHeight;
    xFillY = _screenWidth - buttonsViewWidth;
    yFillY = self.view.bounds.size.height - (buttonsViewHeight / 2);
  }
  
  UIView *roundedButtonsView = [[UIView alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, buttonsViewWidth, buttonsViewHeight)];
  roundedButtonsView.backgroundColor = _backgroundColour;
  roundedButtonsView.layer.cornerRadius = _buttonSize / 2.f;
  
  UIView *buttonsViewFillXCurve = [[UIView alloc] initWithFrame:CGRectMake(xFillX, yFillX, buttonsViewWidth / 2, buttonsViewHeight)];
  buttonsViewFillXCurve.backgroundColor = _backgroundColour;
  
  UIView *buttonsViewFillYCurve = [[UIView alloc] initWithFrame:CGRectMake(xFillY, yFillY, buttonsViewWidth, buttonsViewHeight / 2)];
  buttonsViewFillYCurve.backgroundColor = _backgroundColour;
  
  [self.view addSubview:buttonsViewFillYCurve];
  [self.view addSubview:buttonsViewFillXCurve];
  [self.view addSubview:roundedButtonsView];
  
  UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(_marginBetweenButtons, _marginBetweenButtons, _buttonSize, _buttonSize)];
  settingsButton.backgroundColor = [UIColor whiteColor];
  settingsButton.layer.cornerRadius = _buttonSize / 2;
  [settingsButton addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [roundedButtonsView addSubview:settingsButton];
  
  UIButton *helpButton = [[UIButton alloc] initWithFrame:CGRectMake(_buttonSize + (_marginBetweenButtons * 2), _marginBetweenButtons, _buttonSize, _buttonSize)];
  helpButton.backgroundColor = [UIColor whiteColor];
  helpButton.layer.cornerRadius = _buttonSize / 2;
  [helpButton addTarget:self action:@selector(helpButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [roundedButtonsView addSubview:helpButton];
}

-(void)ensureScrollViewHasCorrectContentOffset {
  if (self.scrollView.contentSize.width > _screenWidth) {
    if (self.scrollView.contentOffset.x < 0.f) {
      [UIView animateWithDuration:0.1f delay:0.f options:UIViewAnimationCurveEaseOut animations:^{
        self.scrollView.contentOffset = CGPointMake(0, 0);
      } completion:nil];
    } else if (self.scrollView.contentOffset.x > (float)self.scrollView.contentSize.width - (float)self.scrollView.frame.size.width) {
      [UIView animateWithDuration:0.1f delay:0.f options:UIViewAnimationCurveEaseOut animations:^{
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentSize.width - self.scrollView.frame.size.width, 0);
      } completion:nil];
    }
  }
}

-(void)defaultScrollViewPosition {
  NSUInteger numberOfOctavesToOffset;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    numberOfOctavesToOffset = 1;
  } else { // iPad
    numberOfOctavesToOffset = 2;
  }
  
  if (self.scrollView.contentSize.width > _screenWidth) {
    CGFloat keyWidth;
    if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
      keyWidth = _whiteBlackWhiteKeyWidth;
      self.scrollView.contentOffset = CGPointMake(_screenMarginSide + (7.f * numberOfOctavesToOffset * keyWidth) - 0.5f, 0); // accommodate key border width
    } else { // grid
       // starts at origin if grid layout
    }
  }
}

#pragma mark - presenting other views methods

-(void)settingsButtonPressed:(UIButton *)sender {
  SettingsViewController *settingsVC;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    settingsVC = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController~iPhone" bundle:nil];
  } else { // iPad
    settingsVC = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController~iPad" bundle:nil];
  }
  settingsVC.dataModel = self.dataModel;
  settingsVC.delegate = self;
  [self presentChildViewController:settingsVC];
//  [self animateDarkOverlayBeforeChildViewController:settingsVC];
}

-(void)presentChildViewController:(UIViewController *)childVC {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self presentViewController:childVC animated:YES completion:nil];
  } else { // iPad
           // not sure why async dispatch works only when it's applied to both this block
           // and the settings view controller's picker blocks
    [self animateDarkOverlayBeforeChildViewController:childVC];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view addSubview:childVC.view];
    });
    [self addChildViewController:childVC];
    [childVC didMoveToParentViewController:self];
  }
}

-(void)animateDarkOverlayBeforeChildViewController:(UIViewController *)childVC {
  _darkOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
  _darkOverlay.backgroundColor = [UIColor clearColor];
  [self.view addSubview:_darkOverlay];
  [UIView animateKeyframesWithDuration:0.3f delay:0.f options:UIViewAnimationCurveEaseInOut animations:^{
    _darkOverlay.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.f alpha:0.5f];
  } completion:nil];
}

-(void)removeDarkOverlay {
  [UIView animateKeyframesWithDuration:0.3f delay:0.f options:UIViewAnimationCurveEaseInOut animations:^{
    _darkOverlay.backgroundColor = [UIColor clearColor];
  } completion:^(BOOL finished) {
    [_darkOverlay removeFromSuperview];
  }];
}

-(void)helpButtonPressed:(UIButton *)sender {
  HelpViewController *helpVC;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController~iPhone" bundle:nil];
  } else { // iPad
    helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController~iPad" bundle:nil];
  }
  helpVC.delegate = self;
  [self presentChildViewController:helpVC];
}

#pragma mark - musical logic

-(void)establishValuesFromTonesPerOctave {
  _totalKeysInKeyboard = (_numberOfOctaves * _tonesPerOctave) + 1;
  _perfectFifth = [self findPerfectFifthWithTonesPerOctave:_tonesPerOctave];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _whiteKeyHeight = _screenHeight * 3/4.f;
    _whiteBlackWhiteKeyWidth = 60.f;
  } else { // iPad
    if ([_keySize isEqualToString:@"smallKeys"] && ![_keyboardStyle isEqualToString:@"grid"]) {
      _whiteKeyHeight = _screenHeight * 2/5.f; // change based on real piano keys
      _whiteBlackWhiteKeyWidth = 60.f;
    } else { // bigKeys or grid
      _whiteKeyHeight = _screenHeight * 4/5.f; // change based on real piano keys
      _whiteBlackWhiteKeyWidth = 120.f;
    }
  }
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _gridKeyWidth = 54.f;
    _numberOfGridRows = 3; // for now, but will change based on iPad or iPhone
  } else { // iPad
    if ([_keySize isEqualToString:@"smallKeys"]) {
        // because iPad has five octaves, this number will only ever be 5 or greater
      if (_totalKeysInKeyboard / _gridInterval >= 8) {
        _gridKeyWidth = 54.f;
        _numberOfGridRows = 8;
      } else if (_totalKeysInKeyboard / _gridInterval >= 7) {
        _gridKeyWidth = 61.7f;
        _numberOfGridRows = 7;
      } else if (_totalKeysInKeyboard / _gridInterval >= 6) {
        _gridKeyWidth = 72.f;
        _numberOfGridRows = 6;
      } else {
        _gridKeyWidth = 86.4f;
        _numberOfGridRows = 5;
      }
    } else { // bigKeys
      _gridKeyWidth = 108.f;
      _numberOfGridRows = 4;
    }
  }
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _buttonSize = 44.f;
    _marginBetweenButtons = 5.f;
  } else { // iPad
    _buttonSize = 88.f;
    _marginBetweenButtons = 10.f;
  }
}

-(NSUInteger)findPerfectFifthWithTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSUInteger perfectFifth = [KeyboardLogic findPerfectFifthWithTonesPerOctave:tonesPerOctave];
  return perfectFifth;
}

#pragma mark - key sounding methods

-(void)pressKey:(Key *)key {
    // ONLY call this method from Key instance
  
    // logic to sound key
  float frequency = _lowestTone * pow(2.f, ((float)key.noModScaleDegree) / _tonesPerOctave);
  audioData.myMandolin->setFrequency(frequency);
  audioData.myMandolin->pluck(0.7f);
}

-(void)liftKey:(Key *)key {
    // ONLY call this method from Key instance
  
    // logic to silence key will go here, depending on audio engine
}

# pragma mark - updating keys and touches helper methods

-(void)updateTouches {
    // ensures that all touches have the right keys when called after a touch delegate method
  for (UITouch *thisTouch in _event.allTouches) {
      // this ensures that keys aren't added for touches that have ended!
      // this was the fix I couldn't figure out for a long, long while...
      // ensures the touch started in key and not scrollview
      if ((thisTouch.phase < 3 && [thisTouch.view isKindOfClass:[Key class]])) {
      CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
      UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:_event];
      
      if ([thisTouchHitTest isKindOfClass:[Key class]]) {
        Key *thisKey = (Key *)thisTouchHitTest;
        if (thisTouch != thisKey.mostRecentTouch && thisTouch) {
          [thisKey addTouchToThisKey:thisTouch];
        }
      }
    }
  }
  [self checkSoundedKeysAreTouchedAtEnd];
}

-(void)checkSoundedKeysAreTouchedAtEnd {
    // ensures that all touches are flushed at the end of dragging, decelerating, and scrollView's touchesEnded,
    // because the key's touchesEnded method doesn't always get called
  NSMutableSet *keysToRemove = [[NSMutableSet alloc] initWithCapacity:5];
  for (Key *thisKey in _allSoundedKeys) {
    BOOL removeTouchFromThisKey = YES; // the default
    for (UITouch *thisTouch in [_event allTouches]) {
      CGPoint touchLocation = [thisTouch locationInView:self.scrollView];
      UIView *hitView = [self.scrollView hitTest:touchLocation withEvent:_event];
      if (hitView == thisKey) {
        removeTouchFromThisKey = NO; // the key is being touched
      }
    }
    if (removeTouchFromThisKey) {
      [keysToRemove addObject:thisKey];
    }
  }
  for (Key *thisKey in keysToRemove) {
    [thisKey removeThisKey];
  }
}

#pragma mark - key gesture recognizer delegate methods

-(void)keyTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // kludge workaround to ensure scrollView doesn't freeze out of bounds after user premature taps key
  [self ensureScrollViewHasCorrectContentOffset];
  _event = event;
  
  UITouch *thisTouch = [touches anyObject];
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
  if ([thisTouchHitTest isKindOfClass:[Key class]]) {
    Key *thisKey = (Key *)thisTouchHitTest;
    [thisKey addTouchToThisKey:thisTouch];
  }
}

-(void)keyTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
  
  UITouch *thisTouch = [touches anyObject];
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitView = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  CGPoint thisTouchPreviousLocation = [thisTouch previousLocationInView:self.scrollView];
  UIView *thisTouchPreviousHitView = [self.scrollView hitTest:thisTouchPreviousLocation withEvent:event];
  BOOL thisTouchIsOnAKeyNow = [thisTouchHitView isKindOfClass:[Key class]];
  BOOL thisTouchWasOnAKeyBefore = [thisTouchPreviousHitView isKindOfClass:[Key class]];

  if (thisTouchIsOnAKeyNow && thisTouchWasOnAKeyBefore) {
    Key *thisKey = (Key *)thisTouchHitView;
    Key *previousKey = (Key *)thisTouchPreviousHitView;
    if (thisKey != previousKey) {
      [thisKey addTouchToThisKey:thisTouch];
      [previousKey removeTouchFromThisKey:thisTouch];
    }
  } else if (thisTouchIsOnAKeyNow && !thisTouchWasOnAKeyBefore) {
    Key *thisKey = (Key *)thisTouchHitView;
    [thisKey addTouchToThisKey:thisTouch];
  } else if (!thisTouchIsOnAKeyNow && thisTouchWasOnAKeyBefore) {
    Key *previousKey = (Key *)thisTouchPreviousHitView;
    [previousKey removeTouchFromThisKey:thisTouch];
  }
}

-(void)keyTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
  
  UITouch *thisTouch = [touches anyObject];
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitView = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
  if ([thisTouchHitView isKindOfClass:[Key class]]) {
    Key *thisKey = (Key *)thisTouchHitView;
    [thisKey removeTouchFromThisKey:thisTouch];
  }
  
  [self checkSoundedKeysAreTouchedAtEnd];
}

-(void)keyTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self keyTouchesEnded:touches withEvent:event];
}

-(void)addKeyToKeysSounded:(Key *)key {
  [_allSoundedKeys addObject:key];
}

-(void)removeKeyFromKeysSounded:(Key *)key {
  [_allSoundedKeys removeObject:key];
}

#pragma mark - scrollview methods

-(void)customScrollViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)customScrollViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)customScrollViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)customScrollViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self updateTouches];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//  [self updateTouches];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  [self updateTouches];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // kludge way to ensure that all keys are lifted after dragging ended
//  [self kludgeMethodToEnsureRemovalOfAllKeysAfterScrolling];
  [self updateTouches];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  [self updateTouches];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // kludge way to ensure that all keys are lifted after decelerating ended
//  [self kludgeMethodToEnsureRemovalOfAllKeysAfterScrolling];
  [self updateTouches];
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
  if ([_colourStyle isEqualToString:@"noColour"] && [_keyboardStyle isEqualToString:@"whiteBlack"]) {
    return UIStatusBarStyleDefault;
  } else {
    return UIStatusBarStyleLightContent;
  }
}

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end