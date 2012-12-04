//
//  LocationsViewController.h
//  Locations
//
//  Created by Xingyin Zhu on 12-12-4.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationsViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
