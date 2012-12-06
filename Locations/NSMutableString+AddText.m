//
//  NSMutableString+AddText.m
//  Locations
//
//  Created by Xingyin Zhu on 12-12-6.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//

#import "NSMutableString+AddText.h"

@implementation NSMutableString (AddText)

- (void)addText:(NSString *)text withSeparator:(NSString *)separator
{
    if (text != nil)
    {
        if ([self length] > 0)
        {
            [self appendString:separator];
        }
        [self appendString:text];
    }
}

@end
