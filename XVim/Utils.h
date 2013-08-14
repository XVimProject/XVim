//
//  Utils.h
//  XVim
//
//  Created by Suzuki Shuichiro on 2/16/13.
//
//

#import <Foundation/Foundation.h>

#define XVimAddPoint(a,b) NSMakePoint(a.x+b.x,a.y+b.y)  // Is there such macro in Cocoa?
#define XVimSubPoint(a,b) NSMakePoint(a.x-b.x,a.y-b.y)  // Is there such macro in Cocoa?

NS_INLINE NSPoint AddPoint(NSPoint a, NSPoint b){
    return NSMakePoint(a.x+b.x, a.y+b.y);
}

NS_INLINE NSPoint SubPoint(NSPoint a, NSPoint b){
    return NSMakePoint(a.x-b.x, a.y-b.y);
}

// Following utils are for non fliped coordinate system
NS_INLINE NSPoint RightBottom(NSRect r){
    return NSMakePoint( r.origin.x + r.size.width, r.origin.y );
}

NS_INLINE NSPoint LeftTop(NSRect r){
    return NSMakePoint( r.origin.x, r.origin.y + r.size.height );
}

NS_INLINE NSPoint RightTop(NSRect r){
    return NSMakePoint( r.origin.x + r.size.width, r.origin.y + r.size.height );
}
// You do not need LeftBottom.

@interface Utils : NSObject

@end
