//
//  YTDragCollectionLayout.h
//  collectionPanViewTest
//
//  Created by ytz on 2018/1/24.
//  Copyright © 2018年 ytz. All rights reserved.
//

#import <UIKit/UIKit.h>
#define YScreenWidth    [UIScreen mainScreen].bounds.size.width
#define YScreenHeight   [UIScreen mainScreen].bounds.size.height
@protocol YTDragCollectionLayoutDelegate <NSObject>



//移动数据源
- (void)yt_moveDataItem:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath;
//删除数据源
- (void)yt_removeDataObjectAtIndex:(NSIndexPath *)index;
//删除区域
- (CGRect)yt_RectForDelete;
@optional

- (BOOL)yt_canMoveItemInIndexPath:(NSIndexPath *)indexPath;

//进出删除区域的操作
- (void)yt_didMoveToDeleteArea;
- (void)yt_didLeaveToDeleteArea;
//手势状态
- (void)yt_willBeginGesture;
- (void)yt_didEndGesture;

//拖动区域的View，不实现则默认为window
- (UIView *)yt_moveMainView;
@end

@interface YTDragCollectionLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) id<YTDragCollectionLayoutDelegate> delegate;

@end


