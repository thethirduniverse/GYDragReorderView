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

#import "ViewController.h"

@interface ViewController () <GYDragReorderViewProtocol>

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
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

}

-(void)reorderView:(GYDragReorderView *)reorderView didMoveItemAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex{
    NSLog(@"%d -> %d\n", oldIndex, newIndex);
}

 //if enabled this will only allow a view to move at most 1 position at a time
-(BOOL)reorderView:(GYDragReorderView *)reorderView shouldMoveItemAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex{
    if (newIndex == oldIndex) {
        return true;
    }
    if (newIndex - oldIndex ==1 || oldIndex - newIndex == 1) {
        return true;
    }
    return false;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
