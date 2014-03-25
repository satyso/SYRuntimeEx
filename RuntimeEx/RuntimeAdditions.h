//
//  RuntimeAdditions.h
//  RuntimeEx
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @  exchanged originalSelector and newSelector.
 */

BOOL classEx_exchangeMethod(Class c, SEL originalSEL, SEL newSEL);

/**
 @ replace originalSelector with block.
 */

BOOL classEx_replaceMethodWithBlock(Class c, SEL originalSEL, id block);

/**
 @ add new method with block
 */

BOOL classEx_addMethodWithBlock(Class c, NSString* selString, id block);

