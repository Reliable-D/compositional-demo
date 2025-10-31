//
//  CPDCompositionalLayoutNormalCell.m
//  compositional-demo
//
//  Created by dengle on 2025/10/31.
//

#import "CPDCompositionalLayoutNormalCell.h"

@implementation CPDCompositionalLayoutNormalCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor cyanColor];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.backgroundColor = [UIColor cyanColor];
}

@end
