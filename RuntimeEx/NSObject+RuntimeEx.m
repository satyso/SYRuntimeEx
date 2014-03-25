//
//  NSObject+RuntimeEx.m
//  RuntimeEx
//
//  Created by satyso on 14-2-13.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//
#import <objc/runtime.h>

#import "NSObject+RuntimeEx.h"

#import "BlockDefine.h"

#import "Util.h"


static void vfunc(id self,SEL sel, ...);

#define KExtraBlockArrayKey @"KExtraBlockArrayKey"

#define PRIVATESEL(selName)  [NSString stringWithFormat:@"songyi@satyso%@", selName]

////////////////////////////////////////////////////////////private

void** getArguList(va_list list, NSMethodSignature* methodSignature);

unsigned long long* getUnsignedIntegerValue(va_list list, const char* type);

double* getDoubleValue(va_list list, const char* type);

void** getPointValue(va_list list, const char* type);

void** getObjectValue(va_list list, const char* type);

////////////////////////////////////////////////////////////


@implementation NSObject (RuntimeEx)

-(BOOL)beforeSelReturn:(SEL)sel executeBlock:(block_t)extraBlock
{
    if ([self respondsToSelector:sel] == NO)
    {
        AssertEx(0, @"lookup the sel");
        return NO;
    }
    
    
    Method origMethod = class_getInstanceMethod([self class], sel);
    
    const char* encoding = method_getTypeEncoding(origMethod);
    
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:encoding];
    
    if (strcmp([methodSignature methodReturnType], @encode(void)) == 0)
    {
        IMP impl = class_replaceMethod([self class], sel, (IMP)vfunc, encoding);
        
        NSString* selName = NSStringFromSelector(sel);
        NSString* newSelName = PRIVATESEL(selName);
        
        class_addMethod([self class], NSSelectorFromString(newSelName), impl, encoding);
        
        NSMutableDictionary *observers = objc_getAssociatedObject(self, KExtraBlockArrayKey);
        if (observers == nil)
        {
            observers = [NSMutableDictionary dictionary];
            objc_setAssociatedObject(self, KExtraBlockArrayKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [observers setObject:extraBlock forKey:NSStringFromSelector(sel)];
        
        return YES;
    }
    else
    {
        AssertEx(0,@"only support void return type");
        return NO;
    }
    
    
}


@end

//怀疑不定参数是拿函数调用栈里的连续内存空间做的参数，所以以下方式不能再插入调用任何函数调用，否则有意想不到结果。
//    va_start(list, sel);
//    id result = impl(self, sel, list);
//    va_end(list);
//    return result;
//你可以通过    NSString* str = [[NSString alloc] initWithFormat:@"%p%@%d" arguments:list];看，也可以通过地址运算看

void vfunc(id self,SEL sel, ...)
{
    
    NSDictionary *observers = objc_getAssociatedObject(self, KExtraBlockArrayKey);
    block_t extraBlock = [observers objectForKey:NSStringFromSelector(sel)];
    
    Method origMethod = class_getInstanceMethod([self class], sel);
    
    const char* encoding = method_getTypeEncoding(origMethod);
    
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:encoding];

    va_list list;
    
    va_start(list, sel);
    
    void** arguList = getArguList(list, methodSignature);
    va_end(list);
    //            thx NSInvocation!!!!!!!!
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    NSString* selName = NSStringFromSelector(sel);
    NSString* newSelName = PRIVATESEL(selName);
    [invocation setSelector:NSSelectorFromString(newSelName)];
    
    for (int i = 0; i + 2 < [methodSignature numberOfArguments]; i++)
    {
        [invocation setArgument:arguList[i] atIndex:i + 2];
    }
    [invocation retainArguments];
    [invocation invoke];
    
    for (int i = 0; i <(int)[methodSignature numberOfArguments] - 2; i++)
    {
        free(arguList[i]);
    }
    free(arguList);
    
    extraBlock();
}

void** getArguList(va_list list, NSMethodSignature* methodSignature)
{
    int arguNum = (int)[methodSignature numberOfArguments] - 2;
    void** arguAddress = malloc(sizeof(void*) * arguNum);
    
    for (int i = 0; i < arguNum; i++)
    {
        const char* type = [methodSignature getArgumentTypeAtIndex:2 + i];
        switch (type[0]) {
            case 'c'://case 里 不让 显视alloc
            case 'i':
            case 's':
            case 'B':
            case 'C':
            case 'S':
            case 'l':
            case 'q':
            case 'I':
            case 'L':
            case 'Q':
                arguAddress[i] = getUnsignedIntegerValue(list, type);
                break;
            case 'f':
            case 'd':
                arguAddress[i] = getDoubleValue(list, type);
                break;
            case '*':
            case '^':
                arguAddress[i] = getPointValue(list, type);
                break;
            case '@':
            case '#':
            case ':':
                arguAddress[i] = getObjectValue(list, type);
                break;
            default:
                break;
        }
    }
    return arguAddress;
}

unsigned long long* getUnsignedIntegerValue(va_list list, const char* type)
{
    unsigned long long* result = (unsigned long long*)malloc(sizeof(unsigned long long));
    switch (*type) {
        case 'c':
        case 'i':
        case 's':
        case 'B':
        case 'C':
        case 'S':
            *result = va_arg(list, int);
            break;
        case 'l':
            *result = va_arg(list, long);
            break;
        case 'q':
            *result = va_arg(list, long long);
            break;
        case 'I':
            *result = va_arg(list, unsigned int);
            break;
        case 'L':
            *result = va_arg(list, unsigned long);
            break;
        case 'Q':
            *result = va_arg(list, unsigned long long);
            break;
        default:
            break;
    }
    return result;
}

double* getDoubleValue(va_list list, const char* type)
{
    double* result = (double*)malloc(sizeof(double));
    switch (*type) {
        case 'f':
        case 'd':
            *result = va_arg(list, double);
            break;
        default:
            break;
    }
    return result;
}

void** getPointValue(va_list list, const char* type)
{
    void** result = (void**)malloc(sizeof(void*));
    switch (*type) {
        case '*':
        case '^':
            *result = va_arg(list, void*);
            break;
        default:
            break;
    }
    return result;
}

void** getObjectValue(va_list list, const char* type)
{
    void** result = (void**)malloc(sizeof(id));
    switch (*type) {
        case '@':
        case '#':
        case ':':
            *result = (__bridge void*)va_arg(list, id);
            break;
        default:
            result = nil;
            break;
    }
    return result;
}

