

#import <UIKit/UIKit.h>

@class FJSpringBoardDemoViewController;

@interface FJSpringBoardDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    FJSpringBoardDemoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FJSpringBoardDemoViewController *viewController;

@end

