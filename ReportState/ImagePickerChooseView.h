//
//  ImagePickerChooseView.h
//  MyFamily
//
//  Created by 陆洋 on 15/7/15.
//  Copyright (c) 2015年 maili. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^ImagePickerBlock)();
@interface ImagePickerChooseView : UIView
-(id)initWithFrame:(CGRect)frame andAboveView:(UIView *)bgView;
-(void)addImagePickerChooseView;
-(void)setImagePickerBlock:(ImagePickerBlock)block;
-(void)disappear;
@end
