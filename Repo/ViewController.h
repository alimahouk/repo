//
//  ViewController.h
//  Repo
//
//  Created by Ali Mahouk on 7/11/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

@interface ViewController : UIViewController

@property (nonatomic) BOOL isFocusedController;

- (void)didChangeControllerFocus:(BOOL)focused;

@end
