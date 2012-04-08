#import "XVimMotionType.h"

@class XVim;
@class DVTSourceTextView;
@class XVimEvaluator;

@interface XVimOperatorAction : NSObject

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim;
@end
