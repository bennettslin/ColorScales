//
//  HelpViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "HelpViewController.h"
#import "UIColor+ColourWheel.h"

@interface HelpViewController ()

@end

@implementation HelpViewController {
  UIColor *_backgroundColour;
  CGFloat _screenWidth;
  CGFloat _screenHeight;
  CGFloat _popupFrameWidth;
  CGFloat _popupFrameHeight;
  CGFloat _marginAroundPopup;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
      // Custom initialization
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  
  _screenWidth = [UIScreen mainScreen].bounds.size.height;
  _screenHeight = [UIScreen mainScreen].bounds.size.width;
  _backgroundColour = [UIColor lighterYellowSettingsBackground];
  self.view.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
  self.view.backgroundColor = [UIColor clearColor];
  
    // use these starting popup values to size and position content and button
    // then use size and position of content and button to finalize size and position of popup
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _popupFrameWidth = 416.f;
    _popupFrameHeight = _screenHeight * 4.2/5.f;
    _marginAroundPopup = 6.f;
  } else {
    _popupFrameWidth = _screenWidth * 1/2.f;
    _popupFrameHeight = _screenHeight * 1/2.f;
    _marginAroundPopup = 15.f;
  }

  [self establishContentAndButtonSizesAndPositions];
  [self establishPopupSizeAndPosition];
}

-(void)establishContentAndButtonSizesAndPositions {
    // about the app
  UITextView *aboutTextView = [[UITextView alloc] init];
  CGFloat textViewWidth = _popupFrameWidth - (_marginAroundPopup * 2);
  CGFloat aboutTextViewHeight = (_popupFrameHeight - (_marginAroundPopup * 2)) * 9/16.f;
  aboutTextView.frame = CGRectMake(_marginAroundPopup, _marginAroundPopup, textViewWidth, aboutTextViewHeight);
  aboutTextView.text = @"Create any equal-temperament scale from 2 to 48. Keyboard layouts are available for popular scales. Grid layout rows may ascend by any interval. The default is the perfect fourth.\
                     \n\nColored keys related by circle of fifths are available for some scales. The circle of fifths is first mapped onto the color wheel; keys are then arranged stepwise.";
  aboutTextView.textColor = [UIColor brownSettings];
  aboutTextView.backgroundColor = [UIColor lighterYellowSettingsBackground];
  aboutTextView.editable = NO;
  aboutTextView.scrollEnabled = NO;
  NSUInteger fontSize;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    fontSize = 13;
  } else { // iPad
    fontSize = 16;
  }
  aboutTextView.font = [UIFont systemFontOfSize:fontSize];
  [aboutTextView sizeToFit];
  aboutTextViewHeight = aboutTextView.frame.size.height;

    // divider
  UIImageView *divider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DividerLightYellow"]];
  CGFloat dividerHeight = 13.f;
  divider.contentMode = UIViewContentModeCenter;
  divider.frame = CGRectMake(_marginAroundPopup, (_marginAroundPopup * 2) + aboutTextViewHeight, _popupFrameWidth - (_marginAroundPopup * 2), dividerHeight);
  
    // about my band
  UITextView *bandTextView = [[UITextView alloc] init];
  CGFloat bandTextViewHeight = (_popupFrameHeight - (_marginAroundPopup * 2)) * 4/16.f;
  bandTextView.frame = CGRectMake(_marginAroundPopup, (_marginAroundPopup * 3) + aboutTextViewHeight + dividerHeight, textViewWidth, bandTextViewHeight);
  bandTextView.text = @"Bobtail Yearlings is a chamber folk band now based in Seattle. Please check out our “Ulysses of rock albums,” as well as our comic book album about the life of Rosalind Franklin!";
  bandTextView.textColor = [UIColor brownSettings];
  bandTextView.backgroundColor = [UIColor lighterYellowSettingsBackground];
  bandTextView.editable = NO;
  bandTextView.scrollEnabled = NO;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    fontSize = 12;
  } else { // iPad
    fontSize = 14.5;
  }
  bandTextView.font = [UIFont systemFontOfSize:fontSize];
  [bandTextView sizeToFit];
  bandTextViewHeight = bandTextView.frame.size.height;
  
    // button to go to band website

  UIButton *websiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  websiteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  [websiteButton setTitle:@"Bobtail Yearlings website" forState:UIControlStateNormal];
  [websiteButton setTitle:@"Bobtail Yearlings website" forState:UIControlStateHighlighted];
  [websiteButton setTitleColor:[UIColor orangeTint] forState:UIControlStateNormal];
  [websiteButton setTitleColor:[UIColor orangeTintHighlighted] forState:UIControlStateHighlighted];
  [websiteButton addTarget:self action:@selector(launchURL:) forControlEvents:UIControlEventTouchUpInside];
  [websiteButton sizeToFit];
  CGFloat websiteButtonWidth = websiteButton.frame.size.width;
  CGFloat websiteButtonHeight = websiteButton.frame.size.height;
  websiteButton.frame = CGRectMake((_popupFrameWidth - websiteButtonWidth) / 2, aboutTextViewHeight + dividerHeight + bandTextViewHeight + (_marginAroundPopup * 4), websiteButtonWidth, websiteButtonHeight);
  
  [self.popupView addSubview:aboutTextView];
  [self.popupView addSubview:bandTextView];
  [self.popupView addSubview:divider];
  [self.popupView addSubview:websiteButton];
  
  _popupFrameHeight = (_marginAroundPopup * 6) + aboutTextViewHeight + dividerHeight + bandTextViewHeight + websiteButtonHeight;
}

-(void)establishPopupSizeAndPosition {
  self.popupView.frame = CGRectMake((_screenWidth - _popupFrameWidth) / 2, (_screenHeight - _popupFrameHeight) / 2, _popupFrameWidth, _popupFrameHeight);
  self.popupView.backgroundColor = _backgroundColour;
  self.popupView.layer.cornerRadius = 10.f;
  self.view.userInteractionEnabled = YES;
}

-(void)launchURL:(UIButton *)sender {
  NSString *launchUrl = @"http://bobtailyearlings.com/";
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString: launchUrl]];
}

-(void)returnToParentViewController {
  [self.delegate removeDarkOverlay];
  [self.delegate hideStatusBar:NO];
  [self willMoveToParentViewController:nil];
  [self.view removeFromSuperview];
  [self removeFromParentViewController];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = touches.anyObject;
  if (touch.view == self.view) {
    [self returnToParentViewController];
  }
}

#pragma mark - app methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden {
  return YES;
}

@end
