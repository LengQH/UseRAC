//
//  RACSubscriber.m
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/1/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSubscriber.h"
#import "RACSubscriber+Private.h"
#import <ReactiveObjC/RACEXTScope.h>
#import "RACCompoundDisposable.h"
#import "RACTuple.h"

@interface RACSubscriber ()

// These callbacks should only be accessed while synchronized on self.
@property (nonatomic, copy) void (^next)(id value);
@property (nonatomic, copy) void (^error)(NSError *error);
@property (nonatomic, copy) void (^completed)(void);

@property (nonatomic, strong, readonly) RACCompoundDisposable *disposable;

@end

@implementation RACSubscriber

#pragma mark Lifecycle

+ (instancetype)subscriberWithNext:(void (^)(id x))next error:(void (^)(NSError *error))error completed:(void (^)(void))completed {
	RACSubscriber *subscriber = [[self alloc] init];

	subscriber->_next = [next copy];
	subscriber->_error = [error copy];
	subscriber->_completed = [completed copy];

	return subscriber;
}

- (id)init {
	self = [super init];
	if (self == nil) return nil;

	@unsafeify(self);

	RACDisposable *selfDisposable = [RACDisposable disposableWithBlock:^{
		@strongify(self);

		@synchronized (self) {
			self.next = nil;
			self.error = nil;
			self.completed = nil;
		}
	}];

	_disposable = [RACCompoundDisposable compoundDisposable];
	[_disposable addDisposable:selfDisposable];

	return self;
}

- (void)dealloc {
	[self.disposable dispose];
}

#pragma mark RACSubscriber

- (void)sendNext:(id)value {
	@synchronized (self) {
		void (^nextBlock)(id) = [self.next copy];
//        RACTuple *tuple=(RACTuple *)value;
//        NSLog(@"元组里面的值:%@",tuple);
//        if([tuple isKindOfClass:[RACTuple class]]){
//             // 如果对应的值为 null 直接返回 不能回调
//            if ([tuple isKindOfClass:[NSString class]]) {
//                if([self isBlankString:tuple]) return;
//            }
//            else{
//                if([self isBlankString:[tuple first]]) return;
//            }
//        }
		if (nextBlock == nil) return;
		nextBlock(value);
	}
}

#pragma mark 判断字符串是否为空
-(BOOL)isBlankString:(id)string{
    NSString * str=(NSString*)string;
    if ([str isEqualToString:@"(null)"]) {
        return YES;
    }
    if (str==nil || str==NULL) {
        return YES;
    }
    if ([str isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

- (void)sendError:(NSError *)e {
	@synchronized (self) {
		void (^errorBlock)(NSError *) = [self.error copy];
		[self.disposable dispose];

		if (errorBlock == nil) return;
		errorBlock(e);
	}
}

- (void)sendCompleted {
	@synchronized (self) {
		void (^completedBlock)(void) = [self.completed copy];
		[self.disposable dispose];

		if (completedBlock == nil) return;
		completedBlock();
	}
}

- (void)didSubscribeWithDisposable:(RACCompoundDisposable *)otherDisposable {
	if (otherDisposable.disposed) return;

	RACCompoundDisposable *selfDisposable = self.disposable;
	[selfDisposable addDisposable:otherDisposable];

	@unsafeify(otherDisposable);

	// If this subscription terminates, purge its disposable to avoid unbounded
	// memory growth.
	[otherDisposable addDisposable:[RACDisposable disposableWithBlock:^{
		@strongify(otherDisposable);
		[selfDisposable removeDisposable:otherDisposable];
	}]];
}

@end
