#import "XVimMotionType.h"

@class DVTSourceTextView;
@class XVimEvaluator;
@class XVimWindow;

@interface XVimOperatorAction : NSObject

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window;
@end
