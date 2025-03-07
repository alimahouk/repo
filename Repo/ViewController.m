//
//  ViewController.m
//  Repo
//
//  Created by Ali Mahouk on 7/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController


- (instancetype)init
{
        self = [super init];
        
        if ( self ) {
                _isFocusedController = NO;
        }
        
        return self;
}

- (void)didChangeControllerFocus:(BOOL)focused
{
        _isFocusedController = focused;
}

- (void)didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}


@end
