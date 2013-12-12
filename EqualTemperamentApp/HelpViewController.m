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

@implementation HelpViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
      // Custom initialization
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
}

-(IBAction)closeButtonTapped:(id)sender {
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - app methods

-(void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
  NSLog(@"deallocated %@", self);
}

@end
