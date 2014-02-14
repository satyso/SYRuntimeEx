//
//  RuntimeTest.m
//  RuntimeEx
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#import "RuntimeTest.h"

@implementation RuntimeTest

-(NSString *) testMethod:(Method)method array:(NSArray*)array integer:(NSInteger)integer
{
    return @"original testMethod";
}

-(void) testVoidMethod:(Method)method array:(NSArray*)array doubleValue:(double)d
{
    NSLog(@"testVoidMethod");
    NSLog(@"method = %p, array = %@, double = %lf", method, array, d);
}

-(void) testVoidMethod2:(Method)method array:(NSArray*)array integer:(int)integer doubleValue:(double)d
{
    NSLog(@"testVoidMethod2");
    NSLog(@"method = %p, array = %@, integer = %d, double = %lf", method, array, integer, d);
}

@end
