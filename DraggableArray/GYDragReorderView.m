/*
The MIT License (MIT)

Copyright (c) 2016 Guanqing Yan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

#import "GYDragReorderView.h"

typedef enum : NSUInteger {
    GYDragReorderViewStateNormal,
    GYDragReorderViewStateReordering,
} GYDragReorderViewState;

typedef enum : NSUInteger {
    /*
     Indicates that the item is in normal state: solid, visible
     */
    GYArrayReorderItemTypeNormal,
    /*
     Indicates that the item is hidden
     */
    GYArrayReorderItemTypePhantom,
    /*
     Indicates that the item is translucent
     */
    GYArrayReorderItemTypeInvisible,
} GYArrayReorderItemType;


/*
 This view is hacky, but necessary. Whenever we add/remove subview
 the touch event is automatically terminated. In order to have
 continuous touch handling events. We use this proxyview to intercept
 the touch events and forwards them to the actual reorder view.
 In this way, we can both manage subviews on the fly and handle touch
 events without interruption.
 */
@interface GYTouchProxyView : UIView
@property (nonatomic, weak) UIView* targetView;
@end

@implementation GYTouchProxyView

/*
 Even more hacky. Normaally we return true, in order to allow this proxy
 view to receive all the touch events. But if we want to actually do a
 hittest as it the proxy view is not here, we need to forward to hittest
 to the target view. We distinguish whether the event is sent by us or
 the UIKit by whether the event is nil. If it is nil, we treat it as if
 we invoked the method, and therefore return nil.
 */
-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (event == nil) {
        return nil;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.targetView touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.targetView touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.targetView touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.targetView touchesCancelled:touches withEvent:event];
}
@end


@interface GYDragReorderView()

/*
 The internal state of the view
 */
@property (nonatomic) GYDragReorderViewState state;

/*
 The proxy which will forward us all the touch events
 */
@property (nonatomic, strong) GYTouchProxyView* proxy;

/*
 A position indicating the best guess for the currently moving item
 */
@property (nonatomic) NSUInteger currentSnapPosition;

/*
 The current moving item that is being dragged
 */
@property (nonatomic, strong) UIView* currentItem;

/*
 The original index for current moving item,
 if the movement is not allowed by delegate,
 this index will be restored
 */
@property (nonatomic) NSUInteger currentItemOriginalPosition;

/*
 The current Item it self is always inside the views array,
 just not visible. What is being dragged around is this snapshot.
 */
@property (nonatomic, strong) UIImageView* currentItemSnapshot;

/*
 A value indicating how much the phantom snapshot should be zoomed.
 */
@property (nonatomic) CGFloat phantomZoomRate;

-(void)setup;
-(void)layoutItems;
@end

@implementation GYDragReorderView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    [self setup];
    return  self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    [self setup];
    return  self;
}

- (void)setup{
    _items = [[NSMutableArray alloc] init];
    self.itemPadding = 8;
    
    self.animationDuration = 0.2;
    self.phantomZoomRate = 1.4;
    
    [self setClipsToBounds:true];
    
    //we need this, otherwise touch events will end when
    //a subview is removed
    self.proxy = [[GYTouchProxyView alloc] init];
    [self.proxy setTargetView:self];
    [self addSubview:self.proxy];
    
    self.layout = GYDragReorderViewLayoutHorizontalAlignMiddle;
    self.type = GYDragReorderViewTypeSnapshotPhantom;
}

#pragma mark - Public Properties

/*
 though type in interface is NSArray
 we make it a mutable array to support add object operateion
 */
@synthesize items = _items;

- (void)setItems:(NSArray *)items{
    _items = [items mutableCopy];
    for (UIView* item in _items) {
        [self addSubview:item];
    }
    [self setNeedsLayout];
}


- (void)addItem:(UIView*)item{
    [(NSMutableArray*)_items addObject:item];
    [self addSubview:item];
    [self setNeedsLayout];
}

- (NSArray*)items{
    return [NSArray arrayWithArray:_items];
}

#pragma mark - Layout and its helpers

- (void)layoutSubviews{
    if (self.proxy) {
        [self bringSubviewToFront:self.proxy];
        [self.proxy setFrame:self.bounds];
    }
    [self layoutItems];
}

- (CGFloat)totalWidthWithPadding{
    CGFloat width = 0;
    for (UIView* item in _items) {
        width += item.bounds.size.width;
    }
    width += self.itemPadding * (_items.count - 1);
    return width;
}

- (CGFloat)totalHeightWithPadding{
    CGFloat height = 0;
    for (UIView* item in _items) {
        height += item.bounds.size.height;
    }
    height += self.itemPadding * (_items.count - 1);
    return height;
}

- (void)layoutItems{
    
    CGFloat startX = CGRectGetMidX(self.bounds) - [self totalWidthWithPadding]/2;
    CGFloat startY = CGRectGetMidY(self.bounds) - [self totalHeightWithPadding]/2;
    
    CGFloat middleX = CGRectGetMidX(self.bounds);
    CGFloat middleY = CGRectGetMidY(self.bounds);
    
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    for (UIView* item in _items) {
        maxWidth = MAX(maxWidth, CGRectGetWidth(item.frame));
        maxHeight = MAX(maxHeight, CGRectGetHeight(item.frame));
    }
    
    CGFloat maxWidth_2 = maxWidth / 2 ;
    CGFloat maxHeight_2 = maxHeight / 2 ;
    
    for (UIView* item in _items) {
        CGRect frame = [item frame];
        CGFloat itemWidth = frame.size.width;
        CGFloat itemHeight = frame.size.height;
        
        switch (self.layout) {
            case GYDragReorderViewLayoutHorizontalAlignMiddle:
                frame.origin = CGPointMake(startX, middleY - itemHeight/2);
                break;
            case GYDragReorderViewLayoutHorizontalAlignTop:
                frame.origin = CGPointMake(startX, middleY - maxHeight_2);
                break;
            case GYDragReorderViewLayoutHorizontalAlignBottom:
                frame.origin = CGPointMake(startX, middleY + maxHeight_2 - itemHeight);
                break;
            case GYDragReorderViewLayoutVerticalAlignMiddle:
                frame.origin = CGPointMake(middleX - itemWidth/2, startY);
                break;
            case GYDragReorderViewLayoutVerticalAlignLeft:
                frame.origin = CGPointMake(middleX - maxWidth_2, startY);
                break;
            case GYDragReorderViewLayoutVerticalAlignRight:
                frame.origin = CGPointMake(middleX + maxWidth_2 - itemWidth, startY);
                break;
            default:
                assert(false);
        }
        [item setFrame:frame];
        
        if (GYDragReorderViewLayoutIsHorizontal(self.layout)) {
            startX += item.bounds.size.width + self.itemPadding;
        }else{
            startY += item.bounds.size.height + self.itemPadding;
        }
    }
}

- (void)makeSnapshotInsideBounds{
    
    CGPoint center = self.currentItemSnapshot.center;
    CGSize size = self.currentItemSnapshot.bounds.size;
    CGRect transformedBound = CGRectApplyAffineTransform(self.currentItemSnapshot.bounds, self.currentItemSnapshot.transform);
    size = transformedBound.size;
    
    CGRect actualFrame = CGRectMake(center.x - size.width/2, center.y - size.height/2, size.width, size.height);
    
    
    /*
     For horizontal layout, we only check y boundary
     otherwise we might not be able to put some item with big size to the end of the array
     */
    if (GYDragReorderViewLayoutIsHorizontal(self.layout)) {
        if (actualFrame.origin.y < 0) {
            center.y += fabs(actualFrame.origin.y);
        }
        if (actualFrame.origin.y > self.bounds.size.height-size.height) {
            center.y -= fabs(self.bounds.size.height - size.height - actualFrame.origin.y);
        }
    }else{
        if (actualFrame.origin.x < 0) {
            center.x += fabs(actualFrame.origin.x);
        }
        
        if (actualFrame.origin.x > self.bounds.size.width-size.width) {
            center.x -= fabs(self.bounds.size.width - size.width - actualFrame.origin.x);
        }
        
    }
    
    [self.currentItemSnapshot setCenter:center];
}

#pragma mark - Handling Touch Events

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:nil];
    
    CGPoint location = [[touches anyObject] locationInView:self];
    
    //passing nil event deliverately
    //see inplementation of GYTouchProxyView
    UIView* obj = [self hitTest:location withEvent:nil];
    if (obj && obj != self) {
        
        self.state = GYDragReorderViewStateReordering;
        self.currentItem = (UIView*)obj;
        self.currentSnapPosition = [_items indexOfObject:obj];
        self.currentItemOriginalPosition = self.currentSnapPosition;
        [self setType:GYArrayReorderItemTypeInvisible forItem:obj];
        
        UIImage* snapshot = [self imageWithView:obj];
        UIImageView* snapshotView = [[UIImageView alloc] initWithImage:snapshot];
        [snapshotView setCenter:[obj center]];
        
        self.currentItemSnapshot = snapshotView;
        [self addSubview:snapshotView];
        
        if (self.type == GYDragReorderViewTypeSnapshotPhantom) {
            [UIView animateWithDuration:self.animationDuration animations:^{
                [self setType:GYArrayReorderItemTypePhantom forItem:self.currentItemSnapshot];
            }];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    UITouch* touch = [touches anyObject];
    
    if (self.currentItemSnapshot) {
        
        [self updateCurrentSnapshotWithTouch:touch];
        
        NSInteger newIndex = [self getEstimatedPositionFromSnapshotFrame];
        
        if (self.currentSnapPosition != newIndex) {
            
            NSUInteger oldIndex = [_items indexOfObject:self.currentItem];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(reorderView:shouldMoveItemAtIndex:toIndex:)]) {
                if (![self.delegate reorderView:self shouldMoveItemAtIndex:self.currentItemOriginalPosition toIndex:newIndex]) {
                    return;
                }
            }
            
            //temporary reorder items
            [(NSMutableArray*)_items removeObject:self.currentItem];
            [(NSMutableArray*)_items insertObject:self.currentItem atIndex:newIndex];
            
            self.currentSnapPosition = newIndex;
            [UIView animateWithDuration:self.animationDuration animations:^{
                [self layoutItems];
            }];
        }
        
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    
    if (self.currentItemSnapshot) {
        [self endInteraction];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesCancelled:touches withEvent:event];
    
    if (self.currentItemSnapshot) {
        [self endInteraction];
    }
}

#pragma mark - Helpers

- (void)updateCurrentSnapshotWithTouch:(UITouch*)touch{
    CGPoint previousLocation = [touch previousLocationInView:self];
    CGPoint location = [touch locationInView:self];
    
    //we may be using transform, can't use frame here
    CGPoint center = self.currentItemSnapshot.center;
    center.x += location.x - previousLocation.x;
    center.y += location.y - previousLocation.y;
    [self.currentItemSnapshot setCenter:center];
    [self makeSnapshotInsideBounds];
}


- (NSInteger)getEstimatedPositionFromSnapshotFrame{
    NSInteger index = -1;
    
    if (GYDragReorderViewLayoutIsHorizontal(self.layout)) {
        CGFloat midXForMovingView = CGRectGetMidX(self.currentItemSnapshot.frame);
        for (UIView*  item in _items) {
            CGFloat itemMidX = CGRectGetMidX(item.frame);
            if (itemMidX <= midXForMovingView) {
                index ++;
            }else if (item == self.currentItem){
                //index ++;
            }else{
                break;
            }
        }
    }else{
        CGFloat midYForMovingView = CGRectGetMidY(self.currentItemSnapshot.frame);
        for (UIView*  item in _items) {
            CGFloat itemMidY = CGRectGetMidY(item.frame);
            if (itemMidY <= midYForMovingView) {
                index ++;
            }else if (item == self.currentItem){
                //index ++;
            }else{
                break;
            }
        }
    }
    
    index = MAX(index, 0);
    return index;
}

- (void)endInteraction{
    UIView* currentItem = self.currentItem;
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        [self.currentItemSnapshot setCenter:self.currentItem.center];
        [self.currentItemSnapshot setTransform:CGAffineTransformIdentity];
        [self.currentItemSnapshot setAlpha:1];
    } completion:^(BOOL finished) {
        [self.currentItemSnapshot removeFromSuperview];
        self.currentItemSnapshot = nil;
        [self setType:GYArrayReorderItemTypeNormal forItem:self.currentItem];
        self.currentItem = nil;
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(reorderView:didMoveItemAtIndex:toIndex:)]) {
        [self.delegate reorderView:self
                didMoveItemAtIndex:self.currentItemOriginalPosition
                           toIndex:[_items indexOfObject:currentItem]];
    }
    
    self.state = GYDragReorderViewStateNormal;
    self.currentSnapPosition = -1;
}

- (UIImage *) imageWithView:(UIView *)view
{
    BOOL hiddenSave = [view isHidden];
    
    [view setHidden:false];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0);
    
    //default background is black, might be bad for translucent views, like label
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:view.bounds];
    [[UIColor clearColor] setFill];
    [path fillWithBlendMode:kCGBlendModeCopy alpha:1];
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    [view setHidden:hiddenSave];
    return img;
}

- (void) setType:(GYArrayReorderItemType)reorderItemType forItem:(UIView*)item{
    switch (reorderItemType) {
        case GYArrayReorderItemTypeNormal:
            [item setHidden:false];
            [item setAlpha:1];
            break;
        case GYArrayReorderItemTypeInvisible:
            [item setHidden:true];
            break;
        case GYArrayReorderItemTypePhantom:
            [item setTransform:CGAffineTransformMakeScale(self.phantomZoomRate, self.phantomZoomRate)];
            [item setAlpha:0.4];
        default:
            break;
    }
}
@end
