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
#import "KeyboardOverlay.h"

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
@property (strong, nonatomic) KeyboardOverlay *keyboardOverlay;
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
  NSMutableArray *_allSoundedKeys; // again, for scrollview's benefit, added and removed in keyPressed and keyLifted methods only
  NSMutableSet *_allKeysMutable;
  NSSet *_allKeys;
//  NSMutableDictionary *_knownTouchEventAndKeyBeingSounded;
}

#pragma mark - touch methods
//
//-(void)keyboardOverlayTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//  NSLog(@"keyboard overlay touches began");
//  
//  UITouch *touch = [touches anyObject];
//  CGPoint touchLocation = [touch locationInView:self.keyboardOverlay];
//  
//  UIView *view = [self.keyboardOverlay hitTest:touchLocation withEvent:event];
//  NSLog(@"this is the view %@", view);
//}
//
//-(void)keyboardOverlayTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//  
//}
//
//-(void)keyboardOverlayTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//  
//}
//
//-(void)keyboardOverlayTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//  
//}

//-(void)updateKeyUnderTouchAfterScroll {
//    // checks to see if
//  if (_knownTouchEventAndKeyBeingSounded) {
//    CGPoint touchLocation = [_knownTouchEventAndKeyBeingSounded[@"touch"] locationInView:self.scrollView];
//    UIView *currentViewBeingTouched =
//      [self.scrollView hitTest:touchLocation withEvent:_knownTouchEventAndKeyBeingSounded[@"event"]];
//    if ([currentViewBeingTouched isKindOfClass:[Key class]]) {
//      if (_knownTouchEventAndKeyBeingSounded[@"key"] != currentViewBeingTouched) {
//        Key *currentKeyBeingTouched = (Key *)currentViewBeingTouched;
//        [self keyLifted:_knownTouchEventAndKeyBeingSounded[@"key"]];
//        [self keyPressed:currentKeyBeingTouched];
//        _knownTouchEventAndKeyBeingSounded[@"key"] = currentViewBeingTouched;
//        NSLog(@"After scroll, key under touch is now %i", currentKeyBeingTouched.noModScaleDegree);
//      }
//    }
//  }
//}



-(void)handleTapFromKey:(Key *)key {
//  NSLog(@"from a tap!");
//  [self keyPressed:key];
//  [self keyLifted:key];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  
  _event = event;
  
    // kludge solution to scrollView freezing out of bounds after user premature taps key
  if (self.scrollView.contentOffset.x < 0.f) {
    [UIView animateWithDuration:0.1f delay:0.f options:UIViewAnimationCurveEaseOut animations:^{
      self.scrollView.contentOffset = CGPointMake(0, 0);
    } completion:nil];
  } else if (self.scrollView.contentOffset.x > (float)self.scrollView.contentSize.width - (float)self.scrollView.frame.size.width) {
    [UIView animateWithDuration:0.1f delay:0.f options:UIViewAnimationCurveEaseOut animations:^{
      self.scrollView.contentOffset = CGPointMake(self.scrollView.contentSize.width - self.scrollView.frame.size.width, 0);
    } completion:nil];
  }
//  NSLog(@"this is the CGPoint %f", self.scrollView.contentSize.width - self.scrollView.frame.size.width);
  
  UITouch *thisTouch = [touches anyObject];
  NSLog(@"thisTouch began %@", thisTouch.description);
//  NSLog(@"number of gesture recognizers %i", [thisTouch.gestureRecognizers count]);
//  for (UIGestureRecognizer *gestureRecognizer in thisTouch.gestureRecognizers) {
//    gestureRecognizer.delaysTouchesBegan = NO;
//    gestureRecognizer.delaysTouchesEnded = NO;
//    gestureRecognizer.cancelsTouchesInView = NO;
//    gestureRecognizer.delegate = self;
//    NSLog(@"it's a tap gesture %@", gestureRecognizer.class);
//  }
//
//  NSLog(@"this touch's gesture recognizers: %@", thisTouch.gestureRecognizers);
  
  
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
    //  if ([thisTouch.view isKindOfClass:[Key class]]) { // don't bother if it's not a key!
  
  BOOL touchingNewKey = YES;
  for (UITouch *otherTouch in event.allTouches) {
    CGPoint otherTouchLocation = [otherTouch locationInView:self.scrollView];
    UIView *otherTouchHitTest = [self.scrollView hitTest:otherTouchLocation withEvent:event];
    if (thisTouch != otherTouch && thisTouchHitTest == otherTouchHitTest) {
      touchingNewKey = NO;
      return; // do nothing, as this key is already being sounded by another touch
    }
  }
  NSLog(@"touching new key %i", touchingNewKey);
//  if (touchingNewKey) {
//    CGPoint thisTouchPreviousLocation = [thisTouch previousLocationInView:self.scrollView];
//    UIView *thisTouchPreviousHitTest = [self.scrollView hitTest:thisTouchPreviousLocation withEvent:event];
//    NSLog(@"previous hit test is %@", thisTouchPreviousHitTest);
//    if (thisTouchHitTest == thisTouchPreviousHitTest) {
//        // touch has only moved within same key, so do nothing
//      return;
//    } else if (thisTouchHitTest != thisTouchPreviousHitTest) {
  if ([thisTouchHitTest isKindOfClass:[Key class]]) {
    [self keyPressed:(Key *)thisTouchHitTest fromTouch:thisTouch];
  }
//      if ([thisTouchPreviousHitTest isKindOfClass:[Key class]]) {
//        [self keyLifted:(Key *)thisTouchPreviousHitTest];
//      }
//    }
//      //    }
//  }
  
  NSLog(@"touches began tap count %i", thisTouch.tapCount);
  NSLog(@"number of event touches %i", [event.allTouches count]);
  NSLog(@"number of touches %i", [touches count]);
  
  
//  [self touchesMoved:touches withEvent:event fromKey:key];
//  NSLog(@"touch began for key %i", key.noModScaleDegree);
  
//  NSLog(@"count of touches %i in touches began: %@", [touches count], touches);
//  NSLog(@"count of event all touches %i in touches began: %@", [[event allTouches] count], [event allTouches]);
//
//  NSLog(@"Event ID %@", event.description);
//  
//  UITouch *touch = [touches anyObject];
//  CGPoint touchLocation = [touch locationInView:self.scrollView];
//  
//  UIView *currentViewBeingTouched = [self.scrollView hitTest:touchLocation withEvent:event];
//  Key *currentKeyBeingTouched;
//  BOOL currentViewIsAKey = [currentViewBeingTouched isKindOfClass:[Key class]];
//  if (!currentViewIsAKey) {
//      // not instantiating a real key here, just signifies that there is no key under this touch
//    currentKeyBeingTouched = [[Key alloc] init];
//    currentKeyBeingTouched.noModScaleDegree = 1000;
//  } else {
//    currentKeyBeingTouched = (Key *)currentViewBeingTouched;
//  }
//  NSLog(@"current key being touched is key %i", currentKeyBeingTouched.noModScaleDegree);
//  
//  if (!_knownTouchEventAndKeyBeingSounded) {
//      // no recorded touch, event and key
//    if (currentKeyBeingTouched.noModScaleDegree != 1000) {
//      _knownTouchEventAndKeyBeingSounded = [[NSMutableDictionary alloc] initWithObjectsAndKeys:touch, @"touch", currentKeyBeingTouched, @"key", event, @"event", nil];
//      [self touch:touch movedIntoKey:currentKeyBeingTouched];
//    }
//    
//  } else if (_knownTouchEventAndKeyBeingSounded[@"key"] == currentKeyBeingTouched) {
//      // do nothing, since it's repressing the same key
//  } else {
//      // gets rid of old touch
//    
//    [self touch:_knownTouchEventAndKeyBeingSounded[@"touch"] movedOutOfKey:_knownTouchEventAndKeyBeingSounded[@"key"]];
//    
//      // makes new touch
//    _knownTouchEventAndKeyBeingSounded[@"touch"] = touch;
//    _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
//    _knownTouchEventAndKeyBeingSounded[@"event"] = event;
//    
//    [self touch:touch movedIntoKey:currentKeyBeingTouched];
//  }
  [self updateKeys];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  _event = event;
  UITouch *thisTouch = [touches anyObject];
//  NSLog(@"thisTouch moved %@", thisTouch.description);
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
//  if ([thisTouch.view isKindOfClass:[Key class]]) { // don't bother if it's not a key!
  
    BOOL touchingNewKey = YES;
    for (UITouch *otherTouch in event.allTouches) {
      CGPoint otherTouchLocation = [otherTouch locationInView:self.scrollView];
      UIView *otherTouchHitTest = [self.scrollView hitTest:otherTouchLocation withEvent:event];
      if (thisTouch != otherTouch && thisTouchHitTest == otherTouchHitTest) {
        touchingNewKey = NO;
        return; // do nothing, as this key is already being sounded by another touch
      }
    }
//  NSLog(@"touching new key %i", touchingNewKey);
    if (touchingNewKey) {
      CGPoint thisTouchPreviousLocation = [thisTouch previousLocationInView:self.scrollView];
      UIView *thisTouchPreviousHitTest = [self.scrollView hitTest:thisTouchPreviousLocation withEvent:event];
//      NSLog(@"previous hit test is %@", thisTouchPreviousHitTest);
      if (thisTouchHitTest == thisTouchPreviousHitTest && thisTouch.tapCount == 1) {
          // touch has only moved within same key, so do nothing
        return;
      } else if (thisTouchHitTest != thisTouchPreviousHitTest) {
        if ([thisTouchHitTest isKindOfClass:[Key class]]) {
          [self keyPressed:(Key *)thisTouchHitTest fromTouch:thisTouch];
        }
        if ([thisTouchPreviousHitTest isKindOfClass:[Key class]]) {
          [self keyLifted:(Key *)thisTouchPreviousHitTest fromTouch:thisTouch];
        }
      }
//    }
  }
  NSLog(@"touches moved tap count %i", thisTouch.tapCount);
  
//  NSLog(@"count of touches %i in touches moved: %@", [touches count], touches);
//  NSLog(@"count of event all touches %i in touches moved: %@", [[event allTouches] count], [event allTouches]);
//  UITouch *touch = [touches anyObject];
//  CGPoint touchLocation = [touch locationInView:self.scrollView];
//  
//  if (!_knownTouchEventAndKeyBeingSounded) {
//      // no recorded touch, event and key
//    _knownTouchEventAndKeyBeingSounded = [[NSMutableDictionary alloc] initWithObjectsAndKeys:touch, @"touch", key, @"key", event, @"event", nil];
//    [self touch:touch movedIntoKey:key];
//  }
//  
//    // retrieve state for this touch recorded in the array
//  Key *knownKeyForThisTouch;
//  if (touch == _knownTouchEventAndKeyBeingSounded[@"touch"]) {
//    knownKeyForThisTouch = _knownTouchEventAndKeyBeingSounded[@"key"];
//  }
//
//    // check to see if state has changed from before
//  UIView *currentViewBeingTouched = [self.scrollView hitTest:touchLocation withEvent:event];
//  Key *currentKeyBeingTouched;
//  BOOL currentViewIsAKey = [currentViewBeingTouched isKindOfClass:[Key class]];
//  if (!currentViewIsAKey) {
//      // not instantiating a real key here, just signifies that there is no key under this touch
//    currentKeyBeingTouched = [[Key alloc] init];
//    currentKeyBeingTouched.noModScaleDegree = 1000;
//  } else {
//    currentKeyBeingTouched = (Key *)currentViewBeingTouched;
//  }
//  
//  if (_knownTouchEventAndKeyBeingSounded) {
//    if (currentKeyBeingTouched.noModScaleDegree == knownKeyForThisTouch.noModScaleDegree) {
//        // nothing has changed
//    } else if (knownKeyForThisTouch.noModScaleDegree != 1000 && !currentViewIsAKey) {
//      NSLog(@"has moved from key %i to nonkey", knownKeyForThisTouch.noModScaleDegree);
//        // touch moved from key to non-key
//      _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
//      [self touch:touch movedOutOfKey:knownKeyForThisTouch];
//
//    } else if (knownKeyForThisTouch.noModScaleDegree == 1000 && currentViewIsAKey) {
//      NSLog(@"has moved from nonkey to key %i", knownKeyForThisTouch.noModScaleDegree);
//        // touch moved from non-key to key
//      _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
//      [self touch:touch movedIntoKey:currentKeyBeingTouched];
//      
//    } else if (knownKeyForThisTouch.noModScaleDegree != 1000 && currentViewIsAKey) {
//      NSLog(@"has moved from key %i to key %i", knownKeyForThisTouch.noModScaleDegree, currentKeyBeingTouched.noModScaleDegree);
//        // touch moved from key to key
//      _knownTouchEventAndKeyBeingSounded[@"key"] = currentKeyBeingTouched;
//      [self touch:touch movedOutOfKey:knownKeyForThisTouch];
//      [self touch:touch movedIntoKey:currentKeyBeingTouched];
//    }
//  }
  
  [self updateKeys];
}
//
//-(void)touch:(UITouch *)touch movedOutOfKey:(Key *)key {
////  if ([self thereIsAnotherTouchForThisKey:key underThisTouch:touch]) {
//      // no need to lift the key
////  } else {
//
//  [self keyLifted:key];
//  
//  touch = nil;
////  }
////  NSLog(@"touch %@ moved out of key %i", touch.debugDescription, key.tag - 1000);
//}

//-(void)touch:(UITouch *)touch movedIntoKey:(Key *)key {
////  if ([self thereIsAnotherTouchForThisKey:key underThisTouch:touch]) {
//      // no need to re-press the key
////  } else {
//  [self keyPressed:key];
//  
//  touch = nil;
////  }
////  NSLog(@"touch %@ moved into key %i", touch.debugDescription, key.tag - 1000);
//}
//
//-(BOOL)thereIsAnotherTouchForThisKey:(Key *)key underThisTouch:(UITouch *)touch {
////  for (NSDictionary *thisTouchAndKey in _currentViewsBeingTouchedAndKeysBeingSounded) {
//      // establish whether there is another touch for this key
////    if (touch != _knownTouchEventAndKeyBeingSounded[@"touch"] && key == _knownTouchEventAndKeyBeingSounded[@"key"]) {
////      return YES;
////    }
////  }
//  return NO;
//}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  
  _event = event;
  UITouch *thisTouch = [[event allTouches] anyObject];
  CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
  UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:event];
  
  BOOL touchingLoneKey = YES;
  for (UITouch *otherTouch in event.allTouches) {
    CGPoint otherTouchLocation = [otherTouch locationInView:self.scrollView];
    UIView *otherTouchHitTest = [self.scrollView hitTest:otherTouchLocation withEvent:event];
    if (thisTouch != otherTouch && thisTouchHitTest == otherTouchHitTest) {
      touchingLoneKey = NO;
    }
  }
  
  if (touchingLoneKey) {
    
//    check that hit test is key
    if ([thisTouchHitTest isKindOfClass:[Key class]]) {
      [self keyLifted:(Key *)thisTouchHitTest fromTouch:thisTouch];
    }
  }

  NSLog(@"this touch's tap count is %i", thisTouch.tapCount);
  
// retrieve state for this touch recorded in the array
//  NSUInteger indexOfThisTouch;
//  Key *knownKeyForThisTouch;
//
//    if (touch == _knownTouchEventAndKeyBeingSounded[@"touch"]) {
////      indexOfThisTouch = [_currentViewsBeingTouchedAndKeysBeingSounded indexOfObject:thisTouchAndKey];
//      knownKeyForThisTouch = _knownTouchEventAndKeyBeingSounded[@"key"];
//      [self touch:touch movedOutOfKey:knownKeyForThisTouch];
////      [_currentViewsBeingTouchedAndKeysBeingSounded removeObjectAtIndex:indexOfThisTouch];
//      _knownTouchEventAndKeyBeingSounded = nil;
//    }

  
//  NSLog(@"Touches ended for key %i", knownKeyForThisTouch.noModScaleDegree);
  
  [self updateKeys];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event fromKey:(Key *)key {
  _event = event;
  NSLog(@"touches cancelled being called");
  [self touchesEnded:touches withEvent:event];
  [self updateKeys];
}

#pragma mark - key sounding methods

-(void)keyPressed:(Key *)sender fromTouch:(UITouch *)touch {
  if (sender.noModScaleDegree != 1000) {
    float frequency = _lowestTone * pow(2.f, ((float)sender.noModScaleDegree) / _tonesPerOctave);
      //  NSLog(@"frequency %f", frequency);
    audioData.myMandolin->setFrequency(frequency);
    audioData.myMandolin->pluck(0.7f);
    
//    NSLog(@"Sounding key %i", sender.noModScaleDegree);
    NSDictionary *thisDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:sender, @"key", touch, @"touch", nil];
    [_allSoundedKeys addObject:thisDictionary];
    sender.backgroundColor = sender.highlightedColour;
  }
    // ensures it gets reset if there's no touch inside this key
}

-(void)keyLifted:(Key *)sender fromTouch:(UITouch *)touch {
  
//  NSLog(@"Lifting key %i", sender.noModScaleDegree);
  [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveEaseIn animations:^{
    sender.backgroundColor = sender.normalColour;
  } completion:nil];
  
  NSDictionary *toBeRemovedDictionary;
  BOOL removedDictionaryExists = NO;
  for (NSDictionary *thisDictionary in _allSoundedKeys) {
    if (thisDictionary[@"key"] == sender && thisDictionary[@"touch"] == touch) {
      toBeRemovedDictionary = thisDictionary;
      removedDictionaryExists = YES;
    }
  }
  if (removedDictionaryExists) {
    [_allSoundedKeys removeObject:toBeRemovedDictionary];
  }
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
  
//  [self layoutKeyboardOverlay];
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
  
  _allSoundedKeys = [[NSMutableArray alloc] initWithCapacity:10];
  _allKeysMutable = [[NSMutableSet alloc] initWithCapacity:10];
  
  if ([_keyboardStyle isEqualToString:@"whiteBlack"]) {
    [self layoutWhiteBlackKeyboardStyle];
  } else if ([_keyboardStyle isEqualToString:@"grid"]) {
    [self layoutGridKeyboardStyle];
  }
  
  _allKeys = [NSSet setWithSet:_allKeysMutable];
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

//-(void)layoutKeyboardOverlay {
//  self.keyboardOverlay = [[KeyboardOverlay alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.contentSize.width, _statusBarHeight + whiteKeyHeight)];
//  self.keyboardOverlay.backgroundColor = [UIColor clearColor];
//  self.keyboardOverlay.delegate = self;
//  [self.scrollView addSubview:self.keyboardOverlay];
//}

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
//
-(void)customScrollViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  
  _event = event;
  
  NSLog(@"touches began, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
  [self.scrollView gestureRecognizerShouldBegin:self.scrollView.panGestureRecognizer];
//  if (_knownTouchEventAndKeyBeingSounded) {
//    [_knownTouchEventAndKeyBeingSounded[@"key"] resignFirstResponder];
//  }
}
//
-(void)customScrollViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  
  _event = event;
  NSLog(@"touches moved, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
//  if (_knownTouchEventAndKeyBeingSounded) {
//    [_knownTouchEventAndKeyBeingSounded[@"key"] resignFirstResponder];
//  }
}

-(void)customScrollViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
  _event = event;
  NSLog(@"touches moved, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
}

-(void)customScrollViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  
  _event = event;
  NSLog(@"custom scrollview touches cancelled");
}


-(BOOL)thereIsATouchOverThisKey:(Key *)key {
  for (UITouch *thisTouch in [_event allTouches]) {
    CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
    UIView *viewUnderThisTouch = [self.scrollView hitTest:thisTouchLocation withEvent:_event];
    if ([viewUnderThisTouch isKindOfClass:[Key class]]) {
      NSLog(@"this is the viewUnderThisTouch %@", viewUnderThisTouch);
      if (viewUnderThisTouch == key) {
        NSLog(@"there is a touch over this key %i", key.noModScaleDegree);
        return YES;
      }
    }
  }
  return NO;
}
//
//-(void)updateAllSoundedKeys {
//  NSLog(@"total keys in all Keys %i", [_allKeys count]);
//  for (Key *key in self.scrollView.subviews) {
//    if ([self thereIsATouchOverThisKey:key]) {
//      if (![_allSoundedKeys containsObject:key]) {
//        [self keyPressed:key];
//        [_allSoundedKeys addObject:key];
//      }
//    } else {
//      if ([_allSoundedKeys containsObject:key]) {
//        [self keyLifted:key];
//        [_allSoundedKeys removeObject:key];
//      }
//    }
//  }


//}

-(void)updateKeys {
//  [self updateAllSoundedKeys];
  NSMutableSet *dictionariesToRemove = [[NSMutableSet alloc] initWithCapacity:10];
  
  for (UITouch *thisTouch in [_event allTouches]) {
    CGPoint thisTouchLocation = [thisTouch locationInView:self.scrollView];
    UIView *thisTouchHitTest = [self.scrollView hitTest:thisTouchLocation withEvent:_event];
    if ([thisTouchHitTest isKindOfClass:[Key class]]) {
      Key *thisKey = (Key *)thisTouchHitTest;
      
        // get previous location from dictionary
//      CGPoint thisTouchPreviousLocation = [thisTouch previousLocationInView:self.scrollView];
//      UIView *thisTouchPreviousHitTest = [self.scrollView hitTest:thisTouchPreviousLocation withEvent:_event];
      BOOL keyChangedUnderThisTouch = NO;
      NSUInteger index;
      for (NSDictionary *thisDictionary in _allSoundedKeys) {
        if (thisDictionary[@"touch"] == thisTouch && thisDictionary[@"key"] == thisKey) {
        } else if (thisDictionary[@"touch"] == thisTouch && thisDictionary[@"key"] != thisKey) {
          index = [_allSoundedKeys indexOfObject:thisDictionary];
          keyChangedUnderThisTouch = YES;
        } else {
          [dictionariesToRemove addObject:thisDictionary];
        }
      }
      
      if (keyChangedUnderThisTouch) {
        [self keyLifted:_allSoundedKeys[index][@"key"] fromTouch:thisTouch];
        [self keyPressed:thisKey fromTouch:thisTouch];
      }
      
      for (NSDictionary *thisDictionary in dictionariesToRemove) {
        [self keyLifted:thisDictionary[@"key"] fromTouch:thisDictionary[@"touch"]];
      }
    }
  }
  
    // ensures there are never more sounds than touches
  
  
    // ensures there are never more touches than sounds
  
  
  NSLog(@"This is the event %@", _event);
  NSLog(@"There are this many touches in the event %i", [[_event allTouches] count]);
  NSLog(@"There are this many sounded keys %i", [_allSoundedKeys count]);
  
//      BOOL thereIsATouchOverThisKey = [self thereIsATouchOverThisKey:thisKey];
//      if (thereIsATouchOverThisKey && ![_allSoundedKeys containsObject:thisKey]) {
//        [self keyPressed:thisKey];
//      }
//      if (!thereIsATouchOverThisKey) {
//        [self keyLifted:thisKey];
//      }
//    }
//  }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  NSLog(@"scrollview contentOffset %f", self.scrollView.contentOffset.x);
  [self updateKeys];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  NSLog(@"will begin dragging, scrollview gestureRecognizer state %i", self.scrollView.panGestureRecognizer.state);
  [self updateKeys];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  NSLog(@"scrollview contentOffset %f", self.scrollView.contentOffset.x);
  [self updateKeys];
//  [self updateKeyUnderTouchAfterScroll];
}
//
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  NSLog(@"scrollview did end dragging");
  
  [self updateKeys];
}
//
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  NSLog(@"scrollview will end dragging");
  
  [self updateKeys];
}
//}
//
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSLog(@"scrollview did end decelerating");
  
  [self updateKeys];
}
//
//-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
//  NSLog(@"scrollview did scroll to top");
//}

@end