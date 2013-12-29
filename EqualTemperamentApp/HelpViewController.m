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
  CGFloat _marginAroundContent;
  CGFloat _paddingYBetweenContent;
  
  UIScrollView *_scrollView;
  UIView *_theView;
  CGFloat _theViewHeight;
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
  self.view.userInteractionEnabled = YES;
  
    // use these starting popup values to size and position content and button
    // then use size and position of content and button to finalize size and position of popup
  
    // iPhone has scrollview to accommodate smaller screen
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _popupFrameWidth = 416.f;
    _popupFrameHeight = _screenHeight * 4.2/5.f;
    _marginAroundPopup = 12.5f;
    _paddingYBetweenContent = 12.5f;
    _marginAroundContent = 0.f;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(_marginAroundPopup, _marginAroundPopup,
                                                                 _popupFrameWidth - (_marginAroundPopup * 2),
                                                                 _popupFrameHeight - (_marginAroundPopup * 2))];
    _scrollView.contentSize = _scrollView.frame.size;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.popupView addSubview:_scrollView];
    _theView = _scrollView;
  } else {
    _popupFrameWidth = _screenWidth * 3/5.f;
    _popupFrameHeight = _screenHeight * 1/2.f;
    _marginAroundPopup = 25.f;
    _paddingYBetweenContent = 20.f;
    _marginAroundContent = _marginAroundPopup;
    _theView = self.popupView;
  }
  
  self.popupView.backgroundColor = _backgroundColour;
  self.popupView.layer.cornerRadius = 10.f;
  [self establishContentAndButtonSizesAndPositions];
  [self establishTheViewSizeAndPosition];
}

-(void)establishContentAndButtonSizesAndPositions {
    // about the app
  UITextView *aboutTextView = [[UITextView alloc] init];
  CGFloat contentViewWidth = _theView.frame.size.width - (_marginAroundContent * 2);
  CGFloat aboutTextViewHeight = (_popupFrameHeight - (_marginAroundContent * 2)) * 9/16.f;
  NSUInteger fontSize;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    fontSize = 16;
  } else { // iPad
    fontSize = 20;
  }
  aboutTextView.font = [UIFont systemFontOfSize:fontSize];
  aboutTextView.text = @"Create any equal-temperament scale from 2 to 48. Keyboard layouts are available for popular scales. Grid layout rows may ascend by any interval. The default is the perfect fourth.\
                     \n\nColored keys related by circle of fifths are available for some scales. The circle of fifths is mapped onto the color wheel, with keys then laid out stepwise.";
  aboutTextView.textColor = [UIColor brownSettings];
  aboutTextView.backgroundColor = [UIColor lighterYellowSettingsBackground];
  aboutTextView.editable = NO;
  aboutTextView.scrollEnabled = NO;
  aboutTextView.frame = CGRectMake(_marginAroundContent, _marginAroundContent, contentViewWidth, aboutTextViewHeight);
  [aboutTextView sizeToFit];
  aboutTextViewHeight = aboutTextView.frame.size.height;

    // divider
  UIImageView *divider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DividerLightYellow"]];
  CGFloat dividerHeight = 13.f;
  divider.contentMode = UIViewContentModeCenter;
  divider.frame = CGRectMake(_marginAroundContent, _marginAroundContent + _paddingYBetweenContent + aboutTextViewHeight, contentViewWidth, dividerHeight);
  
    // about my band
  UITextView *bandTextView = [[UITextView alloc] init];
  CGFloat bandTextViewHeight = (_popupFrameHeight - (_marginAroundContent * 2)) * 4/16.f;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    fontSize = 15;
  } else { // iPad
    fontSize = 18;
  }
  bandTextView.font = [UIFont italicSystemFontOfSize:fontSize];
  bandTextView.text = @"Bennett Lin plays in Bobtail Yearlings, a chamber folk band in Seattle. Please check out our double album inspired by James Joyce's Ulysses, as well as our comic book album about Rosalind Franklin!";
  bandTextView.textColor = [UIColor brownSettings];
  bandTextView.backgroundColor = [UIColor lighterYellowSettingsBackground];
  bandTextView.editable = NO;
  bandTextView.scrollEnabled = NO;
  bandTextView.frame = CGRectMake(_marginAroundContent, _marginAroundContent + (_paddingYBetweenContent * 2) + aboutTextViewHeight + dividerHeight, contentViewWidth, bandTextViewHeight);
  [bandTextView sizeToFit];
  bandTextViewHeight = bandTextView.frame.size.height;
  
    // button to go to band website

  UIButton *websiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  websiteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
  [websiteButton setTitle:@"Bobtail Yearlings website" forState:UIControlStateNormal];
  [websiteButton setTitle:@"Bobtail Yearlings website" forState:UIControlStateHighlighted];
  [websiteButton setTitleColor:[UIColor orangeTint] forState:UIControlStateNormal];
  [websiteButton setTitleColor:[UIColor orangeTintHighlighted] forState:UIControlStateHighlighted];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    fontSize = 18;
  } else { // iPad
    fontSize = 22;
  }
  websiteButton.titleLabel.font = [UIFont systemFontOfSize:fontSize];
  [websiteButton addTarget:self action:@selector(launchURL:) forControlEvents:UIControlEventTouchUpInside];
  [websiteButton sizeToFit];
  CGFloat websiteButtonWidth = websiteButton.frame.size.width;
  CGFloat websiteButtonHeight = websiteButton.frame.size.height;
  websiteButton.frame = CGRectMake(((contentViewWidth + (_marginAroundContent * 2)) - websiteButtonWidth) / 2, aboutTextViewHeight + dividerHeight + bandTextViewHeight + _marginAroundContent + (_paddingYBetweenContent * 3), websiteButtonWidth, websiteButtonHeight);
  
  [_theView addSubview:aboutTextView];
  [_theView addSubview:bandTextView];
  [_theView addSubview:divider];
  [_theView addSubview:websiteButton];
  _theViewHeight = (_paddingYBetweenContent * 4) + (_marginAroundPopup * 2) + aboutTextViewHeight + dividerHeight + bandTextViewHeight + websiteButtonHeight;
}

-(void)establishTheViewSizeAndPosition {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    self.popupView.frame = CGRectMake((_screenWidth - _popupFrameWidth) / 2, (_screenHeight - _popupFrameHeight) / 2, _popupFrameWidth, _popupFrameHeight);
    _scrollView.contentSize = CGSizeMake(_popupFrameWidth - (_marginAroundPopup * 2), _theViewHeight - (_marginAroundPopup * 2));
  } else { // iPad
    self.popupView.frame = CGRectMake((_screenWidth - _popupFrameWidth) / 2, (_screenHeight - _theViewHeight) / 2, _popupFrameWidth, _theViewHeight);
  }
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
