//
//  CategoryPickerViewController.h
//  Locations
//
//  Created by Xingyin Zhu on 12-12-3.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//


@class CategoryPickerViewController;

@protocol CategoryPickerViewControllerDelegate <NSObject>

- (void)categoryPicker:(CategoryPickerViewController *)picker didPickCategory:(NSString *)categoryName;

@end

@interface CategoryPickerViewController : UITableViewController

@property (nonatomic, weak) id <CategoryPickerViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedCategoryName;

@end
