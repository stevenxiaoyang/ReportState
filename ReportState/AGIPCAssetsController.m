//
//  AGIPCAssetsController.m
//  AGImagePickerController
//
//  Created by Artur Grigor on 17.02.2012.
//  Copyright (c) 2012 - 2013 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGIPCAssetsController.h"

#import "AGImagePickerController+Helper.h"

#import "AGIPCGridCell.h"
#import "AGIPCToolbarItem.h"

#import "AGImagePreviewController.h"
#import "AGIPCPreviewController.h"
@interface AGIPCAssetsController ()<AGIPCPreviewControllerDelegate>
{
    ALAssetsGroup *_assetsGroup;
    NSMutableArray *_assets;
    NSMutableArray *_selectedAssets;
    
    __ag_weak AGImagePickerController *_imagePickerController;
    
    UIInterfaceOrientation lastOrientation;
}

@property (nonatomic, strong) NSMutableArray *assets;

@end

@interface AGIPCAssetsController (Private)

- (void)changeSelectionInformation;

- (void)registerForNotifications;
- (void)unregisterFromNotifications;

- (void)didChangeLibrary:(NSNotification *)notification;
- (void)didChangeToolbarItemsForManagingTheSelection:(NSNotification *)notification;

- (BOOL)toolbarHidden;

- (void)loadAssets;
- (void)reloadData;

- (void)setupToolbarItems;

- (NSArray *)itemsForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)doneAction:(id)sender;
- (void)selectAllAction:(id)sender;
- (void)deselectAllAction:(id)sender;
- (void)customBarButtonItemAction:(id)sender;

@end

@implementation AGIPCAssetsController

#pragma mark - Properties

@synthesize assetsGroup = _assetsGroup, assets = _assets, imagePickerController = _imagePickerController;

- (BOOL)toolbarHidden
{
    if (! self.imagePickerController.shouldShowToolbarForManagingTheSelection)
        return YES;
    else
    {
        if (self.imagePickerController.toolbarItemsForManagingTheSelection != nil) {
            return !(self.imagePickerController.toolbarItemsForManagingTheSelection.count > 0);
        } else {
            return NO;
        }
    }
}

- (void)setAssetsGroup:(ALAssetsGroup *)theAssetsGroup
{
    @synchronized (self)
    {
        if (_assetsGroup != theAssetsGroup)
        {
            _assetsGroup = theAssetsGroup;
            [_assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];

            // modified by springox(20140510)
            //[self reloadData];
        }
    }
}

- (ALAssetsGroup *)assetsGroup
{
    ALAssetsGroup *ret = nil;
    
    @synchronized (self)
    {
        ret = _assetsGroup;
    }
    
    return ret;
}

- (NSArray *)selectedAssets
{
    if (!_selectedAssets) {
        _selectedAssets = [[NSMutableArray alloc]init];
    }
    else
    {
        [_selectedAssets removeAllObjects];
    }
    
	for (AGIPCGridItem *gridItem in self.assets)
    {		
		if (gridItem.selected)
        {	
			[_selectedAssets addObject:gridItem];
		}
	}
    
    return _selectedAssets;
}

#pragma mark - Object Lifecycle

- (id)initWithImagePickerController:(AGImagePickerController *)imagePickerController andAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        self.assetsGroup = assetsGroup;
        _assets = [[NSMutableArray alloc] init];
        _selectedAssets = [[NSMutableArray alloc] init];
        
        self.imagePickerController = imagePickerController;
        
        self.title = NSLocalizedStringWithDefaultValue(@"AGIPC.Loading", nil, [NSBundle mainBundle], @"Loading...", nil);
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        
        // Setup toolbar items
        [self setupToolbarItems];
        
        // Start loading the assets
        [self loadAssets];
    }
    
    return self;
}

- (void)dealloc
{
    [self unregisterFromNotifications];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (! self.imagePickerController) return 0;
    
    double numberOfAssets = (double)self.assetsGroup.numberOfAssets;
    NSInteger nr = ceil(numberOfAssets / self.imagePickerController.numberOfItemsPerRow);
    
    return nr;
}

- (NSArray *)itemsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.imagePickerController.numberOfItemsPerRow];
    
    NSUInteger startIndex = indexPath.row * self.imagePickerController.numberOfItemsPerRow, 
                 endIndex = startIndex + self.imagePickerController.numberOfItemsPerRow - 1;
    if (startIndex < self.assets.count)
    {
        if (endIndex > self.assets.count - 1)
            endIndex = self.assets.count - 1;
        
        for (NSUInteger i = startIndex; i <= endIndex; i++)
        {
            [items addObject:(self.assets)[i]];
        }
    }
    
    return items;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return self.imagePickerController.itemRect.origin.y;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect itemRect = self.imagePickerController.itemRect;
    return itemRect.size.height + itemRect.origin.y;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    AGIPCGridCell *cell = (AGIPCGridCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {		        
        cell = [[AGIPCGridCell alloc] initWithImagePickerController:self.imagePickerController items:[self itemsForRowAtIndexPath:indexPath] andReuseIdentifier:CellIdentifier];
    }	
	else 
    {		
		cell.items = [self itemsForRowAtIndexPath:indexPath];
	}
    
    return cell;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fullscreen always support Fullscreen
    /*if (self.imagePickerController.shouldChangeStatusBarStyle) {
        self.wantsFullScreenLayout = YES;
    }*/
    
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.allowsSelection = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Navigation Bar Items
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"AGIPC.Cancel", nil, [NSBundle mainBundle], @"取消", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];

    self.navigationItem.rightBarButtonItem = cancelButton;
    
    lastOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // modified by springox(20140510)
    [self reloadData];
    
    // Setup Notifications
    [self registerForNotifications];
    
    // add by springox(20141105)
    [AGIPCGridItem performSelector:@selector(resetNumberOfSelections)];
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
    
    if (lastOrientation != [[UIApplication sharedApplication] statusBarOrientation]) {
        [self reloadData];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self reloadData];
}

// add by springox(20141024)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self reloadData];
}

#pragma mark - Private

- (void)setupToolbarItems
{
    if (self.imagePickerController.toolbarItemsForManagingTheSelection != nil)
    {
        NSMutableArray *items = [NSMutableArray array];
        
        // Custom Toolbar Items
        for (id item in self.imagePickerController.toolbarItemsForManagingTheSelection)
        {
            NSAssert([item isKindOfClass:[AGIPCToolbarItem class]], @"Item is not a instance of AGIPCToolbarItem.");
            
            ((AGIPCToolbarItem *)item).barButtonItem.target = self;
            ((AGIPCToolbarItem *)item).barButtonItem.action = @selector(customBarButtonItemAction:);
            
            [items addObject:((AGIPCToolbarItem *)item).barButtonItem];
        }
        
        self.toolbarItems = items;
    } else {
        // Standard Toolbar Items
        UIBarButtonItem *preViewButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"AGIPC.Preview", nil, [NSBundle mainBundle], @"预览", nil) style:UIBarButtonItemStylePlain target:self action:@selector(previewAction:)];
        preViewButton.enabled = NO;
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"AGIPC.Done", nil, [NSBundle mainBundle], @"完成", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneAction:)];
        doneButton.enabled = NO;
        
        NSArray *toolbarItemsForManagingTheSelection = @[preViewButton, flexibleSpace, doneButton];
        self.toolbarItems = toolbarItemsForManagingTheSelection;
    }
}

- (void)loadAssets
{
    [self.assets removeAllObjects];
    
    __ag_weak AGIPCAssetsController *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        __strong AGIPCAssetsController *strongSelf = weakSelf;
        
        @autoreleasepool {
            [strongSelf.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result == nil) 
                {
                    return;
                }
                if (strongSelf.imagePickerController.shouldShowPhotosWithLocationOnly) {
                    CLLocation *assetLocation = [result valueForProperty:ALAssetPropertyLocation];
                    if (!assetLocation || !CLLocationCoordinate2DIsValid([assetLocation coordinate])) {
                        return;
                    }
                }
                
                AGIPCGridItem *gridItem = [[AGIPCGridItem alloc] initWithImagePickerController:self.imagePickerController asset:result andDelegate:self];
                
                // Descending photos, springox(20131225)
                [strongSelf.assets addObject:gridItem];
                //[strongSelf.assets insertObject:gridItem atIndex:0];

            }];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [strongSelf reloadData];
            
        });
    
    });
}

- (void)reloadData
{
    // Don't display the select button until all the assets are loaded.
    [self.navigationController setToolbarHidden:[self toolbarHidden] animated:YES];
    
    [self.tableView reloadData];
    
    //[self setTitle:[self.assetsGroup valueForProperty:ALAssetsGroupPropertyName]];
    [self changeSelectionInformation];
    
    
    NSInteger totalRows = [self.tableView numberOfRowsInSection:0];
    //Prevents crash if totalRows = 0 (when the album is empty).
    if (totalRows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:totalRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}


- (void)doneAction:(id)sender
{
    //注意self.selectedAssets已经改变
    [self.imagePickerController performSelector:@selector(didFinishPickingAssets:) withObject:self.selectedAssets];
}

-(void)cancelAction:(id)sender
{
    [self.imagePickerController performSelector:@selector(didCancelPickingAssets) withObject:nil];
}

- (void)previewAction:(id)sender
{
    //NSLog(@"%d",[self.assets count]);
    //NSLog(@"%d",[self.selectedAssets count]);

    /*for (AGIPCGridItem *gridItem in self.assets) {
        if (gridItem.selected) {
        }
    }*/
    AGIPCGridItem *gridItem = [self.selectedAssets firstObject];
    AGIPCPreviewController *preController = [[AGIPCPreviewController alloc] initWithAssets:self.selectedAssets targetAsset:gridItem];
    preController.delegate = self;
    preController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:preController animated:YES completion:^{
        // do nothing
    }];
}

- (void)deselectAllAction:(id)sender
{
    for (AGIPCGridItem *gridItem in self.assets) {
        gridItem.selected = NO;
    }
}

- (void)customBarButtonItemAction:(id)sender
{
    for (id item in self.imagePickerController.toolbarItemsForManagingTheSelection)
    {
        NSAssert([item isKindOfClass:[AGIPCToolbarItem class]], @"Item is not a instance of AGIPCToolbarItem.");
        
        if (((AGIPCToolbarItem *)item).barButtonItem == sender)
        {
            if (((AGIPCToolbarItem *)item).assetIsSelectedBlock) {
                
                NSUInteger idx = 0;
                for (AGIPCGridItem *obj in self.assets) {
                    obj.selected = ((AGIPCToolbarItem *)item).assetIsSelectedBlock(idx, ((AGIPCGridItem *)obj).asset);
                    idx++;
                }
                
            }
        }
    }
}

- (void)changeSelectionInformation
{
    if (self.imagePickerController.shouldDisplaySelectionInformation ) {
        if (0 == [AGIPCGridItem numberOfSelections] ) {
            self.navigationController.navigationBar.topItem.prompt = nil;
        } else {
            // Display supports up to select several photos at the same time, springox(20131220)
            NSInteger maxNumber = _imagePickerController.maximumNumberOfPhotosToBeSelected;
            if (0 < maxNumber) {
                self.navigationController.navigationBar.topItem.prompt = [NSString stringWithFormat:@"(%lu/%ld)", (unsigned long)[AGIPCGridItem numberOfSelections], (long)maxNumber];
            } else {
                self.navigationController.navigationBar.topItem.prompt = [NSString stringWithFormat:@"(%lu/%lu)", (unsigned long)[AGIPCGridItem numberOfSelections], (unsigned long)self.assets.count];
            }
        }
    }
}

#pragma mark - AGGridItemDelegate Methods

- (void)agGridItem:(AGIPCGridItem *)gridItem didChangeNumberOfSelections:(NSNumber *)numberOfSelections
{
    ((UIBarButtonItem *)[self.toolbarItems objectAtIndex:0]).enabled = (numberOfSelections.unsignedIntegerValue > 0);
    ((UIBarButtonItem *)[self.toolbarItems objectAtIndex:2]).enabled = (numberOfSelections.unsignedIntegerValue > 0);
    [self changeSelectionInformation];
}

- (BOOL)agGridItemCanSelect:(AGIPCGridItem *)gridItem
{
    if (self.imagePickerController.selectionMode == AGImagePickerControllerSelectionModeSingle && self.imagePickerController.selectionBehaviorInSingleSelectionMode == AGImagePickerControllerSelectionBehaviorTypeRadio) {
        for (AGIPCGridItem *item in self.assets)
            if (item.selected)
                item.selected = NO;
        return YES;
    } else {
        if (self.imagePickerController.maximumNumberOfPhotosToBeSelected > 0)
            return ([AGIPCGridItem numberOfSelections] < self.imagePickerController.maximumNumberOfPhotosToBeSelected);
        else
            return YES;
    }
}

// add by springox(20141023)
- (void)agGridItemDidTapAction:(AGIPCGridItem *)gridItem
{
    // mark the original orientation, springox(20141109)
    lastOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    AGIPCPreviewController *preController = [[AGIPCPreviewController alloc] initWithAssets:self.assets targetAsset:gridItem];
    preController.delegate = self;
    preController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:preController animated:YES completion:^{
        // do nothing
    }];
}

// add by springox(20150712)
- (void)agGridItemDidTapCheckMarkAction:(AGIPCGridItem *)gridItem
{
    if (nil == _selectedAssets) {
        _selectedAssets = [[NSMutableArray alloc] init];
    }
    
    if (gridItem.selected) {
        if ([_selectedAssets containsObject:gridItem]) {
            [_selectedAssets removeObject:gridItem];
        }
        [_selectedAssets addObject:gridItem];
    } else {
        [_selectedAssets removeObject:gridItem];
    }
}

#pragma mark - AGIPCPreviewControllerDelegate Methods

- (void)previewController:(AGIPCPreviewController *)pVC didRotateFromOrientation:(UIInterfaceOrientation)fromOrientation
{
    // do noting
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
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didChangeToolbarItemsForManagingTheSelection:(NSNotification *)notification
{
    NSLog(@"here.");
}

@end
