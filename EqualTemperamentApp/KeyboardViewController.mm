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
#import "NSObject+ObjectID.h"
#import "KeyTouch.h"

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
    // view variables
  CGFloat _statusBarHeight;
  CGFloat _scrollViewMargin;
  NSUInteger _gridInterval;
  NSUInteger _numberOfGridRows; // set this in viewDidLoad, as it's dependent on iPad or iPhone
  CGFloat _totalKeysPerGridRow;
  UIColor *_backgroundColour;
  
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

  UIEvent *_event; // this is only for the scrollview to know the event
  NSMutableSet *_allSoundedKeys; // added and removed in keyPressed and keyLifted methods only
  NSMutableArray *_allKeysMutable;
  NSArray *_allKeys;
//  NSMutableSet *_allKeyTouches;
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
  self.scrollView.multipleTouchEnabled = NO;
//  self.scrollView.canCancelContentTouches = YES;
  [self.view addSubview:self.scrollView];
}

-(void)layoutKeysBasedOnKeyboardStyle {
    // nmsd means noModScaleDegree
  
  _allSoundedKeys = [[NSMutableSet alloc] initWithCapacity:5];
  _allKeysMutable = [[NSMutableArray alloc] initWithCapacity:_totalKeysInKeyboard];
//  _allKeyTouches = [[NSMutableSet alloc] initWithCapacity:10];
  
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    [self layoutWhiteBlackKeyboardStyle];
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    [self layoutGridKeyboardStyle];
  }
  
  _allKeys = [[NSArray alloc] initWithArray:_allKeysMutable];
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
//  [thisKey addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchDown];
//  [thisKey addTarget:self action:@selector(keyLifted:) forControlEvents:UIControlEventTouchUpInside];
  
  thisKey.delegate = self;
  
  [_allKeysMutable addObject:thisKey];
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

-(void)ensureScrollViewHasCorrectContentOffset {
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

//-(BOOL)thereIsATouchOverThisKey:(Key *)key {
//  for (KeyTouch *thisTouch in [_event allTouches]) {
//    CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
//    UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:_event];
//    if ([thisTouchHitTest isKindOfClass:[Key class]]) {
//      Key *thisKey = (Key *)thisTouchHitTest;
//      if (thisKey == key) {
//        return YES;
//      }
//    }
//  }
//  return NO;
//}

-(void)updateTouches:(NSSet *)touches {
    // ensures that touches have the right keys
  for (KeyTouch *thisTouch in touches) {
    CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
    UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:_event];
    
    if ([thisTouchHitTest isKindOfClass:[Key class]]) {
      Key *thisKey = (Key *)thisTouchHitTest;
      if (![thisKey.touches containsObject:thisTouch]) {
        [thisKey addTouchToThisKey:thisTouch];
        for (Key *otherKey in _allSoundedKeys) {
          if (thisKey != otherKey && [otherKey.touches containsObject:thisTouch]) {
            [otherKey.touches removeObject:thisTouch];
          }
        }
      }
    }
  }
  
//  if ([touches count] == 0) {
//    for (Key *key in _allKeys) {
//      [key removeAllTouchesFromThisKey];
//    }
//  }
  
//  NSLog(@"There are this many touches in the event %i", [_event.allTouches count]);
}

//-(void)updateTouchesAtEnd:touches {
//  if ([touches count] == 0) {
//    for (Key *key in _allKeys) {
////      [key removeAllTouchesFromThisKeyWithEvent:(UIEvent *)_event];
//    }
//  }
//  NSLog(@"Touches at the end: %i", [touches count]);
//  [self updateTouchesAtEnd];
//}

-(void)updateTouches {
    // ensures that touches have the right keys
  for (KeyTouch *thisTouch in _event.allTouches) {
    CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
    UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:_event];
    
    if ([thisTouchHitTest isKindOfClass:[Key class]]) {
      Key *thisKey = (Key *)thisTouchHitTest;
      if (thisTouch != thisKey.mostRecentTouch) {
        [thisKey addTouchToThisKey:thisTouch];
      }
    }
  }
  [self checkSoundedKeysAreTouchedAtEnd];
}

-(void)checkSoundedKeysAreTouchedAtEnd {
  NSMutableSet *keysToRemove = [[NSMutableSet alloc] initWithCapacity:5];
  for (Key *thisKey in _allSoundedKeys) {
    BOOL removeTouchFromThisKey = YES; // the default
    for (UITouch *thisTouch in [_event allTouches]) {
      CGPoint touchLocation = [thisTouch locationInView:self.scrollView];
      UIView *hitView = [self.scrollView hitTest:touchLocation withEvent:_event];
      if (hitView == thisKey) {
        removeTouchFromThisKey = NO; // the key is being touched
        NSLog(@"the touch is %@, its view is %@", thisTouch.objectID, thisTouch.view.objectID);
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
  
  KeyTouch *thisTouch = [touches anyObject];
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
  if ([thisTouchHitTest isKindOfClass:[Key class]]) {
    Key *thisKey = (Key *)thisTouchHitTest;
    [thisKey addTouchToThisKey:thisTouch];
  }
}

-(void)keyTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
  
  KeyTouch *thisTouch = [touches anyObject];
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
  
  KeyTouch *thisTouch = [touches anyObject];
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitView = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
  if ([thisTouchHitView isKindOfClass:[Key class]]) {
    Key *thisKey = (Key *)thisTouchHitView;
    [thisKey removeTouchFromThisKey:thisTouch];
  }
  
  [self checkSoundedKeysAreTouchedAtEnd];
}

-(void)keyTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"touches cancelled from key");
  [self keyTouchesEnded:touches withEvent:event];
}

-(void)addKeyToKeysSounded:(Key *)key {
  [_allSoundedKeys addObject:key];
}

-(void)removeKeyFromKeysSounded:(Key *)key {
  [_allSoundedKeys removeObject:key];
}

-(UIScrollView *)tellKeyScrollview {
  return self.scrollView;
}

#pragma mark - scrollview methods

-(void)customScrollViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
}

-(void)customScrollViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
  [self updateTouches];
}

-(void)customScrollViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
    // ensures that keys will lift if touch went down on scrollView then dragged into key
  [self kludgeMethodToEnsureRemovalOfAllKeysAfterScrolling];
}

-(void)customScrollViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  _event = event;
  [self updateTouches];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //  NSLog(@"scrollview contentOffset %f", self.scrollView.contentOffset.x);
  
  [self updateTouches];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    //  NSLog(@"will begin dragging, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
  
  [self updateTouches];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    //  NSLog(@"scrollview contentOffset %f", self.scrollView.contentOffset.x);
  
  [self updateTouches];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //  NSLog(@"scrollview did end dragging");
  
    // kludge way to ensure that all keys are lifted after dragging ended
  [self kludgeMethodToEnsureRemovalOfAllKeysAfterScrolling];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    //  NSLog(@"scrollview will end dragging");
  
  [self updateTouches];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //  NSLog(@"scrollview did end decelerating");
  
    // kludge way to ensure that all keys are lifted after decelerating ended
  [self kludgeMethodToEnsureRemovalOfAllKeysAfterScrolling];
}

-(void)kludgeMethodToEnsureRemovalOfAllKeysAfterScrolling {
    // kludge way to ensure that all keys are lifted after decelerating or dragging ended
    // for some reason, key doesn't know that its touch has ended after scrolling
  NSSet *keysToRemove = [NSMutableSet setWithSet:_allSoundedKeys];
  for (Key *key in keysToRemove) {
    [key removeThisKey];
  }
}

@end