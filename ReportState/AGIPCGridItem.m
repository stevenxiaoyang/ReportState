//
//  AGIPCGridItem.m
//  AGImagePickerController
//
//  Created by Artur Grigor on 17.02.2012.
//  Copyright (c) 2012 - 2013 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGIPCGridItem.h"

#import "AGImagePickerController+Helper.h"
#import "UIButton+AGIPC.h"

@interface AGIPCGridItem ()
{
    __ag_weak AGImagePickerController *_imagePickerController;
    ALAsset *_asset;
    id<AGIPCGridItemDelegate> __ag_weak _delegate;
    
    BOOL _selected;
    
    UIImageView *_thumbnailImageView;
    UIView *_selectionView;
    //UIImageView *_checkmarkImageView;
    UIButton *_checkmarkImageView;
}

@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UIView *selectionView;
//@property (nonatomic, strong) UIImageView *checkmarkImageView;
@property (nonatomic, strong) UIButton *checkmarkImageView;

+ (void)resetNumberOfSelections;

@end

static NSUInteger numberOfSelectedGridItems = 0;

@implementation AGIPCGridItem

#pragma mark - Properties

@synthesize imagePickerController = _imagePickerController, delegate = _delegate, asset = _asset, selected = _selected, thumbnailImageView = _thumbnailImageView, selectionView = _selectionView, checkmarkImageView = _checkmarkImageView;

- (void)setSelected:(BOOL)selected
{
    @synchronized (self)
    {
        if (_selected != selected)
        {
            if (selected) {
                // Check if we can select
                if ([self.delegate respondsToSelector:@selector(agGridItemCanSelect:)])
                {
                    if (![self.delegate agGridItemCanSelect:self])
                        return;
                }
            }
            
            _selected = selected;
            
            //self.selectionView.hidden = !_selected;
            //self.checkmarkImageView.hidden = !_selected;
            if (self.selected) {
                //[self.checkmarkImageView setImage:[UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-1"] forState:UIControlStateNormal];
                [self.checkmarkImageView setImageWithAnimation:[UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-1"] forState:UIControlStateNormal];
            } else {
                [self.checkmarkImageView setImage:[UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-0"] forState:UIControlStateNormal];
            }
            
            if (_selected)
            {
                numberOfSelectedGridItems++;
            }
            else
            {
                if (numberOfSelectedGridItems > 0)
                    numberOfSelectedGridItems--;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                if ([self.delegate respondsToSelector:@selector(agGridItem:didChangeSelectionState:)])
                {
                    [self.delegate performSelector:@selector(agGridItem:didChangeSelectionState:) withObject:self withObject:@(_selected)];
                }
                
                if ([self.delegate respondsToSelector:@selector(agGridItem:didChangeNumberOfSelections:)])
                {
                    [self.delegate performSelector:@selector(agGridItem:didChangeNumberOfSelections:) withObject:self withObject:@(numberOfSelectedGridItems)];
                }
                
            });
        }
    }
}

- (BOOL)selected
{
    BOOL ret;
    @synchronized (self) { ret = _selected; }
    
    return ret;
}

- (void)setAsset:(ALAsset *)asset
{
    @synchronized (self)
    {
        if (_asset != asset)
        {
            _asset = asset;
        }
    }
}

- (ALAsset *)asset
{
    ALAsset *ret = nil;
    @synchronized (self) { ret = _asset; }
    
    return ret;
}

#pragma mark - Object Lifecycle

- (id)initWithImagePickerController:(AGImagePickerController *)imagePickerController andAsset:(ALAsset *)asset
{
    self = [self initWithImagePickerController:imagePickerController asset:asset andDelegate:nil];
    return self;
}

- (id)initWithImagePickerController:(AGImagePickerController *)imagePickerController asset:(ALAsset *)asset andDelegate:(id<AGIPCGridItemDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.imagePickerController = imagePickerController;
        
        self.selected = NO;
        self.delegate = delegate;
        
        CGRect frame = self.imagePickerController.itemRect;
        CGRect checkmarkFrame = [self.imagePickerController checkmarkFrameUsingItemFrame:frame];
        
        self.thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

		[self addSubview:self.thumbnailImageView];
        
        //self.selectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

        //[self addSubview:self.selectionView];
        
        //self.checkmarkImageView = [[UIImageView alloc] initWithFrame:checkmarkFrame];
        self.checkmarkImageView = [[UIButton alloc] initWithFrame:checkmarkFrame];
        
        [self addSubview:self.checkmarkImageView];
        
        // 多增加对打钩的tap手势响应，springox(20140520)
        [self.checkmarkImageView addTarget:self action:@selector(tapCheckMark) forControlEvents:UIControlEventTouchUpInside];
        
        self.asset = asset;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.thumbnailImageView.contentMode = UIViewContentModeScaleToFill;

    //self.selectionView.backgroundColor = [UIColor whiteColor];
    //self.selectionView.alpha = .5f;
    //self.selectionView.hidden = !self.selected;

    //if (IS_IPAD())
    //self.checkmarkImageView.image = [UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-iPad"];
    //else
    //self.checkmarkImageView.image = [UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-iPhone"];
    //self.checkmarkImageView.hidden = !self.selected;
    if (self.selected) {
        [self.checkmarkImageView setImage:[UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-1"] forState:UIControlStateNormal];
    } else {
        [self.checkmarkImageView setImage:[UIImage imageNamed:@"AGImagePickerController.bundle/AGIPC-Checkmark-0"] forState:UIControlStateNormal];
    }
}

// Drawing must be exectued in main thread. springox(20131218)
- (void)loadImageFromAsset
{
    self.thumbnailImageView.image = [UIImage imageWithCGImage:_asset.thumbnail];
    if ([self.imagePickerController.selection containsObject:self]) {
        self.selected = YES;
    }
}

#pragma mark - Others

- (void)tap:(id)sender
{
    UITapGestureRecognizer *gesRecongnizer = (UITapGestureRecognizer *)sender;
    if (UIGestureRecognizerStateEnded == gesRecongnizer.state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([self.delegate respondsToSelector:@selector(agGridItemDidTapAction:)])
            {
                [self.delegate performSelector:@selector(agGridItemDidTapAction:) withObject:self];
            }
            else
            {
                [self tapCheckMark];
            }
            
        });
    }
}

- (void)tapCheckMark
{
    self.selected = !self.selected;
    if ([self.delegate respondsToSelector:@selector(agGridItemDidTapCheckMarkAction:)])
    {
        [self.delegate performSelector:@selector(agGridItemDidTapCheckMarkAction:) withObject:self];
    }
}

#pragma mark - Private

+ (void)resetNumberOfSelections
{
    numberOfSelectedGridItems = 0;
}

+ (NSUInteger)numberOfSelections
{
    return numberOfSelectedGridItems;
}

@end
