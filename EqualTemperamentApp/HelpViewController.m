//
//  HelpViewController.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/10/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController {
  UIColor *_backgroundColour;
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
  _backgroundColour = [UIColor colorWithRed:0.92f green:0.92f blue:0.8f alpha:1.f];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    self.view.backgroundColor = _backgroundColour;
  } else { // iPad
    self.view.backgroundColor = [UIColor clearColor];
    self.iPadPopupView.backgroundColor = _backgroundColour;
    self.iPadPopupView.layer.cornerRadius = 10.f;
  }

}

-(IBAction)closeButtonTapped:(id)sender {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  } else { // iPad
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [self.delegate removeDarkOverlay];
  }
}

#pragma mark - app methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
