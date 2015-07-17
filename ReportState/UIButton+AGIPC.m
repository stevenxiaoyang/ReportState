//
//  UIButton+AGIPC.m
//  AGImagePickerController Demo
//
//  Created by SpringOx on 14/11/18.
//  Copyright (c) 2014年 Artur Grigor. All rights reserved.
//

#import "UIButton+AGIPC.h"

@implementation UIButton (AGIPC)

- (void)setImageWithAnimation:(UIImage *)image forState:(UIControlState)state
{
    [self setImage:image forState:state];
    [self fireAnimationWithDuration:0.2f];
}

- (void)fireAnimationWithDuration:(CFTimeInterval)duration
{
    CAKeyframeAnimation *animaiton = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CATransform3D transform0 = CATransform3DMakeScale(1, 1, 1);
    CATransform3D transform1 = CATransform3DMakeScale(1.26, 1.26, 1.26);
    CATransform3D transform2 = CATransform3DMakeScale(1, 1, 1);
    NSValue *value1 = [NSValue valueWithCATransform3D:transform0];
    NSValue *value2 = [NSValue valueWithCATransform3D:transform1];
    NSValue *value3 = [NSValue valueWithCATransform3D:transform2];
    NSArray *values = @[value1, value2, value3];
    animaiton.values = values;
    animaiton.duration = duration;
    animaiton.repeatCount = 0;      //    #define    HUGE_VALF    1e50f
    
    [self.layer addAnimation:animaiton forKey:@"AnimationForTransform"];
}

@end
