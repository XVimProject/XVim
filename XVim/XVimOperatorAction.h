#import "XVimMotionType.h"

@class XVim;
@class DVTSourceTextView;
@class XVimEvaluator;

@interface XVimOperatorAction : NSObject
@property (weak) XVim *xvim;
@property (readonly) DVTSourceTextView *textView;

- (id)initWithXVim:(XVim*)xvim;
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
@end
