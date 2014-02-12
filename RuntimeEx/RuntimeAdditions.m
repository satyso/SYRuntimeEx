//
//  RuntimeAdditions.m
//  simplearray
//
//  Created by satyso on 14-2-12.
//  Copyright (c) 2014年 Graham Lee. All rights reserved.
//

#import "RuntimeAdditions.h"
#import <objc/runtime.h>


#define AssertEx(expression, ...) \
do { if(!(expression)) { \
NSLog(@"%@", [NSString stringWithFormat: @"Assertion failure: %s in %s on line %s:%d. %@", #expression, __PRETTY_FUNCTION__, __FILE__, __LINE__, [NSString stringWithFormat:@"" __VA_ARGS__]]); \
abort(); }} while(0)

struct BlockModel {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
    	unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
    	void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    	void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

enum {
    BlockDescriptionFlagsHasCopyDispose = (1 << 25),
    BlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    BlockDescriptionFlagsIsGlobal = (1 << 28),
    BlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BlockDescriptionFlagsHasSignature = (1 << 30)
};

//private
//////////////////////////////////////////////////////////////////

BOOL isSignatureEqual(id block, Method method);

const char* getBlockSignature(id block);

//////////////////////////////////////////////////////////////////

BOOL classEx_replaceMethodWithBlock(Class c, SEL originalSEL, id block)
{
    Method origMethod = class_getInstanceMethod(c, originalSEL);
    const char *encoding = method_getTypeEncoding(origMethod);
    
    if (isSignatureEqual(block, origMethod) == NO)
    {
        AssertEx(0, @"lookup args");
        return NO;
    }
    
    SEL tmpSEL = NSSelectorFromString([NSString stringWithFormat:@"%p%@", block, NSStringFromSelector(originalSEL)]);
    // Add the new method.
    
    IMP impl = imp_implementationWithBlock(block);
    
    if (!class_addMethod(c, tmpSEL, impl, encoding))
    {
        AssertEx(0, @"can't add SEL %@", NSStringFromSelector(tmpSEL));
        return NO;
    }
    else
    {
        return classEx_replaceMethod(c, originalSEL, tmpSEL);
    }
    return YES;
}

BOOL classEx_replaceMethod(Class c, SEL originalSEL, SEL newSEL)
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
    
    if (class_addMethod(c, originalSEL, method_getImplementation(newMethod), origMethodEncoding))
    {
        class_replaceMethod(c, newSEL, method_getImplementation(origMethod), origMethodEncoding);
    }
    else
    {
        method_exchangeImplementations(origMethod, newMethod);
    }
    
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
