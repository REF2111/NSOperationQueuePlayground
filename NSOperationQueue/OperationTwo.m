//
//  OperationTwo.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/9/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "OperationTwo.h"

#import "OperationOne.h"

@implementation OperationTwo

- (void)start
{
    NSOperation* operation = [self.dependencies firstObject];
    OperationOne* operationOne = (OperationOne*)operation;
    NSLog(@"%@", operationOne.message);
    [super start];
}

@end
