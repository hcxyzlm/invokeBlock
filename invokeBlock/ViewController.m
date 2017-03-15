//
//  ViewController.m
//  invokeBlock
//
//  Created by zhuo on 2017/3/15.
//  Copyright © 2017年 zhuo. All rights reserved.
//

#import "ViewController.h"
#include <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    void (^block)() = ^ () {
        
        NSLog(@"block get call");
    };
    //    block(); // 不能这样调，有多少种方法可以调用
    
    [self blockAnswer1:block];
    [self blockAnswer2:block];
    [self blockAnswer3:block];
    [self blockAnswer4:block];
    [self blockAnswer5:block];
    [self blockAnswer6:block];
    [self blockAnswer7:block];
}

- (void)blockAnswer1:(void (^)(void))block {
    [UIView animateWithDuration:0 animations:block completion:nil];
    // or
   // dispatch_async(dispatch_get_main_queue(), block);
}

- (void)blockAnswer2:(void (^)(void))block {
    NSBlockOperation *openeration = [[NSBlockOperation alloc] init];
    [openeration addExecutionBlock:block];
    [openeration start];
}

- (void)blockAnswer3:(void (^)(void))block {
    //4
    /**
     struct __block_impl {
     void *isa; // 8字节
     int Flags;
     int Reserved;
     void *FuncPtr;
     };
     **/
    // 先转化成void *
    
    void *pBlock = (__bridge void*)block;
    // 把地址移动+2,相当于移动到FuncPtr的地址，再解移动，取到函数地址
    void (*invoke)(void*, ...) = (void(*)(void*, ...))*((void **)pBlock +2);
    invoke(pBlock);
}

- (void)blockAnswer4:(void (^)(void))block {
    //[self description];
    
//    NSMethodSignature *metho1 = [self methodSignatureForSelector:@selector(description)];
//    
//    // 包含一个签名的函数
//    NSInvocation *invo = [NSInvocation invocationWithMethodSignature:metho1];
//    invo.target = self;
//    invo.selector = @selector(description);
//    [invo invoke];// 调用
    
    // 是一个包封了方法签名的对象
    NSMethodSignature*signature = [NSMethodSignature signatureWithObjCTypes:"v@?"];
    /**
     1. v = void 等于返回值
     2. @ = 等于自己本身
     3. ？表示是一个block
     /*/
    NSInvocation*invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = block;
    [invocation invoke];
}


/**
block --> __NSGlobalBlock__ --> NSGlobalBlock__ ->NSBlock --> NSObject
 */
- (void)blockAnswer5:(void (^)(void))block {
    
    [block invoke];
    // 0r
    //[block performAfterDelay:0];
}
- (NSString *)description {
    NSLog(@"%s", __func__);
    return @"call for method";
}

static void blockCleanUp(__strong void (^*block)(void)) {
    (*block)();
}

- (void)blockAnswer6:(void (^)(void))block {
    __strong void (^cleaner)(void) __attribute__((cleanup(blockCleanUp), unused)) = block;
}


- (void)blockAnswer7:(void (^)(void))block {
    
    /**
     使用dis命令打印汇编
     
     -------------------------------
     0x108d98610 <+0>:  pushq  %rbp
     0x108d98611 <+1>:  movq   %rsp, %rbp
     0x108d98614 <+4>:  subq   $0x20, %rsp
     0x108d98618 <+8>:  leaq   -0x18(%rbp), %rax
     0x108d9861c <+12>: movq   %rdi, -0x8(%rbp)
     0x108d98620 <+16>: movq   %rsi, -0x10(%rbp)
     0x108d98624 <+20>: movq   $0x0, -0x18(%rbp)
     0x108d9862c <+28>: movq   %rax, %rdi
     0x108d9862f <+31>: movq   %rdx, %rsi                 // 进入blockAnswer7函数
     0x108d98632 <+34>: callq  0x108d9898c               ; symbol stub for: objc_storeStrong
     ->  0x108d98637 <+39>: movq   -0x18(%rbp), %rax
     0x108d9863b <+43>: movq   %rax, %rdx
     0x108d9863e <+46>: movq   %rdx, %rdi
     0x108d98641 <+49>: callq  *0x10(%rax)                // 调用block，模拟
     0x108d98644 <+52>: callq  *0x10(%rax)
     0x108d98647 <+55>: xorl   %ecx, %ecx
     0x108d98649 <+57>: movl   %ecx, %esi
     0x108d9864b <+59>: leaq   -0x18(%rbp), %rax
     0x108d9864f <+63>: movq   %rax, %rdi
     0x108d98652 <+66>: callq  0x108d9898c               ; symbol stub for: objc_storeStrong
     0x108d98657 <+71>: addq   $0x20, %rsp
     0x108d9865b <+75>: popq   %rbp
     0x108d9865c <+76>: retq

     --------------------------------
     
     */
    block();
    asm("callq  *0x10(%rax)");
}

@end
