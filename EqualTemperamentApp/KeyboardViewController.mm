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
#import "KeyboardLogic.h"
#import "CustomScrollView.h"

#define SRATE 44100
#define FRAMESIZE 128
#define NUMCHANNELS 2

  // fine-tune these as necessary
const CGFloat marginSide = 1.f;
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

@interface KeyboardViewController () <UIScrollViewDelegate, KeyDelegate, CustomScrollViewDelegate> {
  struct AudioData audioData;
}
@property (strong, nonatomic) CustomScrollView *scrollView;
@property (strong, nonatomic) DataModel *dataModel;

@end

@implementation KeyboardViewController {
  CGFloat _statusBarHeight;
  CGFloat _scrollViewMargin;
  
  NSUInteger _numberOfOctaves;
  NSUInteger _totalKeysInKeyboard;
  NSUInteger _perfectFifth;
  
  NSUInteger _tonesPerOctave;
  NSString *_instrument;
  NSString *_keyCharacter;
  NSString *_keyboardStyle;
  NSString *_colourStyle;
  NSNumber *_rootColourWheelPosition;
  NSString *_userButtonsPosition;
  
  NSUInteger _gridInterval;
  NSUInteger _numberOfGridRows; // set this in viewDidLoad, as it's dependent on iPad or iPhone
  CGFloat _totalKeysPerGridRow;
  
  float _lowestTone;
  UIColor *_backgroundColour;
  
  NSMutableDictionary *_knownTouchEventAndKeyBeingSounded;
}

#pragma mark - touch methods

-(void)updateKeyUnderTouchAfterScroll {
    // checks to see if
  if (_knownTouchEventAndKeyBeingSounded) {
    CGPoint touchLocation = [_knownTouchEventAndKeyBeingSounded[@"touch"] locationInView:self.scrollView];
    UIView *currentViewBeingTouched =
      [self.scrollView hitTest:touchLocation withEvent:_knownTouchEventAndKeyBeingSounded[@"event"]];
    if ([currentViewBeingTouched isKindOfClass:[Key class]]) {
      if (_knownTouchEventAndKeyBeingSounded[@"key"] != currentViewBeingTouched) {
        Key *currentKeyBeingTouched = (Key *)currentViewBeingTouched;
        [self keyLifted:_knownTouchEventAndKeyBeingSounded[@"key"]];
        [self keyPressed:currentKeyBeingTouched];
        _knownTouchEventAndKeyBeingSounded[@"key"] = currentViewBeingTouched;
        NSLog(@"After scroll, key under touch is now %i", currentKeyBeingTouched.noModScaleDegree);
      }
    }
  }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
//  NSLog(@"scrollview did scroll");
  
  [self updateKeyUnderTouchAfterScroll];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  
//  NSLog(@"touch began for key %i", key.noModScaleDegree);
  
  NSLog(@"count of touches %i in touches began: %@", [touches count], touches);
  NSLog(@"count of event all touches %i in touches began: %@", [[event allTouches] count], [event allTouches]);

  UITouch *touch = [touches anyObject];
  CGPoint touchLocation = [touch locationInView:self.scrollView];
  
  UIView *currentViewBeingTouched = [self.scrollView hitTest:touchLocation withEvent:event];
  Key *currentKeyBeingTouched;
  BOOL currentViewIsAKey = [currentViewBeingTouched isKindOfClass:[Key class]];
  if (!currentViewIsAKey) {
      // not instantiating a real key here, just signifies that there is no key under this touch
    currentKeyBeingTouched = [[Key alloc] init];
    currentKeyBeingTouched.noModScaleDegree = 1000;
  } else {
    currentKeyBeingTouched = (Key *)currentViewBeingTouched;
  }
  NSLog(@"current key being touched is key %i", currentKeyBeingTouched.noModScaleDegree);
  
  if (!_knownTouchEventAndKeyBeingSounded) {
      // no recorded touch, event and key
    if (currentKeyBeingTouched.noModScaleDegree != 1000) {
      _knownTouchEventAndKeyBeingSounded = [[NSMutableDictionary alloc] initWithObjectsAndKeys:touch, @"touch", currentKeyBeingTouched, @"key", event, @"event", nil];
      [self touch:touch movedIntoKey:currentKeyBeingTouched];
    }
    
  } else if (_knownTouchEventAndKeyBeingSounded[@"key"] == currentKeyBeingTouched) {
      // do nothing, since it's repressing the same key
  } else {
      // gets rid of old touch
    
    [self touch:_knownTouchEventAndKeyBeingSounded[@"touch"] movedOutOfKey:_knownTouchEventAndKeyBeingSounded[@"key"]];
    
      // makes new touch
    _knownTouchEventAndKeyBeingSounded[@"touch"] = touch;
    _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
    _knownTouchEventAndKeyBeingSounded[@"event"] = event;
    
    [self touch:touch movedIntoKey:currentKeyBeingTouched];
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  
  NSLog(@"count of touches %i in touches moved: %@", [touches count], touches);
  NSLog(@"count of event all touches %i in touches moved: %@", [[event allTouches] count], [event allTouches]);
  UITouch *touch = [touches anyObject];
  CGPoint touchLocation = [touch locationInView:self.scrollView];
  
  if (!_knownTouchEventAndKeyBeingSounded) {
      // no recorded touch, event and key
    _knownTouchEventAndKeyBeingSounded = [[NSMutableDictionary alloc] initWithObjectsAndKeys:touch, @"touch", key, @"key", event, @"event", nil];
    [self touch:touch movedIntoKey:key];
  }
  
    // retrieve state for this touch recorded in the array
  Key *knownKeyForThisTouch;
  if (touch == _knownTouchEventAndKeyBeingSounded[@"touch"]) {
    knownKeyForThisTouch = _knownTouchEventAndKeyBeingSounded[@"key"];
  }

    // check to see if state has changed from before
  UIView *currentViewBeingTouched = [self.scrollView hitTest:touchLocation withEvent:event];
  Key *currentKeyBeingTouched;
  BOOL currentViewIsAKey = [currentViewBeingTouched isKindOfClass:[Key class]];
  if (!currentViewIsAKey) {
      // not instantiating a real key here, just signifies that there is no key under this touch
    currentKeyBeingTouched = [[Key alloc] init];
    currentKeyBeingTouched.noModScaleDegree = 1000;
  } else {
    currentKeyBeingTouched = (Key *)currentViewBeingTouched;
  }
  
  if (_knownTouchEventAndKeyBeingSounded) {
    if (currentKeyBeingTouched.noModScaleDegree == knownKeyForThisTouch.noModScaleDegree) {
        // nothing has changed
    } else if (knownKeyForThisTouch.noModScaleDegree != 1000 && !currentViewIsAKey) {
      NSLog(@"has moved from key %i to nonkey", knownKeyForThisTouch.noModScaleDegree);
        // touch moved from key to non-key
      _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
      [self touch:touch movedOutOfKey:knownKeyForThisTouch];

    } else if (knownKeyForThisTouch.noModScaleDegree == 1000 && currentViewIsAKey) {
      NSLog(@"has moved from nonkey to key %i", knownKeyForThisTouch.noModScaleDegree);
        // touch moved from non-key to key
      _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
      [self touch:touch movedIntoKey:currentKeyBeingTouched];
      
    } else if (knownKeyForThisTouch.noModScaleDegree != 1000 && currentViewIsAKey) {
      NSLog(@"has moved from key %i to key %i", knownKeyForThisTouch.noModScaleDegree, currentKeyBeingTouched.noModScaleDegree);
        // touch moved from key to key
      _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
      [self touch:touch movedOutOfKey:knownKeyForThisTouch];
      [self touch:touch movedIntoKey:currentKeyBeingTouched];
    }
  }
}

-(void)touch:(UITouch *)touch movedOutOfKey:(Key *)key {
//  if ([self thereIsAnotherTouchForThisKey:key underThisTouch:touch]) {
      // no need to lift the key
//  } else {

  [self keyLifted:key];
  
  touch = nil;
//  }
//  NSLog(@"touch %@ moved out of key %i", touch.debugDescription, key.tag - 1000);
}

-(void)touch:(UITouch *)touch movedIntoKey:(Key *)key {
//  if ([self thereIsAnotherTouchForThisKey:key underThisTouch:touch]) {
      // no need to re-press the key
//  } else {
  [self keyPressed:key];
  
  touch = nil;
//  }
//  NSLog(@"touch %@ moved into key %i", touch.debugDescription, key.tag - 1000);
}

-(BOOL)thereIsAnotherTouchForThisKey:(Key *)key underThisTouch:(UITouch *)touch {
//  for (NSDictionary *thisTouchAndKey in _currentViewsBeingTouchedAndKeysBeingSounded) {
      // establish whether there is another touch for this key
//    if (touch != _knownTouchEventAndKeyBeingSounded[@"touch"] && key == _knownTouchEventAndKeyBeingSounded[@"key"]) {
//      return YES;
//    }
//  }
  return NO;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  
  UITouch *touch = [[event allTouches] anyObject];

// retrieve state for this touch recorded in the array
//  NSUInteger indexOfThisTouch;
  Key *knownKeyForThisTouch;

    if (touch == _knownTouchEventAndKeyBeingSounded[@"touch"]) {
//      indexOfThisTouch = [_currentViewsBeingTouchedAndKeysBeingSounded indexOfObject:thisTouchAndKey];
      knownKeyForThisTouch = _knownTouchEventAndKeyBeingSounded[@"key"];
      [self touch:touch movedOutOfKey:knownKeyForThisTouch];
//      [_currentViewsBeingTouchedAndKeysBeingSounded removeObjectAtIndex:indexOfThisTouch];
      _knownTouchEventAndKeyBeingSounded = nil;
    }

  
  NSLog(@"Touches ended for key %i", knownKeyForThisTouch.noModScaleDegree);
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  [self touchesEnded:touches withEvent:event];
}

#pragma mark - key sounding methods

-(void)keyPressed:(Key *)sender {
  if (sender.noModScaleDegree != 1000) {
    float frequency = _lowestTone * pow(2.f, ((float)sender.noModScaleDegree) / _tonesPerOctave);
      //  NSLog(@"frequency %f", frequency);
    audioData.myMandolin->setFrequency(frequency);
    audioData.myMandolin->pluck(0.7f);
    
    NSLog(@"Sounding key %i", sender.noModScaleDegree);
    
    sender.backgroundColor = sender.highlightedColour;
  }
}

-(void)keyLifted:(Key *)sender {
  
  NSLog(@"Lifting key %i", sender.noModScaleDegree);
  [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
    sender.backgroundColor = sender.normalColour;
  } completion:nil];
}

#pragma mark - view methods

-(void)viewDidLoad {
    // for landscape statusBarHeight is width?! Whatever...
  _statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
  _backgroundColour = [UIColor colorWithRed:0.3f green:0.3f blue:0.25f alpha:1.f];
  [super viewDidLoad];
  
    // Bennett-tweaked constants
  _numberOfOctaves = 3;
  _lowestTone = 130.8127826f; // C3
  _numberOfGridRows = 3; // for now, but will change based on iPad or iPhone
  
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
  
  [self saveSettings];
  [self establishValuesFromTonesPerOctave];
  [self placeScrollView];
  
  [self layoutKeysBasedOnKeyboardStyle];
  [self layoutUserButtons];
  
}

-(void)placeScrollView {
  self.scrollView = [[CustomScrollView alloc] init];
  self.scrollView.frame = CGRectMake(0, 0,
                                     self.view.bounds.size.width, self.view.bounds.size.height);
  self.scrollView.backgroundColor = _backgroundColour;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  CGFloat keyWidth = 0;
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    keyWidth = whiteBlackWhiteKeyWidth;
  } else if ([_keyboardStyle isEqualToString:@"justWhite"]) {
    keyWidth = justWhiteKeyWidth;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    keyWidth = gridKeyWidth;
  }
  
  NSUInteger numberOfKeysMultiplier = 0;

  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    // all whiteBlack keyboard layouts have seven white notes per octave
    numberOfKeysMultiplier = (7 * _numberOfOctaves) + 1;
  } else if ([_keyboardStyle isEqualToString:@"justWhite"]) {
    numberOfKeysMultiplier = _totalKeysInKeyboard;
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    _totalKeysPerGridRow = _totalKeysInKeyboard - (_gridInterval * (_numberOfGridRows - 1));
    numberOfKeysMultiplier = _totalKeysPerGridRow;
  }
  
  self.scrollView.contentSize = CGSizeMake((marginSide * 2) + (keyWidth * numberOfKeysMultiplier),
                                           self.scrollView.bounds.size.height);
  _scrollViewMargin = [self findScrollViewMargin];
  self.scrollView.delegate = self;
  self.scrollView.customDelegate = self;
  self.scrollView.delaysContentTouches = NO;
  self.scrollView.multipleTouchEnabled = YES;
//  self.scrollView.canCancelContentTouches = YES;
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

-(CGFloat)findScrollViewMargin {
  CGFloat scrollViewWidth = self.scrollView.contentSize.width;
  CGFloat viewWidth = self.view.frame.size.width;
//  NSLog(@"scrollview width is %f, view width is %f", scrollViewWidth, viewWidth);
  if (viewWidth > scrollViewWidth) {
    return (viewWidth - scrollViewWidth) / 2;
  }
  return 0.f;
}

-(void)layoutWhiteBlackKeyboardStyle {
      // first add white keys
  NSInteger whiteKeyCount = 0;
  for (NSInteger nmsd = 0; nmsd < _totalKeysInKeyboard; nmsd++) {
    NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
    if ([KeyboardLogic isWhiteKeyGivenScaleDegree:scaleDegree andTonesPerOctave:_tonesPerOctave]) {
      CGRect frame = CGRectMake(_scrollViewMargin + marginSide + (whiteKeyCount * whiteBlackWhiteKeyWidth),
                                0, whiteBlackWhiteKeyWidth, whiteKeyHeight + _statusBarHeight);
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
  CGFloat blackKeyWidth = whiteBlackWhiteKeyWidth * 3/4;
  CGFloat blackKeyOffsetMultiplier;
  for (NSArray *thisBlackKeyRow in theBlackKeys) {
    NSInteger blackKeyIndexRow = [theBlackKeys indexOfObject:thisBlackKeyRow];
    CGFloat blackKeyType = [KeyboardLogic getBlackKeyTypeGivenIndexRow:blackKeyIndexRow andTonesPerOctave:_tonesPerOctave];
    CGFloat blackKeyHeightMultiplier = [KeyboardLogic getBlackKeyHeightMultiplierGivenBlackKeyType:blackKeyType];
    CGFloat blackKeyHeight = blackKeyHeightMultiplier * whiteKeyHeight;
    
    if (blackKeyType == 11/18.f + 0.00001f) {
      blackKeyOffsetMultiplier = 1/2.f;
    } else {
      blackKeyOffsetMultiplier = blackKeyType;
    }
    CGFloat blackKeyOffset = blackKeyOffsetMultiplier * whiteBlackWhiteKeyWidth + 1.f;
    CGFloat initialExtraMultiplier = [initialExtraMultipliers[blackKeyIndexRow] floatValue];
    NSInteger blackKeyCount = 0;
    CGFloat blackKeyGapSpace = 0;
    for (NSInteger nmsd = 0; nmsd < _totalKeysInKeyboard; nmsd++) {
      NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
      if ([thisBlackKeyRow containsObject:scaleDegree]) {
        CGRect frame = CGRectMake(_scrollViewMargin + (initialExtraMultiplier * whiteBlackWhiteKeyWidth) + marginSide + ((whiteBlackWhiteKeyWidth - blackKeyWidth) / 2) + blackKeyOffset + (blackKeyCount * whiteBlackWhiteKeyWidth) + blackKeyGapSpace, 0, blackKeyWidth, blackKeyHeight + _statusBarHeight);
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
          blackKeyGapSpace += multiplier * whiteBlackWhiteKeyWidth;
        }
      }
    }
  }
}

-(void)layoutGridKeyboardStyle {
    // may need to tweak this to get right
  CGFloat gridKeyHeight = whiteKeyHeight / _numberOfGridRows;
  for (int thisRow = 0; thisRow < _numberOfGridRows; thisRow++) {
    for (NSInteger nmsd = thisRow * _gridInterval; nmsd < _totalKeysInKeyboard - (_gridInterval * (_numberOfGridRows - (thisRow + 1))); nmsd++) {
      
      NSNumber *scaleDegree = [NSNumber numberWithInteger:nmsd % _tonesPerOctave];
      CGRect frame;
//      if (thisRow == _numberOfGridRows - 1) { // the last row
//      frame = CGRectMake(_scrollViewMargin + marginSide + ((nmsd - (_gridInterval * thisRow)) * gridKeyWidth),
//                                 0, gridKeyWidth, gridKeyHeight + _statusBarHeight);
//      } else {
        frame = CGRectMake(_scrollViewMargin + marginSide + ((nmsd - (_gridInterval * thisRow)) * gridKeyWidth),
                                  _statusBarHeight + (gridKeyHeight * (_numberOfGridRows - (thisRow + 1))), gridKeyWidth, gridKeyHeight);
//      }
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
  [thisKey addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchDown];
  [thisKey addTarget:self action:@selector(keyLifted:) forControlEvents:UIControlEventTouchUpInside];
  
  thisKey.delegate = self;
  
  [self.scrollView addSubview:thisKey];
}

-(void)layoutUserButtons {
    // gets width of screen in landscape
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.height;
  
  CGFloat buttonsViewWidth = (buttonSize * 2) + (marginBetweenButtons * 3);
  CGFloat buttonsViewHeight = buttonSize + (marginBetweenButtons * 2);
  
  CGFloat xOrigin = 0.f;
  CGFloat yOrigin = _statusBarHeight;
  CGFloat xFillX = 0.f;
  CGFloat yFillX = _statusBarHeight;
  CGFloat xFillY = 0.f;
  CGFloat yFillY = _statusBarHeight;
  
  if ([_userButtonsPosition isEqualToString:@"topLeft"]) {
  } else if ([_userButtonsPosition isEqualToString:@"topRight"]) {
    xOrigin = screenWidth - buttonsViewWidth;
    xFillX = screenWidth - (buttonsViewWidth / 2);
    xFillY = screenWidth - buttonsViewWidth;
  } else if ([_userButtonsPosition isEqualToString:@"bottomLeft"]) {
    yOrigin = self.view.bounds.size.height - buttonsViewHeight;
    yFillX = self.view.bounds.size.height - buttonsViewHeight;
    yFillY = self.view.bounds.size.height - (buttonsViewHeight / 2);
  } else if ([_userButtonsPosition isEqualToString:@"bottomRight"]) {
    xOrigin = screenWidth - buttonsViewWidth;
    yOrigin = self.view.bounds.size.height - buttonsViewHeight;
    xFillX = screenWidth - (buttonsViewWidth / 2);
    yFillX = self.view.bounds.size.height - buttonsViewHeight;
    xFillY = screenWidth - buttonsViewWidth;
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
  HelpViewController *_helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
  [self presentViewController:_helpVC animated:YES completion:nil];
}

#pragma mark - musical logic

-(void)establishValuesFromTonesPerOctave {
  _totalKeysInKeyboard = (_numberOfOctaves * _tonesPerOctave) + 1;
  _perfectFifth = [self findPerfectFifthWithTonesPerOctave:_tonesPerOctave];
}

-(NSUInteger)findPerfectFifthWithTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSUInteger perfectFifth = [KeyboardLogic findPerfectFifthWithTonesPerOctave:tonesPerOctave];
  return perfectFifth;
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

  // TODO: delete all this









#pragma mark - delegate methods for debugging

-(void)customScrollViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"touches began, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
  [self.scrollView gestureRecognizerShouldBegin:self.scrollView.panGestureRecognizer];
//  if (_knownTouchEventAndKeyBeingSounded) {
//    [_knownTouchEventAndKeyBeingSounded[@"key"] resignFirstResponder];
//  }
}

-(void)customScrollViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"touches moved, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
//  if (_knownTouchEventAndKeyBeingSounded) {
//    [_knownTouchEventAndKeyBeingSounded[@"key"] resignFirstResponder];
//  }
}

-(void)customScrollViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"touches moved, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
}

-(void)customScrollViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"custom scrollview touches cancelled");
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  NSLog(@"will begin dragging, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
  [self updateKeyUnderTouchAfterScroll];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  NSLog(@"scrollview will begin decelerating");
  
  [self updateKeyUnderTouchAfterScroll];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  NSLog(@"scrollview did end dragging");
  
  [self updateKeyUnderTouchAfterScroll];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  NSLog(@"scrollview will end dragging");
  
  [self updateKeyUnderTouchAfterScroll];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSLog(@"scrollview did end decelerating");
  
  [self updateKeyUnderTouchAfterScroll];
}

-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
  NSLog(@"scrollview did scroll to top");
}

@end