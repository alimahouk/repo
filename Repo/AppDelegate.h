//
//  AppDelegate.h
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

@import UIKit;

#import "Model.h"

@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
        MainViewController *viewController;
        UIBackgroundTaskIdentifier backgroundTask;
}

@property (nonatomic) Model *model;
@property (strong, nonatomic) UIWindow *window;

@end

