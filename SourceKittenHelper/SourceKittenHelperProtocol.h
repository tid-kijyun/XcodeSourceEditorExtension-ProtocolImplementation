//
//  SourceKittenHelperProtocol.h
//  SourceKittenHelper
//
//  Created by Atsushi Kiwaki on 2017/03/04.
//  Copyright © 2017 Atsushi Kiwaki. All rights reserved.
//

#import <Foundation/Foundation.h>

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.

@protocol SourceKittenHelperProtocol

//// Replace the API of this protocol with an API appropriate to the service you are vending.
//- (void)upperCaseStringFor:(NSString *)aString withReply:(void (^)(NSString *))reply;
- (void)structure: (NSString * _Nonnull)content withReply: (nonnull void (^)(NSString * _Nonnull))reply;

- (void)complete: (NSString * _Nonnull)file content: (NSString * _Nonnull)content offset: (NSInteger)offset withReply: (nonnull void (^)(NSString * _Nonnull))reply;

- (void)snippet: (NSString * _Nonnull)file withReply: (nonnull void (^)(NSString * _Nonnull))reply;
@end

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     _connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"com.tid.SourceKittenHelper"];
     _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SourceKittenHelperProtocol)];
     [_connectionToService resume];

Once you have a connection to the service, you can use it like this:

     [[_connectionToService remoteObjectProxy] upperCaseString:@"hello" withReply:^(NSString *aString) {
         // We have received a response. Update our text field, but do it on the main thread.
         NSLog(@"Result string was: %@", aString);
     }];

 And, when you are finished with the service, clean up the connection like this:

     [_connectionToService invalidate];
*/
