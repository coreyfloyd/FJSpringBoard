//
//  NSObject+Proxy.h
//  
//
//  Created by Corey Floyd.
//  Borrowed from Steve Degutis and Peter Hosey, with a splash of me
//

#import <Foundation/Foundation.h>


@protocol FJNSObjectProxy

- (id)nextRunloopProxy;
- (id)proxyWithDelay:(float)time;
- (id)performOnMainThreadProxy;
- (id)performIfRespondsToSelectorProxy;

@end


@interface NSObject(Proxy) <FJNSObjectProxy>

- (id)nextRunloopProxy;
- (id)proxyWithDelay:(float)time;
- (id)performOnMainThreadProxy;
- (id)performIfRespondsToSelectorProxy;

@end

