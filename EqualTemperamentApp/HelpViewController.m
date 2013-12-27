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
  CGFloat _viewFrameWidth;
  CGFloat _viewFrameHeight;
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
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    _viewFrameWidth = _screenWidth * 5/6.f;
    _viewFrameHeight = _screenHeight * 4/5.f;
  } else {
    _viewFrameWidth = _screenWidth * 3/5.f;
    _viewFrameHeight = _screenHeight * 1/2.f;
  }

  self.view.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
  self.view.backgroundColor = [UIColor clearColor];
  self.popupView.frame = CGRectMake((_screenWidth - _viewFrameWidth) / 2, (_screenHeight - _viewFrameHeight) / 2, _viewFrameWidth, _viewFrameHeight);
  self.popupView.backgroundColor = _backgroundColour;
  self.popupView.layer.cornerRadius = 10.f;
  self.view.userInteractionEnabled = YES;
  
  [self setText];
  [self setURLButton];
}

-(void)setText {
  UITextView *textView = [[UITextView alloc] init];
  CGFloat textFieldWidth = _viewFrameWidth - 20.f;
  CGFloat textFieldHeight = _viewFrameHeight - 20.f;
  textView.frame = CGRectMake((_viewFrameWidth - textFieldWidth) / 2, (_viewFrameHeight - textFieldHeight) / 2, textFieldWidth, textFieldHeight);
  textView.text = @"Create scales of any equal temperament, from 2 to 48.\
                     \n\nKeyboard layouts are available for popular scales.\
                     \n\nGrid layout rows may ascend by any interval. The default is the perfect fourth.\
                     \n\nColored keys related by circle of fifths are available for some scales. The circle of fifths is first mapped onto the color wheel. The keys are then arranged stepwise.\
                     \n\nBobtail Yearlings is a chamber folk band now based in Seattle. Please check out Yearling’s Bobtail, our “Ulysses of rock albums,” as well as our comic book album about the life of Rosalind Franklin!";
  textView.textColor = [UIColor brownSettings];
  textView.backgroundColor = [UIColor lighterYellowSettingsBackground];
  textView.editable = NO;
  [self.popupView addSubview:textView];
}

-(void)setURLButton {
  CGFloat buttonWidth = 250.f;
  CGFloat buttonHeight = 50.f;
  UIButton *websiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  websiteButton.frame = CGRectMake((_viewFrameWidth - buttonWidth) / 2, _viewFrameHeight - buttonHeight, buttonWidth, buttonHeight);
  websiteButton.layer.borderColor = [UIColor blackColor].CGColor;
  websiteButton.layer.borderWidth = 1.f;
  [websiteButton setTitle:@"Bobtail Yearlings website" forState:UIControlStateNormal];
  [websiteButton setTitle:@"Bobtail Yearlings website" forState:UIControlStateHighlighted];
  [websiteButton setTitleColor:[UIColor orangeTint] forState:UIControlStateNormal];
  [websiteButton setTitleColor:[UIColor orangeTintHighlighted] forState:UIControlStateHighlighted];
  [websiteButton addTarget:self action:@selector(launchURL:) forControlEvents:UIControlEventTouchUpInside];
  [self.popupView addSubview:websiteButton];
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
