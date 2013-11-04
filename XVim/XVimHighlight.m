//
//  XVimHighlight.m
//  XVim
//
//  Created by Suzuki Shuichiro on 11/3/13.
//
//

#import "XVimHighlight.h"
#import "Utils.h"

#pragma mark XVimHighlightGroup

@implementation XVimHighlightGroup

+ (id)highlightWithGuifg:(NSColor*)guifg guibg:(NSColor*)guibg{
    return [[[XVimHighlightGroup alloc] initWithGuifg:guifg guibg:guibg] autorelease];
}

- (id)init{
    return [self initWithGuifg:nil guibg:nil];
}

- (id)initWithGuifg:(NSColor*)guifg guibg:(NSColor*)guibg{
    if( self = [super init] ){
        self.guifg = guifg;
        self.guibg = guibg;
    }
    return self;
}

- (void)dealloc{
    self.guifg = nil;
    self.guibg = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    return [[XVimHighlightGroup allocWithZone:zone] initWithGuifg:self.guifg guibg:self.guibg];
}

- (void)setColorName:(NSString*)color forKey:(NSString*)key{
    NSColor* c = nil;
    if( [color isEqualToString:@"NONE"]){
        c = [NSColor clearColor];
    }else{
        c = [NSColor colorWithString:color];
    }
    if( c == nil ){
        return;
    }
    [self setValue:c forKey:key];
}

- (void)setArg:(NSString*)arg forKey:(NSString*)key{
    if( [key isEqualToString:@"guifg"] ){
        [self setColorName:arg forKey:key];
    }else if( [key isEqualToString:@"guibg"] ){ 
        [self setColorName:arg forKey:key];
    }
}

@end 


#pragma mark XVimHighlightGroups

@interface XVimHighlightGroups()
@property(strong,nonatomic) NSMutableDictionary* highlightGroups;
@end

@implementation XVimHighlightGroups
- (id)init{
    if( self = [super init] ){
        self.highlightGroups = [NSMutableDictionary dictionary];
        
        // Initialize Highlight Groups
        [self.highlightGroups setObject:[XVimHighlightGroup highlightWithGuifg:nil guibg:nil] forKey:@"Search"];
        
        // Default settings
        [self setHighlightGroupForName:@"Search" key:@"guifg" arg:@"NONE"];
        [self setHighlightGroupForName:@"Search" key:@"guibg" arg:@"yellow"];
    }
    return self;
}

- (void)dealloc{
    self.highlightGroups = nil;
    [super dealloc];
}

- (void)setHighlightGroupForName:(NSString*)name key:(NSString*)key arg:(NSString*)arg{
    XVimHighlightGroup* g = [self.highlightGroups objectForKey:name];
    [g setArg:arg forKey:key];
}

- (XVimHighlightGroup*)highlightGroup:(NSString*)name{
    return [[[self.highlightGroups objectForKey:name] copy] autorelease];
}
@end
