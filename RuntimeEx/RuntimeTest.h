//
//  RuntimeTest.h
//  RuntimeEx
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

@interface RuntimeTest : NSObject

-(NSString *) testMethod:(Method)method array:(NSArray*)array integer:(NSInteger)integer;

-(void) testVoidMethod:(Method)method array:(NSArray*)array doubleValue:(double)d;

-(void) testVoidMethod2:(Method)method array:(NSArray*)array integer:(int)integer doubleValue:(double)d;
@end
