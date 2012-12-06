//
//  FirstViewController.h
//  Locations
//
//  Created by Xingyin Zhu on 12-12-3.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//


@interface CurrentLocationViewController : UIViewController<CLLocationManagerDelegate>



@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UILabel *latitudeLabel;
@property (nonatomic, strong) IBOutlet UILabel *longitudeLabel;
@property (nonatomic, strong) IBOutlet UILabel *addressLabel;

@property (nonatomic, strong) IBOutlet UIButton *tagButton;
@property (nonatomic, strong) IBOutlet UIButton *getButton;

- (IBAction)getLocation:(id)sender;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;


@property (nonatomic, strong) IBOutlet UILabel *latitudeTextLabel;
@property (nonatomic, strong) IBOutlet UILabel *longitudeTextLabel;
@property (nonatomic, strong) IBOutlet UIView *panelView;

@end
