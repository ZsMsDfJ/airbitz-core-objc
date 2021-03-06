//
//  ABCKeychain.m
//  Airbitz
//
//  Created by Paul Puey on 2015-08-31.
//  Copyright (c) 2015 Airbitz. All rights reserved.
//

#import "NSMutableData+Secure.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "ABCKeychain+Internal.h"
#import "ABCContext+Internal.h"

@interface ABCKeychain ()

@property (nonatomic) ABCContext *abc;
@property (nonatomic) ABCLocalSettings *localSettings;

@end

@implementation ABCKeychain
{
    
}

- (id) init:(ABCContext *)abc;
{
    self = [super init];
    self.abc = abc;

    return self;
}
#if TARGET_OS_IPHONE

- (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
{
    if (! key) return NO;
    if (![self bHasSecureEnclave]) return NO;

    id accessible = (authenticated) ? (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly :
    (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:SEC_ATTR_SERVICE,
            (__bridge id)kSecAttrAccount:key};

    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL) == errSecItemNotFound) {
        if (! data) return YES;

        NSDictionary *item = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrService:SEC_ATTR_SERVICE,
                (__bridge id)kSecAttrAccount:key,
                (__bridge id)kSecAttrAccessible:accessible,
                (__bridge id)kSecValueData:data};
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)item, NULL);

        if (status == noErr) return YES;
        NSLog(@"SecItemAdd error status %d", (int)status);
        return NO;
    }

    if (! data) {
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

        if (status == noErr) return YES;
        NSLog(@"SecItemDelete error status %d", (int)status);
        return NO;
    }

    NSDictionary *update = @{(__bridge id)kSecAttrAccessible:accessible,
            (__bridge id)kSecValueData:data};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);

    if (status == noErr) return YES;
    NSLog(@"SecItemUpdate error status %d", (int)status);
    return NO;
}

- (NSData *) getKeychainData:(NSString *)key error:(ABCError **)error;
{
    NSDictionary *query = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:SEC_ATTR_SERVICE,
            (__bridge id)kSecAttrAccount:key,
            (__bridge id)kSecReturnData:@YES};
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);

    if (status == errSecItemNotFound) return nil;
    if (status == noErr) return CFBridgingRelease(result);
    if (error) *error = [ABCError errorWithDomain:@"Airbitz" code:status
                                        userInfo:@{NSLocalizedDescriptionKey:@"SecItemCopyMatching error"}];
    return nil;
}

- (BOOL) bHasSecureEnclave;
{
    LAContext *context = [LAContext new];
    ABCError *error = nil;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
    {
        return YES;
    }

    return NO;
}

// Authenticate w/touchID
- (void)authenticateTouchID:(NSString *)promptString fallbackString:(NSString *)fallbackString
                   complete:(void (^)(BOOL didAuthenticate)) completionHandler;

{
    LAContext *context = [LAContext new];
    ABCError *error = nil;
    __block NSInteger authcode = 0;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
    {
        context.localizedFallbackTitle = fallbackString;

        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:promptString.length > 0 ? promptString : @" "
                            reply:^(BOOL success, NSError *error)
        {
            if (success) {
                // User authenticated successfully, take appropriate action
                dispatch_async(dispatch_get_main_queue(), ^{
                    // write all your code here
                    completionHandler(YES);
                });
            } else {
                // User did not authenticate successfully, look at error and take appropriate action
                
                switch (error.code) {
                    case LAErrorAuthenticationFailed:
                        NSLog(@"Authentication Failed");
                        NSLog(@"[LAContext canEvaluatePolicy:] %@", error.localizedDescription);
                        break;
                        
                    case LAErrorUserCancel:
                        NSLog(@"User pressed Cancel button");
                        NSLog(@"[LAContext canEvaluatePolicy:] %@", error.localizedDescription);
                        break;
                        
                    case LAErrorUserFallback:
                        NSLog(@"User pressed \"Enter Password\"");
                        NSLog(@"[LAContext canEvaluatePolicy:] %@", error.localizedDescription);
                        break;
                        
                    default:
                        NSLog(@"Touch ID is not configured");
                        NSLog(@"[LAContext canEvaluatePolicy:] %@", error.localizedDescription);
                        break;
                }
                
                NSLog(@"Authentication Fails");
                dispatch_async(dispatch_get_main_queue(), ^{
                    // write all your code here
                    completionHandler(NO);
                });
            }
        }];
    }
    else
    {
        completionHandler(NO);
    }
    
//        
//        
//        
//        
//        
//        
//        
//        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
//                localizedReason:(promptString.length > 0 ? promptString : @" ") reply:^(BOOL success, ABCError *error)
//                {
//                    authcode = (success) ? 1 : error.code;
//                }];
//
//        while (authcode == 0) {
//            [[NSRunLoop mainRunLoop] limitDateForMode:NSDefaultRunLoopMode];
//        }
//
//        if (authcode == LAErrorAuthenticationFailed)
//        {
//            return NO;
//        }
//        else if (authcode == 1)
//        {
//            return YES;
//        }
//        else if (authcode == LAErrorUserCancel || authcode == LAErrorSystemCancel)
//        {
//            return NO;
//        }
//    }
//    else if (error)
//    {
//        NSLog(@"[LAContext canEvaluatePolicy:] %@", error.localizedDescription);
//    }
//
//    return NO;
}

#else
- (BOOL) setKeychainData:(NSData *)data key:(NSString *)key authenticated:(BOOL) authenticated;
{ return NO; }
- (NSData *) getKeychainData:(NSString *)key error:(ABCError **)error;
{ return nil; }
- (BOOL) bHasSecureEnclave;
{ return NO; }
- (void)authenticateTouchID:(NSString *)promptString fallbackString:(NSString *)fallbackString;
{ return; }

#endif

- (NSString *) createKeyWithUsername:(NSString *)username key:(NSString *)key;
{
    return [NSString stringWithFormat:@"%@___%@",username,key];
}

- (BOOL) setKeychainString:(NSString *)s key:(NSString *)key authenticated:(BOOL) authenticated;
{
    @autoreleasepool {
        NSData *d = (s) ? CFBridgingRelease(CFStringCreateExternalRepresentation(SecureAllocator(), (CFStringRef)s,
                                                                                 kCFStringEncodingUTF8, 0)) : nil;
        
        return [self setKeychainData:d key:key authenticated:authenticated];
    }
}

- (NSString *) getKeychainString:(NSString *)key error:(ABCError **)error;
{
    @autoreleasepool {
        NSData *d = [self getKeychainData:key error:error];
        
        return (d) ? CFBridgingRelease(CFStringCreateFromExternalRepresentation(SecureAllocator(), (CFDataRef)d,
                                                                                kCFStringEncodingUTF8)) : nil;
    }
}

- (BOOL) setKeychainInt:(int64_t) i key:(NSString *)key authenticated:(BOOL) authenticated;
{
    @autoreleasepool {
        NSMutableData *d = [NSMutableData secureDataWithLength:sizeof(int64_t)];
        
        *(int64_t *)d.mutableBytes = i;
        return [self setKeychainData:d key:key authenticated:authenticated];
    }
}

- (int64_t) getKeychainInt:(NSString *)key error:(ABCError **)error;
{
    @autoreleasepool {
        NSData *d = [self getKeychainData:key error:error];
        
        return (d.length == sizeof(int64_t)) ? *(int64_t *)d.bytes : 0;
    }
}


- (void) disableRelogin:(NSString *)username;
{
    [self setKeychainData:nil
                          key:[self createKeyWithUsername:username key:RELOGIN_KEY]
                authenticated:YES];
}

- (void) disableTouchID:(NSString *)username;
{
    [self setKeychainData:nil
                          key:[self createKeyWithUsername:username key:USE_TOUCHID_KEY]
                authenticated:YES];
}

- (void) clearKeychainInfo:(NSString *)username;
{
    [self setKeychainData:nil
                          key:[self createKeyWithUsername:username key:PASSWORD_KEY]
                authenticated:YES];
    [self setKeychainData:nil
                          key:[self createKeyWithUsername:username key:RELOGIN_KEY]
                authenticated:YES];
    [self setKeychainData:nil
                          key:[self createKeyWithUsername:username key:USE_TOUCHID_KEY]
                authenticated:YES];
}

- (BOOL) disableKeychainBasedOnSettings:(NSString *)username;
{
    BOOL disableFingerprint = NO;
    if (![self bHasSecureEnclave])
        return YES;

    if ([self.localSettings.touchIDUsersDisabled indexOfObject:username] != NSNotFound)
        disableFingerprint = YES;

    [self setKeychainInt:disableFingerprint ? 0 : 1
                     key:[self createKeyWithUsername:username key:USE_TOUCHID_KEY]
           authenticated:YES];
    
    if (disableFingerprint)
    {
        // If user has disabled TouchID, then do not use ABCKeychain at all for maximum security
        [self clearKeychainInfo:username];
        return YES;
    }

    return NO;
}

- (void) updateLoginKeychainInfo:(NSString *)username
                        loginKey:(NSString *)loginKey
                      useTouchID:(BOOL) bUseTouchID;
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if ([self disableKeychainBasedOnSettings:username])
            return;
        
        [self setKeychainInt:1
                             key:[self createKeyWithUsername:username key:RELOGIN_KEY]
                   authenticated:YES];
        [self setKeychainInt:bUseTouchID
                             key:[self createKeyWithUsername:username key:USE_TOUCHID_KEY]
                   authenticated:YES];
        if (loginKey != nil)
        {
            [self setKeychainString:loginKey
                                key:[self createKeyWithUsername:username key:LOGINKEY_KEY]
                      authenticated:YES];
        }
    });
}

@end

