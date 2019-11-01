//
//  YTDragCollectionLayout.m
//  collectionPanViewTest
//
//  Created by ytz on 2018/1/24.
//  Copyright © 2018年 ytz. All rights reserved.
//

#import "YTDragCollectionLayout.h"

typedef NS_ENUM(NSInteger,GestureOperation) {
    GestureOperationNone = 0,
    GestureOperationChange,
    GestureOperationDelete,
};


@interface YTDragCollectionLayout ()<UIGestureRecognizerDelegate> {
    GestureOperation operation;
}

@property (nonatomic, strong) UILongPressGestureRecognizer * longPress;
@property (nonatomic, strong) NSIndexPath * currentIndexPath;
@property (nonatomic, strong) UIView * snapImageView;

@end

@implementation YTDragCollectionLayout

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureObserver];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self configureObserver];
    }
    return self;
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"collectionView"];
}

#pragma mark - setup

- (void)configureObserver{
    [self addObserver:self forKeyPath:@"collectionView" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setUpGestureRecognizers{
    if (self.collectionView == nil) {
        return;
    }
    _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];
    _longPress.minimumPressDuration = 0.2f;
    _longPress.delegate = self;
    [self.collectionView addGestureRecognizer:_longPress];
}

#pragma mark - observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"collectionView"]) {
        [self setUpGestureRecognizers];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)longPress
{
    UIView *touchView = [self getMoveMainView];
 
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [longPress locationInView:self.collectionView];
            NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:location];
            BOOL canMove = [self canMoveItemInIndexPath:indexPath];
            
            if(!indexPath||!canMove||operation!=GestureOperationNone) {
                return ;
            }
            
            self.currentIndexPath = indexPath;
            UICollectionViewCell* targetCell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
            UIView* cellView = [targetCell snapshotViewAfterScreenUpdates:YES];
            self.snapImageView = cellView;
            self.snapImageView.frame = cellView.frame;
            targetCell.hidden = YES;
            
            [touchView addSubview:self.snapImageView];
            //转为窗体坐标
            CGPoint center = [self.collectionView convertPoint:targetCell.center toView:touchView];
            cellView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            cellView.center = center;
            [self beginGesture];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if(!self.snapImageView) return;
            
            CGPoint point = [longPress locationInView:self.collectionView];
            CGPoint center = [longPress locationInView:touchView];
            self.snapImageView.center = center;
            NSIndexPath * indexPath = [self.collectionView indexPathForItemAtPoint:point];
            
            if (!indexPath) {   //没滑到其他cell上
                CGRect deleteRect = [self getDeleteArea];
                if ( CGRectIntersectsRect(deleteRect, self.snapImageView.frame)) { //滑到删除区域
                    operation = GestureOperationDelete;
                    [self moveInDeleteArea];
                }
                else {
                    operation = GestureOperationNone;
                    [self leaveDeleteArea];
                }
                return;
            }
            
            BOOL canMove = [self canMoveItemInIndexPath:indexPath];
            if(!canMove) {
                return ;
            }
            
            if (![indexPath isEqual:self.currentIndexPath]&&indexPath)//滑到其他cell上
            {
                operation = GestureOperationChange;
                
                [self.collectionView performBatchUpdates:^{
                [self moveDataFromIndex:self.currentIndexPath toIndexPath:indexPath];
                [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:indexPath];
                } completion:^(BOOL finished) {
                    
                }];
                self.currentIndexPath = indexPath;
            }
        }
        break;
        case UIGestureRecognizerStateEnded:
        {
            
            if(operation== GestureOperationDelete) { //删除操作
                
                if ([self.delegate respondsToSelector:@selector(yt_removeDataObjectAtIndex:)]) {
                    
                    [self.collectionView performBatchUpdates:^{
                        [self.delegate yt_removeDataObjectAtIndex:_currentIndexPath];
                        [self.collectionView deleteItemsAtIndexPaths:@[_currentIndexPath]];
                        [self.snapImageView removeFromSuperview];
                    } completion:^(BOOL finished) {
                        [self resetData];
                    }];
                    
                }
            } else  {   //移动操作
                
                UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
                CGPoint center = [self.collectionView convertPoint:cell.center toView:touchView];
                [UIView animateWithDuration:0.25 animations:^{
                    self.snapImageView.center = center;
                } completion:^(BOOL finished) {
                    [self.snapImageView removeFromSuperview];
                    cell.hidden  = NO;
                    [self resetData];
                    
                }];
            }
            
        }
            break;
        default:
            break;
    }
}

- (void)resetData {
    operation= GestureOperationNone;
    self.snapImageView = nil;
    self.currentIndexPath = nil;
    [self leaveDeleteArea];
    [self endGesture];
    
    //可以reload查看数据源是否正确
    [self.collectionView reloadData];
}

- (void)moveDataFromIndex:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(yt_moveDataItem:toIndexPath:)]) {
        [self.delegate yt_moveDataItem:fromIndex toIndexPath:indexPath];
    }
}

- (BOOL)canMoveItemInIndexPath:(NSIndexPath *)indexPath {
    BOOL canMove = YES;
    if([self.delegate respondsToSelector:@selector(yt_canMoveItemInIndexPath:)]) {
     canMove =  [self.delegate yt_canMoveItemInIndexPath:indexPath];
    }
    return canMove;
}

- (CGRect )getDeleteArea {
    if([self.delegate respondsToSelector:@selector(yt_RectForDelete)]) {
        return [self.delegate yt_RectForDelete];
    }
    
    return CGRectZero;
}



- (void)leaveDeleteArea {
    if([self.delegate respondsToSelector:@selector(yt_didLeaveToDeleteArea)]) {
        return [self.delegate yt_didLeaveToDeleteArea];
    }
}

- (void)moveInDeleteArea {
    if([self.delegate respondsToSelector:@selector(yt_didMoveToDeleteArea)]) {
        return [self.delegate yt_didMoveToDeleteArea];
    }
}

- (void)beginGesture {
    if([self.delegate respondsToSelector:@selector(yt_willBeginGesture)]) {
        return [self.delegate yt_willBeginGesture];
    }
}

- (void)endGesture {
    if([self.delegate respondsToSelector:@selector(yt_didEndGesture)]) {
        return [self.delegate yt_didEndGesture];
    }
}

- (UIView *)getMoveMainView {
    if([self.delegate respondsToSelector:@selector(yt_moveMainView)]) {
        return [self.delegate yt_moveMainView];
    }
    return [UIApplication sharedApplication].keyWindow;
    
    
}




@end


