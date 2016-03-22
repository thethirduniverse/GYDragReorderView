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

#import <UIKit/UIKit.h>
@class GYDragReorderView;


typedef enum : NSUInteger {
    /*
     Horizontal Layouts
     */
    GYDragReorderViewLayoutHorizontalAlignMiddle = 0,
    GYDragReorderViewLayoutHorizontalAlignTop = 1,
    GYDragReorderViewLayoutHorizontalAlignBottom = 2,
    /*
     Vertical Layouts
     */
    GYDragReorderViewLayoutVerticalAlignMiddle = 3,
    GYDragReorderViewLayoutVerticalAlignLeft = 4,
    GYDragReorderViewLayoutVerticalAlignRight = 5,
} GYDragReorderViewLayout;

#define GYDragReorderViewLayoutIsHorizontal(layout) \
    (layout<=GYDragReorderViewLayoutHorizontalAlignBottom)


typedef enum : NSUInteger {
    /*
     The movable part will be solid, and have the same size as 
     the original item
     */
    GYDragReorderViewTypeSnapshotSolid,
    /*
     The movable part will be translucent, and larger than the
     size of the original item
     */
    GYDragReorderViewTypeSnapshotPhantom,
} GYDragReorderViewType;


@protocol GYDragReorderViewProtocol <NSObject>

@optional

/*
 Invoked when user attempts to drag an item
 to a new (or its original) position. You can return true to 
 indicate that this is a valid position, or false to not allow
 this order.
 
 Sample Implementation:
 
 //this will force each item move at most 1 position at a time
 -(BOOL)reorderView:(GYDragReorderView *)reorderView shouldMoveItemAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex{
     if (newIndex == oldIndex) {
         return true;
     }
     if (newIndex - oldIndex == 1 || oldIndex - newIndex == 1) {
         return true;
     }
     return false;
 }
 */
-(BOOL)reorderView:(GYDragReorderView*)reorderView
shouldMoveItemAtIndex:(NSUInteger)oldIndex
           toIndex:(NSUInteger)newIndex;

/*
 Invoked when the touch ended
 */
-(void)reorderView:(GYDragReorderView*)reorderView
didMoveItemAtIndex:(NSUInteger)oldIndex
           toIndex:(NSUInteger)newIndex;

@end


@interface GYDragReorderView : UIView

/*
 Provide an array of UIViews to be displayed and reordered
 */
-(void)setItems:(NSArray*)items;

/*
 Add an UIView item to be displayed and reordered
 */
-(void)addItem:(UIView*)item;

@property (nonatomic, strong, setter=setItems:) NSArray* items;

@property (nonatomic, assign) id<GYDragReorderViewProtocol> delegate;
@property (nonatomic) CGFloat animationDuration;
@property (nonatomic) CGFloat itemPadding;
@property (nonatomic) GYDragReorderViewLayout layout;
@property (nonatomic) GYDragReorderViewType type;
@end
