//
//  AppDelegate.m
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#import "AppDelegate.h"

#import "MainViewController.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
        UIApplicationShortcutItem *shortcutItem;
        BOOL retVal;
        
        _model         = [Model new];
        retVal         = YES;
        shortcutItem   = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        viewController = [MainViewController new];
        
        if ( shortcutItem ) {
                if ( [shortcutItem.type isEqualToString:[NSString stringWithFormat:@"%@.textentry", NSBundle.mainBundle.bundleIdentifier]] ) {
                        [viewController showTextEditorAndFocus:YES];
                } else if ( [shortcutItem.type isEqualToString:[NSString stringWithFormat:@"%@.location", NSBundle.mainBundle.bundleIdentifier]] ) {
                        [viewController showLocationPickerAndMark:YES];
                }
                
                retVal = NO;
        }
        
        _window                    = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        _window.backgroundColor    = UIColor.blackColor;
        _window.rootViewController = viewController;
        
        [_window makeKeyAndVisible];
        
        return retVal;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        backgroundTask = [application beginBackgroundTaskWithName:@"EnteringBackgroundTask" expirationHandler:^{
                [application endBackgroundTask:backgroundTask];
                
                backgroundTask = UIBackgroundTaskInvalid;
        }];
        
        // Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [viewController didEnterBackground];
                [application endBackgroundTask:backgroundTask];
                
                backgroundTask = UIBackgroundTaskInvalid;
        });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        [viewController didEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler
{
        if ( [shortcutItem.type isEqualToString:[NSString stringWithFormat:@"%@.textentry", NSBundle.mainBundle.bundleIdentifier]] ) {
                [viewController showTextEditorAndFocus:YES];
                
                completionHandler(YES);
        } else if ( [shortcutItem.type isEqualToString:[NSString stringWithFormat:@"%@.location", NSBundle.mainBundle.bundleIdentifier]] ) {
                [viewController showLocationPickerAndMark:YES];
        }
}


@end
