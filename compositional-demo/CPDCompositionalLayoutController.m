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

@interface CPDCompositionalLayoutController ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSString *> *bannerArray;
@property (nonatomic, strong) NSMutableArray *section1DataArray;
@property (nonatomic, strong) NSMutableArray<CPDCompositionalGroupObject *> *section2DataArray;
@property (nonatomic, strong) NSMutableArray *section3DataArray;
@end

@implementation CPDCompositionalLayoutController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _bannerArray = [NSMutableArray arrayWithObjects:@"",@"",@"",@"",@"", nil];
    _section1DataArray = [NSMutableArray arrayWithObjects:@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"", nil];
    NSMutableArray<CPDCompositionalGroupObject *> *array = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
        [array addObject:[CPDCompositionalGroupObject new]];
    }
    _section2DataArray = array;
    
    _section3DataArray = [NSMutableArray arrayWithObjects:@"",@"",@"",@"",@"",@"",@"",@"",@"",@"", nil];
    
    [self setupUI];
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
    _collectionView.dataSource = self;
}

- (UICollectionViewCompositionalLayout *)createLayout {
    UICollectionViewCompositionalLayoutConfiguration *layoutConfig = [UICollectionViewCompositionalLayoutConfiguration new];
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        if (sectionIndex == 0) {
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
        }else if (sectionIndex == 1) { // normal, 一个group,2行2列，且横向滑动
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
        } else if (sectionIndex == 2) {
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
        } else {
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

#pragma makr - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 4;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) { // banner
        return self.bannerArray.count;
    } else if (section == 1) { // normal, 一个group,2行2列
        return self.section1DataArray.count;
    } else if (section == 2) {
        return self.section2DataArray.count;
    } else {
        return self.section3DataArray.count; // normal, 1行2列
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { // banner
        CPDCompositionalLayoutBannerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutBannerCell" forIndexPath:indexPath];
        return cell;
    } else if (indexPath.section == 1) { // normal, 一个group,2行2列
        CPDCompositionalLayoutNormalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutNormalCell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor redColor];
        return cell;
    } else if (indexPath.section == 2) { //
        CPDCompositionalLayoutGroupCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutGroupCell" forIndexPath:indexPath];
        return cell;
    } else { // normal, 1行2列
        CPDCompositionalLayoutNormalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPDCompositionalLayoutNormalCell" forIndexPath:indexPath];
        return cell;
    }
}

#pragma makr - UICollectionViewDelegate



@end
