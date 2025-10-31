//
//  CPDCompositionalGroupObject.m
//  compositional-demo
//
//  Created by dengle on 2025/10/31.
//

#import "CPDCompositionalGroupObject.h"

@implementation CPDCompositionalGroupItem

@end

@implementation CPDCompositionalGroupObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _title = @"CPDCompositionalGroupObject";
        _groups = [NSMutableArray array];
        for (int i = 0; i<50; i++) {
            [_groups addObject:[CPDCompositionalGroupItem new]];
        }
    }
    return self;
}

@end
