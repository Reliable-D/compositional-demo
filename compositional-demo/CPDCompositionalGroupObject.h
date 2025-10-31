//
//  CPDCompositionalGroupObject.h
//  compositional-demo
//
//  Created by dengle on 2025/10/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPDCompositionalGroupItem: NSObject

@end

@interface CPDCompositionalGroupObject : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSMutableArray<CPDCompositionalGroupItem *> *groups;

@end

NS_ASSUME_NONNULL_END
