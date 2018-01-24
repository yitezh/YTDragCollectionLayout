//
//  DFZFBLayout.h
//  collectionPanViewTest
//
//  Created by ytz on 2018/1/24.
//  Copyright © 2018年 ytz. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kScreenHeight   [UIScreen mainScreen].bounds.size.height
@protocol DFZFBLayoutDelegate <NSObject>

//移动数据源
- (void)mp_moveDataItem:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath;
//删除数据源  
- (void)mp_removeDataObjectAtIndex:(NSIndexPath *)index;
- (CGRect)mp_RectForDelete;
@optional
- (void)mp_didMoveToDeleteArea;
- (void)mp_didLeaveToDeleteArea;

- (NSArray<NSIndexPath *> *)mp_disableMoveItemArray;
@end

@interface MPGestureLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) id<DFZFBLayoutDelegate> delegate;

@end


