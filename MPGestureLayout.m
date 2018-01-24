//
//  DFZFBLayout.m
//  collectionPanViewTest
//
//  Created by ytz on 2018/1/24.
//  Copyright © 2018年 ytz. All rights reserved.
//

#import "MPGestureLayout.h"

typedef NS_ENUM(NSInteger,GestureOperation) {
    OptionNone = 0,
    OptionChange,
    OptionDelete,
};


@interface MPGestureLayout ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) UIView *mappingImageCell;
@property (nonatomic, assign)GestureOperation operation;

@end

@implementation MPGestureLayout

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
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [longPress locationInView:self.collectionView];
            NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:location];
            if (!indexPath) return;
            
            NSArray *disableArray =[self getDisableMoveArray];
            if([disableArray containsObject:indexPath]) return ;

            self.currentIndexPath = indexPath;
            UICollectionViewCell* targetCell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
        
            UIView* cellView = [targetCell snapshotViewAfterScreenUpdates:YES];
            self.mappingImageCell = cellView;
            

            self.mappingImageCell.frame = cellView.frame;
            targetCell.hidden = YES;
            
            [[UIApplication sharedApplication].keyWindow addSubview:self.mappingImageCell];
            
            CGPoint center = [self.collectionView convertPoint:targetCell.center toView:nil];
            cellView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            cellView.center = center;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [longPress locationInView:[UIApplication sharedApplication].keyWindow];
            //更新cell的位置
            self.mappingImageCell.center = point;
            NSIndexPath * indexPath = [self.collectionView indexPathForItemAtPoint:point];
            NSArray *disableArray =[self getDisableMoveArray];
            
            if (!indexPath) {
                 CGRect deleteRect = [self getDeleteArea];
                if ( CGRectContainsPoint(deleteRect, point)) {
                    _operation = OptionDelete;
                    [self moveInDeleteArea];
                }
                else {
                    _operation = OptionNone;
                    [self leaveDeleteArea];
                  
                }
                return;
            }
            
            if([disableArray containsObject:indexPath])return ;
            
            if (![indexPath isEqual:self.currentIndexPath])
            {
                 _operation = OptionChange;
                if ([self.delegate respondsToSelector:@selector(mp_moveDataItem:toIndexPath:)]) {
                    [self.delegate mp_moveDataItem:self.currentIndexPath toIndexPath:indexPath];
                }
                [self.collectionView moveItemAtIndexPath:self.currentIndexPath toIndexPath:indexPath];
                self.currentIndexPath = indexPath;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
             if(_operation== OptionDelete) { //删除操作
                if ([self.delegate respondsToSelector:@selector(mp_removeDataObjectAtIndex:)]) {
                    [self.collectionView performBatchUpdates:^{
                          [self.delegate mp_removeDataObjectAtIndex:_currentIndexPath];
                            [self.collectionView deleteItemsAtIndexPaths:@[_currentIndexPath]];
                    } completion:^(BOOL finished) {
                    }];
                    [self.mappingImageCell removeFromSuperview];
                    self.mappingImageCell = nil;
                    self.currentIndexPath = nil;
                }
             } else {   //移动操作
                 UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.currentIndexPath];
                 [UIView animateWithDuration:0.25 animations:^{
                     self.mappingImageCell.center = cell.center;
                 } completion:^(BOOL finished) {
                     [self.mappingImageCell removeFromSuperview];
                     cell.hidden           = NO;
                     self.mappingImageCell = nil;
                     self.currentIndexPath = nil;
                 }];
                 _operation= OptionNone;
                [self leaveDeleteArea];
             }
            
        }
            break;
        default:
        {
            
        }
            break;
    }
}

- (CGRect )getDeleteArea {
    if([self.delegate respondsToSelector:@selector(mp_RectForDelete)]) {
        return [self.delegate mp_RectForDelete];
    }
    
    return CGRectZero;
}

- (NSArray<NSIndexPath *> *)getDisableMoveArray {
    if([self.delegate respondsToSelector:@selector(mp_disableMoveItemArray)]) {
        return [self.delegate mp_disableMoveItemArray];
    }
    return nil;
}

- (void)leaveDeleteArea {
    if([self.delegate respondsToSelector:@selector(mp_didLeaveToDeleteArea)]) {
        return [self.delegate mp_didLeaveToDeleteArea];
    }
}

- (void)moveInDeleteArea {
    if([self.delegate respondsToSelector:@selector(mp_didMoveToDeleteArea)]) {
        return [self.delegate mp_didMoveToDeleteArea];
    }
}

@end


