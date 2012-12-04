//
//  LocationCell.m
//  Locations
//
//  Created by Xingyin Zhu on 12-12-4.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//

#import "LocationCell.h"

@implementation LocationCell

@synthesize descriptionLabel, addressLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
