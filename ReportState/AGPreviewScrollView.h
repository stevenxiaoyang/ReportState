//
//  AGPreviewScrollView.h
//  AGImagePickerController Demo
//
//  Created by SpringOx on 14/11/1.
//  Copyright (c) 2014年 Artur Grigor. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AGImagePickerControllerDefines.h"

@class AGPreviewScrollView;

@protocol AGPreviewScrollViewDelegate <NSObject>

- (NSInteger)previewScrollViewNumberOfImage:(AGPreviewScrollView *)scrollView;

- (CGSize)previewScrollViewSizeOfImage:(AGPreviewScrollView *)scrollView;

- (NSUInteger)previewScrollViewCurrentIndexOfImage:(AGPreviewScrollView *)scrollView;

- (UIImage *)previewScrollView:(AGPreviewScrollView *)scrollView imageAtIndex:(NSUInteger)index;

- (void)previewScrollView:(AGPreviewScrollView *)scrollView didScrollWithCurrentIndex:(NSUInteger)index;

@end

@interface AGPreviewScrollView : UIScrollView

@property (nonatomic, ag_weak) id<AGPreviewScrollViewDelegate, NSObject> preDelegate;

- (id)initWithFrame:(CGRect)frame preDelegate:(id)preDelegate;

- (NSInteger)currentIndexOfImage;

- (void)resetContentViews;

@end
