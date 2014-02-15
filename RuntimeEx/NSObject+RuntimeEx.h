//
//  NSObject+RuntimeEx.h
//  RuntimeEx
//
//  Created by satyso on 14-2-13.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^block_t)(void);

@interface NSObject (RuntimeEx)

/**
 @  execute block before SEL return
 */

-(BOOL)ifSELWillBeReturned:(SEL)sel executeOperation:(block_t)extraBlock;

@end
