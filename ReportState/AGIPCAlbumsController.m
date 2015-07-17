//
//  AGIPCAlbumsController.m
//  AGImagePickerController
//
//  Created by Artur Grigor on 2/16/12.
//  Copyright (c) 2012 - 2013 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGIPCAlbumsController.h"

#import "AGImagePickerController.h"
#import "AGIPCAssetsController.h"

@interface AGIPCAlbumsController ()
{
    NSMutableArray *_assetsGroups;
    __ag_weak AGImagePickerController *_imagePickerController;
}

@end

@interface AGIPCAlbumsController ()

- (void)registerForNotifications;
- (void)unregisterFromNotifications;

- (void)didChangeLibrary:(NSNotification *)notification;

- (void)reloadData;

- (void)cancelAction:(id)sender;

@end

@implementation AGIPCAlbumsController

#pragma mark - Properties

@synthesize imagePickerController = _imagePickerController;

- (NSMutableArray *)assetsGroups
{
    if (_assetsGroups == nil)
    {
        _assetsGroups = [[NSMutableArray alloc] init];
    }
    
    return _assetsGroups;
}

#pragma mark - Object Lifecycle

- (id)initWithImagePickerController:(AGImagePickerController *)imagePickerController
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        self.imagePickerController = imagePickerController;
        
        [self assetsGroups];
        
        // avoid deadlock on ios5, delay to handle in viewDidLoad, springox(20140612)
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.f) {
            [self loadAssetsGroups];
        }
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fullscreen
    if (self.imagePickerController.shouldChangeStatusBarStyle) {
        //self.wantsFullScreenLayout = YES;  
    }
    self.title = NSLocalizedStringWithDefaultValue(@"AGIPC.Albums", nil, [NSBundle mainBundle], @"相簿", nil);
    
    // avoid deadlock on ios5, delay to handle in viewDidLoad, springox(20140612)
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.f) {
        [self loadAssetsGroups];
    }
    
    // Setup Notifications
    [self registerForNotifications];
    
    // Navigation Bar Items
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Destroy Notifications
    [self unregisterFromNotifications];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)pushFirstAssetsController
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    @synchronized(self) {
        if (0 < self.assetsGroups.count) {
            AGIPCAssetsController *controller = [[AGIPCAssetsController alloc] initWithImagePickerController:self.imagePickerController andAssetsGroup:self.assetsGroups[0]];
            [self.navigationController pushViewController:controller animated:NO];
        } else {
            static int tryCount;
            if (tryCount < 3) {
                [self performSelector:@selector(pushFirstAssetsController) withObject:nil afterDelay:0.8];
                ++tryCount;
            }
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assetsGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    ALAssetsGroup *group = (self.assetsGroups)[indexPath.row];
    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSUInteger numberOfAssets = group.numberOfAssets;
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [group valueForProperty:ALAssetsGroupPropertyName]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfAssets];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup *)self.assetsGroups[indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	AGIPCAssetsController *controller = [[AGIPCAssetsController alloc] initWithImagePickerController:self.imagePickerController andAssetsGroup:self.assetsGroups[indexPath.row]];
	[self.navigationController pushViewController:controller animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	return 57;
}

#pragma mark - Private

- (void)loadAssetsGroups
{
    __ag_weak AGIPCAlbumsController *weakSelf = self;
    
    [self.assetsGroups removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        @autoreleasepool {
            
            void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
            {
                // filter the value==0, springox(20140502)
                if (group == nil || group.numberOfAssets == 0)
                {
                    return;
                }
                
                @synchronized(weakSelf) {
                    // optimize the sort algorithm by springox(20140327)
                    int groupType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                    if (weakSelf.imagePickerController.shouldShowSavedPhotosOnTop && groupType == ALAssetsGroupSavedPhotos) {
                        [self.assetsGroups insertObject:group atIndex:0];
                    } else {
                        NSUInteger index = 0;
                        for (ALAssetsGroup *g in [NSArray arrayWithArray:self.assetsGroups]) {
                            if (weakSelf.imagePickerController.shouldShowSavedPhotosOnTop && [[g valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
                                index++;
                                continue;
                            }
                            if (groupType > [[g valueForProperty:ALAssetsGroupPropertyType] intValue]) {
                                [self.assetsGroups insertObject:group atIndex:index];
                                break;
                            }
                            index++;
                        }
                        if (![self.assetsGroups containsObject:group]) {
                            [self.assetsGroups addObject:group];
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadData];
                });
            };
            
            void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                NSLog(@"A problem occured. Error: %@", error.localizedDescription);
                [self.imagePickerController performSelector:@selector(didFail:) withObject:error];
            };	
            
            [[AGImagePickerController defaultAssetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:assetGroupEnumerator failureBlock:assetGroupEnumberatorFailure];
        }
        
    });
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)cancelAction:(id)sender
{
    [self.imagePickerController performSelector:@selector(didCancelPickingAssets)];
}

#pragma mark - Notifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(didChangeLibrary:) 
                                                 name:ALAssetsLibraryChangedNotification 
                                               object:[AGImagePickerController defaultAssetsLibrary]];
}

- (void)unregisterFromNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:ALAssetsLibraryChangedNotification 
                                                  object:[AGImagePickerController defaultAssetsLibrary]];
}

- (void)didChangeLibrary:(NSNotification *)notification
{
    [self loadAssetsGroups];
}

@end
