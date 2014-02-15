//
//  main.c
//  RuntimeEx
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RuntimeAdditions.h"

#import <objc/runtime.h>

#import "RuntimeTest.h"

#import "NSObject+RuntimeEx.h"

@interface RuntimeTest (ex)

-(NSString *) newTestMethod:(Method)method array:(NSArray*)array integer:(NSInteger)integer;

@end

@implementation RuntimeTest (ex)

-(NSString *) newTestMethod:(Method)method array:(NSArray*)array integer:(NSInteger)integer
{
    return @"new testMethod";
}

@end



int main(int argc, const char * argv[])
{

    // insert code here...
    
    @autoreleasepool
    {
        RuntimeTest* test = [RuntimeTest new];

        {//exchange Method via method
            NSLog(@"exchange Method via method          begin");
            
            classEx_exchangeMethod([RuntimeTest class], @selector(testMethod:array:integer:), @selector(newTestMethod:array:integer:));
            
            NSLog(@"%@", [test testMethod:NULL array:@[@1,@2,@3] integer:11111]);
            NSLog(@"%@", [test newTestMethod:NULL array:@[@1,@2,@3] integer:11111]);
            
            NSLog(@"exchange Method via method          end");
        }
        
        {//replace Method via block
            NSLog(@"replace Method via block          begin");
            
            NSLog(@"%@", [test testMethod:NULL array:nil integer:0]);
            
            classEx_replaceMethodWithBlock([RuntimeTest class], @selector(testMethod:array:integer:), ^NSString*(__weak id self, Method m, NSArray* a, NSInteger i){
                NSLog(@"array = %@", a);
                NSLog(@"int = %ld", i);
                return @"classEx_replaceMethodWithBlock";
            });
            NSLog(@"%@", [test testMethod:NULL array:@[@1,@2,@3] integer:11111]);
            
            NSLog(@"replace Method via block          end");
        }

        {//add method
            NSLog(@"add method          begin");
            
            NSString* newMethod = @"newStr:";
            classEx_addMethodWithBlock([RuntimeTest class], newMethod, ^NSString*(__weak id self, NSString* str, NSArray* array){
                NSLog(@"newStr = %@", str);
                NSLog(@"newArray = %@", array);
                
                return @"classEx_addMethodWithBlock";
            });
            
            if ([test respondsToSelector:NSSelectorFromString(newMethod)])
            {//no leak,IDE error
                NSLog(@"%@",[test performSelector:NSSelectorFromString(newMethod) withObject:@"hello" withObject:@[@1,@2,@3]]);
            }
            
            NSLog(@"add method          end");
        }
        
        {
            [test ifSELWillBeReturned:@selector(testVoidMethod2:array:integer:doubleValue:) executeOperation:^{
                NSLog(@"add operation");
            }];
            
            
            [test testVoidMethod2:Nil array:@[@1,@2] integer:5 doubleValue:9.9];
        }
    }
    
    return 0;
}

