//
//  CPDCompositionalLayoutController.m
//  compositional-demo
//
//  Created by dengle on 2025/10/31.
//

#import "CPDCompositionalLayoutController.h"
#import "CPDCompositionalLayoutBannerCell.h"
#import "CPDCompositionalLayoutNormalCell.h"
#import "CPDCompositionalLayoutGroupCell.h"
#import "CPDCompositionalGroupObject.h"

// 定义Section标识符类型
typedef NS_ENUM(NSInteger, CPDCompositionalSectionType) {
    CPDCompositionalSectionTypeBanner = 0,
    CPDCompositionalSectionTypeNormal2x2,
    CPDCompositionalSectionTypeGroup,
    CPDCompositionalSectionTypeNormal1x2
};

// 定义Section标识符（需要遵循NSCopying）
@interface CPDCompositionalSection : NSObject <NSCopying>
@property (nonatomic, assign) CPDCompositionalSectionType type;
- (instancetype)initWithType:(CPDCompositionalSectionType)type;
@end

// 定义Item标识符（需要遵循NSCopying）
@interface CPDCompositionalItem : NSObject <NSCopying>
@property (nonatomic, strong) id data;
@property (nonatomic, assign) CPDCompositionalSectionType sectionType;
@property (nonatomic, strong) NSUUID *uniqueIdentifier; // 确保每个item唯一
- (instancetype)initWithData:(id)data sectionType:(CPDCompositionalSectionType)sectionType;
@end

@implementation CPDCompositionalSection

- (instancetype)initWithType:(CPDCompositionalSectionType)type {
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    CPDCompositionalSection *copy = [[CPDCompositionalSection allocWithZone:zone] initWithType:self.type];
    return copy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CPDCompositionalSection class]]) {
        return NO;
    }
    return self.type == ((CPDCompositionalSection *)object).type;
}

- (NSUInteger)hash {
    return self.type;
}

@end

@implementation CPDCompositionalItem

- (instancetype)initWithData:(id)data sectionType:(CPDCompositionalSectionType)sectionType {
    self = [super init];
    if (self) {
        _data = data;
        _sectionType = sectionType;
        _uniqueIdentifier = [NSUUID UUID];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    CPDCompositionalItem *copy = [[CPDCompositionalItem allocWithZone:zone] initWithData:self.data sectionType:self.sectionType];
    copy.uniqueIdentifier = self.uniqueIdentifier;
    return copy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CPDCompositionalItem class]]) {
        return NO;
    }
    CPDCompositionalItem *other = (CPDCompositionalItem *)object;
    // 使用uniqueIdentifier来确保唯一性
    return [self.uniqueIdentifier isEqual:other.uniqueIdentifier];
}

- (NSUInteger)hash {
    return [self.uniqueIdentifier hash];
}

@end

@interface CPDCompositionalLayoutController ()<UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<CPDCompositionalSection *, CPDCompositionalItem *> *dataSource;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
// 保存所有可能的 section 对象，确保即使 section 被隐藏也能在新数据到来时恢复
@property (nonatomic, strong) NSArray<CPDCompositionalSection *> *allSections;
@end

@implementation CPDCompositionalLayoutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
    [self configureDataSource];
    [self loadInitialData];
}

- (void)setupUI {
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[self createLayout]];
    [self.view addSubview:_collectionView];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [_collectionView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor constant:0],
        [_collectionView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor constant:0],
    ]];
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    [_collectionView registerClass:[CPDCompositionalLayoutBannerCell class] forCellWithReuseIdentifier:@"CPDCompositionalLayoutBannerCell"];
    [_collectionView registerClass:[CPDCompositionalLayoutNormalCell class] forCellWithReuseIdentifier:@"CPDCompositionalLayoutNormalCell"];
    [_collectionView registerClass:[CPDCompositionalLayoutGroupCell class] forCellWithReuseIdentifier:@"CPDCompositionalLayoutGroupCell"];
    _collectionView.delegate = self;
    
    // 添加下拉刷新控件
    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"下拉刷新"];
    [_refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    _collectionView.refreshControl = _refreshControl;
}

- (void)configureDataSource {
    __weak typeof(self) weakSelf = self;
    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, CPDCompositionalItem * _Nonnull itemIdentifier) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return nil;
        }
        
        if (itemIdentifier.sectionType == CPDCompositionalSectionTypeBanner) {
            CPDCompositionalLayoutBannerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutBannerCell" forIndexPath:indexPath];
            return cell;
        } else if (itemIdentifier.sectionType == CPDCompositionalSectionTypeNormal2x2) {
            CPDCompositionalLayoutNormalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutNormalCell" forIndexPath:indexPath];
            cell.backgroundColor = [UIColor redColor];
            return cell;
        } else if (itemIdentifier.sectionType == CPDCompositionalSectionTypeGroup) {
            CPDCompositionalLayoutGroupCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutGroupCell" forIndexPath:indexPath];
            return cell;
        } else { // CPDCompositionalSectionTypeNormal1x2
            CPDCompositionalLayoutNormalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutNormalCell" forIndexPath:indexPath];
            return cell;
        }
    }];
}

- (void)loadInitialData {
    // 创建并保存所有可能的 section 对象
    CPDCompositionalSection *bannerSection = [[CPDCompositionalSection alloc] initWithType:CPDCompositionalSectionTypeBanner];
    CPDCompositionalSection *normal2x2Section = [[CPDCompositionalSection alloc] initWithType:CPDCompositionalSectionTypeNormal2x2];
    CPDCompositionalSection *groupSection = [[CPDCompositionalSection alloc] initWithType:CPDCompositionalSectionTypeGroup];
    CPDCompositionalSection *normal1x2Section = [[CPDCompositionalSection alloc] initWithType:CPDCompositionalSectionTypeNormal1x2];
    
    self.allSections = @[bannerSection, normal2x2Section, groupSection, normal1x2Section];
    
    NSDiffableDataSourceSnapshot<CPDCompositionalSection *, CPDCompositionalItem *> *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
    
    // Section 0: Banner
    [snapshot appendSectionsWithIdentifiers:@[bannerSection]];
    NSMutableArray<CPDCompositionalItem *> *bannerItems = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:@"" sectionType:CPDCompositionalSectionTypeBanner];
        [bannerItems addObject:item];
    }
    [snapshot appendItemsWithIdentifiers:bannerItems intoSectionWithIdentifier:bannerSection];
    
    // Section 1: Normal 2x2
    [snapshot appendSectionsWithIdentifiers:@[normal2x2Section]];
    NSMutableArray<CPDCompositionalItem *> *normal2x2Items = [NSMutableArray array];
    for (int i = 0; i < 12; i++) {
        CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:@"" sectionType:CPDCompositionalSectionTypeNormal2x2];
        [normal2x2Items addObject:item];
    }
    [snapshot appendItemsWithIdentifiers:normal2x2Items intoSectionWithIdentifier:normal2x2Section];
    
    // Section 2: Group
    [snapshot appendSectionsWithIdentifiers:@[groupSection]];
    NSMutableArray<CPDCompositionalItem *> *groupItems = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
        CPDCompositionalGroupObject *groupObject = [[CPDCompositionalGroupObject alloc] init];
        CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:groupObject sectionType:CPDCompositionalSectionTypeGroup];
        [groupItems addObject:item];
    }
    [snapshot appendItemsWithIdentifiers:groupItems intoSectionWithIdentifier:groupSection];
    
    // Section 3: Normal 1x2
    [snapshot appendSectionsWithIdentifiers:@[normal1x2Section]];
    NSMutableArray<CPDCompositionalItem *> *normal1x2Items = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:@"" sectionType:CPDCompositionalSectionTypeNormal1x2];
        [normal1x2Items addObject:item];
    }
    [snapshot appendItemsWithIdentifiers:normal1x2Items intoSectionWithIdentifier:normal1x2Section];
    
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

- (void)handleRefresh:(UIRefreshControl *)refreshControl {
    // 模拟网络请求
    [self fetchNewDataWithCompletion:^{
        // 网络请求完成后，停止刷新动画
        dispatch_async(dispatch_get_main_queue(), ^{
            [refreshControl endRefreshing];
        });
    }];
}

- (void)fetchNewDataWithCompletion:(void(^)(void))completion {
    // 模拟网络请求延迟（1-2秒）
    NSTimeInterval delay = arc4random_uniform(1000) / 1000.0 + 1.0; // 1.0-2.0秒
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 在主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateDataWithRandomCount];
            
            if (completion) {
                completion();
            }
        });
    });
}

- (void)updateDataWithRandomCount {
    // 创建新的snapshot
    NSDiffableDataSourceSnapshot<CPDCompositionalSection *, CPDCompositionalItem *> *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
    
    // 使用保存的所有 section 对象，而不是从当前 snapshot 获取
    // 这样可以确保即使某个 section 之前被隐藏（count=0），新数据到来时也能恢复显示
    NSArray<CPDCompositionalSection *> *sections = self.allSections;
    
    // 为每个section生成随机数量的新数据
    for (CPDCompositionalSection *section in sections) {
        NSInteger randomCount = 0;
        NSMutableArray<CPDCompositionalItem *> *newItems = [NSMutableArray array];
        
        if (section.type == CPDCompositionalSectionTypeBanner) {
            // Banner section: 0-8个（允许为0）
            randomCount = arc4random_uniform(9); // 0-8
            for (NSInteger i = 0; i < randomCount; i++) {
                CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:@"" sectionType:CPDCompositionalSectionTypeBanner];
                [newItems addObject:item];
            }
        } else if (section.type == CPDCompositionalSectionTypeNormal2x2) {
            // Normal 2x2 section: 0-15个（允许为0）
            randomCount = arc4random_uniform(16); // 0-15
            for (NSInteger i = 0; i < randomCount; i++) {
                CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:@"" sectionType:CPDCompositionalSectionTypeNormal2x2];
                [newItems addObject:item];
            }
        } else if (section.type == CPDCompositionalSectionTypeGroup) {
            // Group section: 0-6个（允许为0）
            randomCount = arc4random_uniform(7); // 0-6
            for (NSInteger i = 0; i < randomCount; i++) {
                CPDCompositionalGroupObject *groupObject = [[CPDCompositionalGroupObject alloc] init];
                CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:groupObject sectionType:CPDCompositionalSectionTypeGroup];
                [newItems addObject:item];
            }
        } else if (section.type == CPDCompositionalSectionTypeNormal1x2) {
            // Normal 1x2 section: 0-15个（允许为0）
            randomCount = arc4random_uniform(16); // 0-15
            for (NSInteger i = 0; i < randomCount; i++) {
                CPDCompositionalItem *item = [[CPDCompositionalItem alloc] initWithData:@"" sectionType:CPDCompositionalSectionTypeNormal1x2];
                [newItems addObject:item];
            }
        }
        
        // 只有当 items 数量 > 0 时才添加 section 和 items
        // 如果 count 为 0，则不添加该 section，这样就不会显示空 section
        if (newItems.count > 0) {
            [snapshot appendSectionsWithIdentifiers:@[section]];
            [snapshot appendItemsWithIdentifiers:newItems intoSectionWithIdentifier:section];
        }
    }
    
    // 应用新的snapshot，带动画效果
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
}

- (UICollectionViewCompositionalLayout *)createLayout {
    UICollectionViewCompositionalLayoutConfiguration *layoutConfig = [UICollectionViewCompositionalLayoutConfiguration new];
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        // 使用dataSource获取section identifier
        // 如果dataSource还未初始化，使用sectionIndex作为fallback
        CPDCompositionalSectionType sectionType;
        
        if (self.dataSource) {
            NSDiffableDataSourceSnapshot<CPDCompositionalSection *, CPDCompositionalItem *> *snapshot = self.dataSource.snapshot;
            NSArray<CPDCompositionalSection *> *sections = snapshot.sectionIdentifiers;
            
            if (sectionIndex < sections.count) {
                CPDCompositionalSection *sectionIdentifier = sections[sectionIndex];
                sectionType = sectionIdentifier.type;
            } else {
                // 如果sectionIndex超出范围，使用默认值
                sectionType = (CPDCompositionalSectionType)sectionIndex;
            }
        } else {
            // dataSource未初始化时，使用sectionIndex作为类型
            sectionType = (CPDCompositionalSectionType)sectionIndex;
        }
        
        if (sectionType == CPDCompositionalSectionTypeBanner) {
            // Group 的方向可以是横向(horizontalGroup)或纵向(verticalGroup)
            // horizontalGroup: items 在 Group 内横向排列
            // verticalGroup: items 在 Group 内纵向排列
            // Section 内的多个 Groups 默认纵向排列（因为 UICollectionView 默认纵向滚动）
            // 要实现横向滚动效果，需要设置 orthogonalScrollingBehavior
            
            // 每个 item 的宽度应该是屏幕宽度的一部分（比如 0.85 或固定宽度）
            // 如果想要横向滚动，item 宽度不能是 1.0（会占满整个宽度）
            NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:300] heightDimension:[NSCollectionLayoutDimension absoluteDimension:120]];
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
            
            NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:300] heightDimension:[NSCollectionLayoutDimension absoluteDimension:120]];
            // 使用 horizontalGroup：items 在 Group 内横向排列
            NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item]];
            // 设置 group 内 items 之间的间距（横向间距）
            group.interItemSpacing = [NSCollectionLayoutSpacing fixedSpacing:10];
            
            NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
            // 关键：设置横向滚动行为，让 Section 内的多个 Groups 横向排列
            section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorContinuous;
            // 设置 section 内 groups 之间的间距（横向滚动时是横向间距）
            section.interGroupSpacing = 10;
            // 设置 section 的内容边距
            section.contentInsets = NSDirectionalEdgeInsetsMake(10, 10, 10, 10);
            return section;
        } else if (sectionType == CPDCompositionalSectionTypeNormal2x2) { // normal, 一个group,2行2列，且横向滑动
            // ========== 嵌套 Group 实现 2行2列 ==========
            // 
            // 【布局结构】
            // Section (横向滚动)
            //   └── Group (外层横向 Group，包含2个垂直的 Group)
            //         ├── Vertical Group 1 (第1列，包含2个 items)
            //         │     ├── Item 1 (第1行第1列)
            //         │     └── Item 2 (第2行第1列)
            //         └── Vertical Group 2 (第2列，包含2个 items)
            //               ├── Item 3 (第1行第2列)
            //               └── Item 4 (第2行第2列)
            //
            // 【关键概念】
            // - 使用嵌套 Groups：外层横向 Group + 内层垂直 Group
            // - orthogonalScrollingBehavior 实现横向滚动
            
            // 1. 创建 Item（每个 cell 的大小）
            // 每个 item 占据 Group 宽度的一半（因为外层 Group 包含2列）
            NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:0.5]];
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
            
            // 2. 创建内层垂直 Group（每列包含2行）
            // 每个垂直 Group 的宽度是外层 Group 的一半（fractionalWidthDimension:0.5）
            // 高度需要计算：如果每个 item 高度是外层 Group 高度的 0.5，那么垂直 Group 的总高度等于外层 Group 的高度
            NSCollectionLayoutSize *verticalGroupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:0.5] heightDimension:[NSCollectionLayoutDimension absoluteDimension:200]];
            NSCollectionLayoutGroup *verticalGroup = [NSCollectionLayoutGroup verticalGroupWithLayoutSize:verticalGroupSize subitems:@[item, item]];
            // 设置垂直 Group 内 items 之间的间距（行间距）
            verticalGroup.interItemSpacing = [NSCollectionLayoutSpacing fixedSpacing:10];
            
            // 3. 创建外层横向 Group（包含2个垂直 Group，形成2列）
            // 宽度设置为固定值（比如屏幕宽度的 0.85 或固定宽度），这样多个 Group 可以横向滚动
            NSCollectionLayoutSize *horizontalGroupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:350] heightDimension:[NSCollectionLayoutDimension absoluteDimension:200]];
            NSCollectionLayoutGroup *horizontalGroup = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:horizontalGroupSize subitems:@[verticalGroup, verticalGroup]];
            // 设置横向 Group 内垂直 Groups 之间的间距（列间距）
            horizontalGroup.interItemSpacing = [NSCollectionLayoutSpacing fixedSpacing:10];
            
            // 4. 创建 Section 并设置横向滚动
            NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:horizontalGroup];
            // 【关键】设置横向滚动行为，让多个 Groups（每个包含2行2列）可以横向滑动
            section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorGroupPaging;
            // 设置多个 Groups 之间的间距（横向滚动时的间距）
            section.interGroupSpacing = 10;
            // 设置 Section 的内容边距
            section.contentInsets = NSDirectionalEdgeInsetsMake(10, 10, 10, 10);
            
            return section;
        } else if (sectionType == CPDCompositionalSectionTypeGroup) {
            NSCollectionLayoutSize *topItemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension absoluteDimension:44]];
            NSCollectionLayoutItem *topItem = [NSCollectionLayoutItem itemWithLayoutSize:topItemSize];

            NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:200] heightDimension:[NSCollectionLayoutDimension absoluteDimension:100]];

            NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension absoluteDimension:100]];
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
            NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[topItem, item]];
            NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
            section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorGroupPaging;
            section.interGroupSpacing = 10;
            section.contentInsets = NSDirectionalEdgeInsetsMake(0, 0, 0, 0);
            return section;
        } else { // CPDCompositionalSectionTypeNormal1x2
            // ========== Compositional Layout 详细解释 ==========
            // 
            // 【核心概念】
            // 1. Item（单元格）：最小的布局单元
            // 2. Group（组）：包含一个或多个 Items
            // 3. Section（区）：包含一个或多个 Groups
            // 
            // 【布局层次结构】
            // Section
            //   └── Group 1
            //         ├── Item 1
            //         └── Item 2
            //   └── Group 2
            //         ├── Item 3
            //         └── Item 4
            //
            // 【关键点】
            // - Group 的方向决定 Group 内 Items 的排列方式
            // - Section 内多个 Groups 的排列方向由 UICollectionView 的滚动方向决定（默认纵向）
            //
            // 【一行2列的实现原理】
            // 方案：使用 horizontalGroup，在同一个 Group 内放入 2 个 Items
            // - 每个 Item 宽度 = 0.5（占屏幕宽度的一半）
            // - Group 宽度 = 1.0（占满整个屏幕宽度）
            // - 这样 2 个 Items 会在 Group 内横向排列，形成一行2列
            
            // 每个 item 的宽度设置为屏幕宽度的 50%（一行2列）
            NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:0.5] heightDimension:[NSCollectionLayoutDimension absoluteDimension:100]];
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
            // 设置 item 的内边距（可选）
            // item.contentInsets = NSDirectionalEdgeInsetsMake(5, 5, 5, 5);
            
            // Group 的宽度必须设置为 1.0（占满整个屏幕宽度）
            // 这样才能让 2 个 Items（每个 0.5 宽度）在同一行显示
            NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension absoluteDimension:100]];
            
            // 【重要】使用 horizontalGroup：Items 在 Group 内横向排列
            // 创建一个包含 2 个 items 的横向 Group
            // 当有多个 items 时，系统会为每 2 个 items 创建一个 Group
            NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item, item]];
            
            // 设置 Group 内 Items 之间的间距（横向间距，即列之间的间距）
            group.interItemSpacing = [NSCollectionLayoutSpacing fixedSpacing:10];
            
            NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
            // 设置 Section 内 Groups 之间的间距（多个 Groups 纵向排列时的行间距）
            section.interGroupSpacing = 15;
            // 设置 Section 的内容边距
            section.contentInsets = NSDirectionalEdgeInsetsMake(10, 10, 10, 10);
            return section;
        }
    } configuration:layoutConfig];
    return layout;
}

#pragma mark - UICollectionViewDelegate



@end
