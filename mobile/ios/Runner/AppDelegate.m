#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#include "TflitePlugin.h"
#include "MuseumTflitePlugin.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    [MuseumTflitePlugin registerWithRegistrar:[self registrarForPlugin:@"net.pangolinai.mobile/museum_tflite"]];
    
    [TflitePlugin registerWithRegistrar:[self registrarForPlugin:@"net.pangolinai.mobile/tflite"]];
    
  [GeneratedPluginRegistrant registerWithRegistry:self];
    
    
    
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                               annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                    ];
    // Add any custom logic here.
    return handled;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:sourceApplication
                                                               annotation:annotation
                    ];
    // Add any custom logic here.
    return handled;
} 

@end
