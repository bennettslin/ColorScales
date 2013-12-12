//
//  KeyboardViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyboardViewController.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"
#import "mo_audio.h"
#import "DataModel.h"

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

  // fine-tune these as necessary
const CGFloat marginSide = 2.f;
const CGFloat marginTop = 20.f;
const CGFloat marginBetweenKeys = 1.f;
const CGFloat keyWidth = 42.f;
const CGFloat keyHeight = 235.f;
const CGFloat buttonSize = 44.f;
const CGFloat marginBetweenButtons = 5.f;

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
  
  float _semitoneInterval;
  float _lowestTone;
  UIColor *_backgroundColour;
}

#pragma mark - view methods

-(void)viewDidLoad {
  _backgroundColour = [UIColor colorWithRed:.2f green:.2f blue:.2f alpha:1.f];
  [super viewDidLoad];
  
    // Bennett-tweaked constants
  _numberOfOctaves = 2;
  _lowestTone = 220.f;
  
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
    self.dataModel.userButtonsPosition = @"right";
  }
  [self updateKeyboardWithChangedDataModel:self.dataModel];
  
  audioData.myMandolin = new Mandolin(20);
    // init the MoAudio layer
  MoAudio::init(SRATE, FRAMESIZE, NUMCHANNELS);
    // start the audio layer, registering a callback method
  MoAudio::start(audioCallback, &audioData);
  
  NSLog(@"Documents folder is %@", [self documentsDirectory]);
  NSLog(@"Data file path is %@", [self dataFilePath]);
}

  // app doesn't know it's in landscape mode until this point
-(void)viewDidAppear:(BOOL)animated {
}

-(void)viewWillLayoutSubviews {
}

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
  [self layoutKeys];
  [self layoutButtons];
}

-(void)placeScrollView {
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
  self.scrollView.backgroundColor = _backgroundColour;
  self.scrollView.contentSize = CGSizeMake((marginSide * 2) + (keyWidth * _totalKeysInKeyboard) +
                                           (marginBetweenKeys * (_totalKeysInKeyboard - 1)),
                                           self.scrollView.bounds.size.height);
  
  [self.scrollView setMultipleTouchEnabled:YES];
  UITapGestureRecognizer *multipleTapsRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keysPressed:)];
  [multipleTapsRecognizer setNumberOfTouchesRequired:2];
  [self.scrollView addGestureRecognizer:multipleTapsRecognizer];
  
  self.scrollView.delegate = self;
  [self.view addSubview:self.scrollView];
}

  // TODO: capture touches in container view
-(void)layoutKeys {
  for (int sd = 0; sd < _totalKeysInKeyboard; sd++) {
    UIButton *whiteKey = [UIButton buttonWithType:UIButtonTypeSystem];
    whiteKey.frame = CGRectMake(marginSide + (sd * keyWidth) + (sd * marginBetweenKeys),
                                marginTop, keyWidth, keyHeight);
    whiteKey.backgroundColor = [self findColour:sd];
    whiteKey.tag = 1000 + sd;
    [whiteKey addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchDown];
    [whiteKey addTarget:self action:@selector(keyLifted:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.scrollView addSubview:whiteKey];
  }
}

-(void)layoutButtons {
  CGFloat buttonsViewWidth = (buttonSize * 2) + (marginBetweenButtons * 3);
  CGFloat buttonsViewHeight = buttonSize + (marginBetweenButtons * 2);
  UIView *roundedButtonsView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - buttonsViewWidth, 20, buttonsViewWidth, buttonsViewHeight)];
  roundedButtonsView.backgroundColor = _backgroundColour;
  roundedButtonsView.layer.cornerRadius = buttonSize / 2.f;
  UIView *buttonsViewTop = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - buttonsViewWidth, 20, buttonsViewWidth, buttonsViewHeight / 2)];
  buttonsViewTop.backgroundColor = _backgroundColour;
  UIView *buttonsViewRight = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - (buttonsViewWidth / 2), 20, buttonsViewWidth / 2, buttonsViewHeight)];
  buttonsViewRight.backgroundColor = _backgroundColour;
  [self.view addSubview:buttonsViewTop];
  [self.view addSubview:buttonsViewRight];
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

#pragma mark - presenting view methods

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

-(UIColor *)findColour:(NSUInteger)pitch {
  
  NSUInteger scaleDegree = pitch % _tonesPerOctave;
  NSUInteger fifthWheelPosition = 0;
  for (int i = 0; i < _tonesPerOctave; i++) {
    if ((i * _perfectFifth) % _tonesPerOctave == scaleDegree) {
      fifthWheelPosition = i;
        //      NSLog(@"Fifth wheel position is %i for scale degree %i", fifthWheelPosition, scaleDegree);
      break;
    }
  }
    // make colour wheel counter-clockwise
  float colourWheelPosition = 1.f - ((float)fifthWheelPosition / _tonesPerOctave);
  float redValue, greenValue, blueValue;
  
    // adjust to taste
  float minBright = 0.65f;
  float maxBright = 1.f;
  
    // wheel positions may need adjusting, because colour wheel isn't perfectly symmetrical
    // red and green are perceived as being more opposite than red and cyan
  float p1 = 1/6.f;
  float p2 = 2/6.f;
  float p3 = 3/6.f;
  float p4 = 4/6.f;
  float p5 = 5/6.f;
  
  if (colourWheelPosition <= p1) {
    redValue = maxBright;
    greenValue = minBright + (1/p1) * (maxBright - minBright) * colourWheelPosition;
    blueValue = minBright;
  } else if (colourWheelPosition > p1 && colourWheelPosition <= p2) {
    redValue = minBright + (1/(p2-p1)) * (maxBright - minBright) * (p2 - colourWheelPosition);
    greenValue = maxBright;
    blueValue = minBright;
  } else if (colourWheelPosition > p2 && colourWheelPosition <= p3) {
    redValue = minBright;
    greenValue = maxBright;
    blueValue = minBright + (1/(p3-p2)) * (maxBright - minBright) * (colourWheelPosition - p2);
  } else if (colourWheelPosition > p3 && colourWheelPosition <= p4) {
    redValue = minBright;
    greenValue = minBright + (1/(p4-p3)) * (maxBright - minBright) * (p4 - colourWheelPosition);
    blueValue = maxBright;
  } else if (colourWheelPosition > p4 && colourWheelPosition <= p5) {
    redValue = minBright + (1/(p5-p4)) * (maxBright - minBright) * (colourWheelPosition - p4);
    greenValue = minBright;
    blueValue = maxBright;
  } else {
    redValue = maxBright;
    greenValue = minBright;
    blueValue = minBright + (1/(1.f-p5)) * (maxBright - minBright) * (1.f - colourWheelPosition);
  }
  return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1.f];
}

#pragma mark - keyboard methods

-(void)keyPressed:(UIButton *)sender {
  float frequency = _lowestTone * pow(2.f, (sender.tag - 1000.f) / _tonesPerOctave);
    //  NSLog(@"frequency %f", frequency);
  audioData.myMandolin->setFrequency(frequency);
  audioData.myMandolin->pluck(0.7f);
}

-(void)keyLifted:(UIButton *)sender {
}

-(void)keysPressed:(UIGestureRecognizer *)tapGesture {
  if (tapGesture.state == UIGestureRecognizerStateEnded) {
    NSInteger numberOfTaps = tapGesture.numberOfTouches;
    for (int i=0; i<numberOfTaps; i++) {
      for (UIButton *button in self.scrollView.subviews) {
        CGPoint point = [tapGesture locationInView:self.scrollView];
        if (CGRectContainsPoint(button.bounds, point)) {
          NSLog(@"Two touches");
          [self keyPressed:button];
        }
      }
    }
  }
}

#pragma mark - directory methods

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