//
//  RuntimeAdditions.m
//  simplearray
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

#import <objc/runtime.h>

#import "RuntimeAdditions.h"

#import "BlockDefine.h"
#import "Util.h"


//private
//////////////////////////////////////////////////////////////////

BOOL isSignatureEqual(id block, Method method);

const char* getBlockSignature(id block);

//////////////////////////////////////////////////////////////////

BOOL classEx_exchangeMethod(Class c, SEL originalSEL, SEL newSEL)
{
    Method origMethod = class_getInstanceMethod(c, originalSEL);
    Method newMethod = class_getInstanceMethod(c, newSEL);
    
    const char* origMethodEncoding = method_getTypeEncoding(origMethod);
    const char* newMethodEncoding = method_getTypeEncoding(newMethod);
    
    if (strcmp(origMethodEncoding, newMethodEncoding) != 0)
    {
        AssertEx(0, @"lookup args");
        return NO;
    }
    
    method_exchangeImplementations(origMethod, newMethod);
    
    return YES;
}

BOOL classEx_replaceMethodWithBlock(Class c, SEL originalSEL, id block)
{
    Method origMethod = class_getInstanceMethod(c, originalSEL);
    
    if (isSignatureEqual(block, origMethod) == NO)
    {
        AssertEx(0, @"lookup args");
        return NO;
    }
    
    IMP impl = imp_implementationWithBlock(block);
    
    return classEx_replaceMethodWithIMP(c, originalSEL, impl);
}

BOOL classEx_replaceMethodWithIMP(Class c, SEL originalSEL, IMP newIMP)
{
    const char* encoding = method_getTypeEncoding(class_getInstanceMethod(c, originalSEL));
    
    class_replaceMethod(c, originalSEL, newIMP, encoding);
    
    return YES;
}

BOOL classEx_addMethodWithBlock(Class c, NSString* selString, id block)
{
    if (class_addMethod(c, NSSelectorFromString(selString), imp_implementationWithBlock(block), getBlockSignature(block)))
    {
        return YES;
    }
    return NO;
}

///////////////////////////////////////////////////////////////private

const char* getBlockSignature(id block)
{
    struct BlockModel *blockRef = (__bridge struct BlockModel *)block;
    int _flags = blockRef->flags;
    
    
    if (_flags & BlockDescriptionFlagsHasSignature)
    {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (_flags & BlockDescriptionFlagsHasCopyDispose)
        {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        return (*(const char **)signatureLocation);
    }
    return NULL;
}

BOOL isSignatureEqual(id block, Method method)
{
    if (method == NULL || block == NULL)
    {
        return NO;
    }
    
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:getBlockSignature(block)];
    
    if (blockSignature.numberOfArguments != methodSignature.numberOfArguments)
    {
        return NO;
    }
    
    if (strncmp(blockSignature.methodReturnType, methodSignature.methodReturnType, strlen(methodSignature.methodReturnType)) != 0)
    {
        return NO;
    }
    
    //block展开后的第一个参数为函数指针，用@?表示 第二个是self 用@表示
    //method展开后第一个参数为self 用@表示 第二个参数是SEL 用:表示
    //可以略过这俩参数，剩下的参数block要比method全，因为block是纯c++函数，所以对参数的说明要多于method
    //    //在method中 block 是 @?
    //    //在block中 嵌套block 是 <v@?>
    //    //函数调用看.h，函数签名看的确是.m
    
    for (int i = 2; i < methodSignature.numberOfArguments; i++)
    {
        NSLog(@"%s", [methodSignature getArgumentTypeAtIndex:i]);
        NSLog(@"%s", [blockSignature getArgumentTypeAtIndex:i]);
        if (strncmp([blockSignature getArgumentTypeAtIndex:i], [methodSignature getArgumentTypeAtIndex:i], strlen([methodSignature getArgumentTypeAtIndex:i])) != 0)
        {
            return NO;
        }
    }
    return YES;
}
