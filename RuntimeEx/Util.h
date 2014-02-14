//
//  util.h
//  RuntimeEx
//
//  Created by satyso on 14-2-13.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#ifndef RuntimeEx_util_h
#define RuntimeEx_util_h

#define AssertEx(expression, ...) \
do { if(!(expression)) { \
NSLog(@"%@", [NSString stringWithFormat: @"Assertion failure: %s in %s on line %s:%d. %@", #expression, __PRETTY_FUNCTION__, __FILE__, __LINE__, [NSString stringWithFormat:@"" __VA_ARGS__]]); \
abort(); }} while(0)

#endif
