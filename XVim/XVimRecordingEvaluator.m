//
//  XVimRecordingEvaluator.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/13/13.
//
//

#import "XVimRecordingEvaluator.h"
#import "XVimWindow.h"
#import "XVimNormalEvaluator.h"
#import "XVim.h"

@interface XVimRecordingEvaluator()

@property (strong,nonatomic) NSMutableArray* evaluatorStack;
@property (strong,nonatomic) NSString* reg;
@end

@implementation XVimRecordingEvaluator
@synthesize reg = _reg, evaluatorStack = _evaluatorStack;

- (id)initWithWindow:(XVimWindow *)window withRegister:(NSString*)reg{
    if( self = [super initWithWindow:window] ){
        self.evaluatorStack = [[[NSMutableArray alloc] init] autorelease];
        [self.evaluatorStack addObject:[[[XVimNormalEvaluator alloc] initWithWindow:window] autorelease]];
        self.reg = reg;
    }
    return self;
}

- (void)dealloc{
    self.evaluatorStack = nil;
    self.reg = nil;
    [super dealloc];
}

- (void)becameHandler{
    [super becameHandler];
    [[[XVim instance] registerManager] startRecording:self.reg];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    if( keyStroke.modifier == 0 && keyStroke.character == 'q' ){
        [[[XVim instance] registerManager] stopRecording:NO];
        return nil;
    }
    [[[XVim instance] registerManager] record:[keyStroke xvimString]];
    [self.window handleKeyStroke:keyStroke onStack:self.evaluatorStack];
    return self;
}

- (CGFloat)insertionPointHeightRatio{
    return [[self.evaluatorStack lastObject] insertionPointHeightRatio];
}

- (CGFloat)insertionPointWidthRatio{
    return [[self.evaluatorStack lastObject] insertionPointWidthRatio];
}

- (CGFloat)insertionPointAlphaRatio{
    return [[self.evaluatorStack lastObject] insertionPointAlphaRatio];
}

- (NSString*)modeString{
    return @"  Recording  ";
    //return [[self.evaluatorStack lastObject] modeString];
}

- (XVIM_MODE)mode{
    return [(XVimEvaluator*)[self.evaluatorStack lastObject] mode];
}

@end
