//
//  ViewController.m
//  MusiCon
//
//  Created by Bhanu Verma on 3/6/16.
//  Copyright © 2016 theRecommendables. All rights reserved.
//

#import "ViewController.h"
#import <Spotify/Spotify.h>

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"LoggedIn"] == nil) {
        [self performSegueWithIdentifier:@"ViewToLogin" sender:self];
    }
    else {
        [self performSegueWithIdentifier:@"ViewToHome" sender:self];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
