//
//  main.c
//  RuntimeEx
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 ALipay. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RuntimeAdditions.h"

#import <objc/runtime.h>

#import "RuntimeTest.h"


int main(int argc, const char * argv[])
{

    // insert code here...
    @autoreleasepool
    {
        RuntimeTest* test = [RuntimeTest new];
        
        {//replace Method
            NSLog(@"%@", [test testMethod:NULL array:nil integer:0]);
            
            classEx_replaceMethodWithBlock([RuntimeTest class], @selector(testMethod:array:integer:), ^NSString*(__weak id self, Method m, NSArray* a, NSInteger i){
                NSLog(@"%@", self);
                NSLog(@"array = %@", a);
                NSLog(@"int = %ld", i);
                return @"classEx_replaceMethodWithBlock";
            });
            NSLog(@"%@", [test testMethod:NULL array:@[@1,@2,@3] integer:11111]);
        }
        
        {//add method
            NSString* newMethod = @"newStr:";
            classEx_addMethodWithBlock([RuntimeTest class], newMethod, ^NSString*(__weak id self, NSString* str, NSArray* array){
                NSLog(@"newStr = %@", str);
                NSLog(@"newArray = %@", array);
                
                return @"newMethod";
            });
            
            if ([test respondsToSelector:NSSelectorFromString(newMethod)])
            {//no leak,IDE error
                NSLog(@"%@",[test performSelector:NSSelectorFromString(newMethod) withObject:@"hello" withObject:@[@1,@2,@3]]);
            }
        }
    }
    
    system("pause");
    return 0;
}

