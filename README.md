# GYDragReorderView
#### Easy solution to achieve the drag to reorder effect. Without the use of UITableView or UICollectionView.

##Demo
![Horizontal Align Middle Phantom](/demo-gifs/horizontal_middle_phantom.gif "Horizontal Align Middle Phantom")
* Horizontal Layout Align Middle Phantom Effect

![Horizontal Align Top Phantom](/demo-gifs/horizontal_top_phantom.gif "Horizontal Align Top Phantom")
* Horizontal Layout Align Top Phantom Effect

![Vertical Align Right Solid](/demo-gifs/vertical_right_normal.gif "Vertical Align Right Solid")
* Vertical Layout Align Right Solid Effect

![Horizontal Aligh Right Phantom](/demo-gifs/vertical_right_phantom.gif "Horizontal Aligh Right Phanto")
* Vertical Layout Align Right Phantom Effect

##Usage
```
GYDragReorderView* dragView = [[GYDragReorderView alloc] initWithFrame:CGRectMake(30, 150, 350, 400)];
    [self.view addSubview:dragView];
    
    [dragView setLayout:GYDragReorderViewLayoutVerticalAlignRight];
    
    [dragView setType:GYDragReorderViewTypeSnapshotSolid];

    [dragView setDelegate:self];
    
    NSMutableArray* items = [[NSMutableArray alloc] init];
    for (int i=0; i<6; i++) {
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40 + 30*i, 10 + 10*i)];
        [view setBackgroundColor:[UIColor colorWithHue:(arc4random()%255)/255.0 saturation:(arc4random()%255)/255.0 brightness:(arc4random()%255)/255.0 alpha:1]];
        [items addObject:view];
    }
    [dragView setItems:items];
```

####Notes
* When adding views to GYDragReorderView, only the size of the view matters. GYDragReorderView does not care about its origin, because it will be reculculated.
* You can potentially add any view to be reordered, but:
  1. the view's `isUserInteractionEnabled` property has to be YES. 
    * For example, this property defaults to be `false` for `UILabel`. If you want to use `UILabel`, you need to set it to true manually.
  2. the view's touch events will never triggered. Because the touch event is always intercepted.

####Delegate
Currently `GYDragReorderViewProtocol` only has two optional callbacks.
* `-(BOOL)reorderView:(GYDragReorderView*)reorderView
shouldMoveItemAtIndex:(NSUInteger)oldIndex
           toIndex:(NSUInteger)newIndex;`
  * You can use this callback to specify whether you want some particular reordering to happen. For example the following code will not allow any view to move beyond one position at a time. 
  ```
-(BOOL)reorderView:(GYDragReorderView *)reorderView shouldMoveItemAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex{
    if (newIndex == oldIndex) {
        return true;
    }
    if (newIndex - oldIndex == 1 || oldIndex - newIndex == 1) {
        return true;
    }
    return false;
}
```
* `-(void)reorderView:(GYDragReorderView*)reorderView
didMoveItemAtIndex:(NSUInteger)oldIndex
           toIndex:(NSUInteger)newIndex;`

####Currently Available GYDragReorderViewLayout:
* GYDragReorderViewLayoutHorizontalAlignMiddle (default)
* GYDragReorderViewLayoutHorizontalAlignTop
* GYDragReorderViewLayoutHorizontalAlignBottom
* GYDragReorderViewLayoutVerticalAlignMiddle
* GYDragReorderViewLayoutVerticalAlignLeft
* GYDragReorderViewLayoutVerticalAlignRight

####Currently Available GYDragReorderViewType:
* GYDragReorderViewTypeSnapshotPhantom
* GYDragReorderViewTypeSnapshotSolid (default)

####Additional Configurable Properties
* `@property (nonatomic) CGFloat animationDuration;` Controls the animation duration. Default is 0.2.
* `@property (nonatomic) CGFloat itemPadding;` Controls how much space will be put between two items. Default is 8.
