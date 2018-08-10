//
//  OperationOne.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/9/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "OperationOne.h"

@implementation OperationOne

- (void)start
{
    self.message = @"MESSAGE FROM OPERATION ONE PROPERTY";
    [super start];
}

@end
