//
//  AGIPCPreviewController.h
//  AGImagePickerController Demo
//
//  Created by SpringOx on 14/11/1.
//  Copyright (c) 2014年 Artur Grigor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AGImagePickerControllerDefines.h"

@class AGIPCPreviewController;
@class AGIPCGridItem;
@protocol AGIPCPreviewControllerDelegate <NSObject>

@optional
- (void)previewController:(AGIPCPreviewController *)pVC didRotateFromOrientation:(UIInterfaceOrientation)fromOrientation;

- (BOOL)previewController:(AGIPCPreviewController *)pVC canSelectItem:(AGIPCGridItem *)gridItem;

- (void)previewController:(AGIPCPreviewController *)pVC didSelectItem:(AGIPCGridItem *)gridItem;

- (void)previewController:(AGIPCPreviewController *)pVC didDeselectItem:(AGIPCGridItem *)gridItem;

@end

@interface AGIPCPreviewController : UIViewController

@property (nonatomic, strong, readonly) AGIPCGridItem *targetAsset;

@property (nonatomic, strong, readonly) NSArray *assets;

@property (nonatomic, ag_weak) id<AGIPCPreviewControllerDelegate, NSObject> delegate;

- (id)initWithAssets:(NSArray *)assets targetAsset:(AGIPCGridItem *)targetAsset;

@end
