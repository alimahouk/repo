//
//  DarkNavigationController.m
//  Repo
//
//  Created by Ali Mahouk on 16/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "DarkNavigationController.h"

#import "ViewController.h"

@implementation DarkNavigationController


- (UIStatusBarStyle)preferredStatusBarStyle
{
        return UIStatusBarStyleLightContent;
}

- (void)didChangeControllerFocus:(BOOL)focused
{
        // We need to forward this callback to the view controller.
        ViewController *activeController;
        
        activeController = (ViewController *)self.visibleViewController;
        
        [activeController didChangeControllerFocus:focused];
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        
}


@end
