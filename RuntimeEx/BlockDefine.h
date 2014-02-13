//
//  BlockDefine.h
//  RuntimeEx
//
//  Created by satyso on 14-2-13.
//  Copyright (c) 2014年 song4@163.com. All rights reserved.
//

//https://llvm.org/svn/llvm-project/compiler-rt/trunk/BlocksRuntime/Block_private.h

#ifndef RuntimeEx_Block_define_h
#define RuntimeEx_Block_define_h

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

#endif
