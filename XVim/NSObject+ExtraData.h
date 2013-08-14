//
//  NSObject+ExtraData.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/24/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (ExtraData)
- (id)dataForName:(NSString*)name;
- (void)setData:(id)data forName:(NSString*)name;

// Utilities
- (void)setBool:(BOOL)b forName:(NSString*)name;
- (void)setUnsignedInteger:(NSUInteger)b forName:(NSString*)name;
- (void)setInteger:(NSInteger)b forName:(NSString *)name;
@end
