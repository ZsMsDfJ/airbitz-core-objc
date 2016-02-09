//
// Created by Paul P on 1/30/16.
// Copyright (c) 2016 Airbitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABCConditionCode.h"
#import "AirbitzCore.h"
#import "ABCUser.h"

@class AirbitzCore;
@class ABCKeychain;
@class ABCUser;

#define ABC_ARRAY_EXCHANGES     @[@"Bitstamp", @"BraveNewCoin", @"Coinbase", @"CleverCoin"]

@interface ABCSettings : NSObject

/// @name User Settings that are synced across devices
/// Must call [ABCSettings loadSettings] before reading and
/// [ABCSettings saveSettings] after writing

/// How many minutes after the app is backgrounded before the user should be auto logged out
@property (nonatomic) int minutesAutoLogout;

/// Default ISO currency number for new wallets and for the account total on Wallets screen
@property (nonatomic) int defaultCurrencyNum;

@property (nonatomic) int64_t denomination;
@property (nonatomic, copy) NSString* denominationLabel;
@property (nonatomic) int denominationType;
@property (nonatomic, copy) NSString* firstName;
@property (nonatomic, copy) NSString* lastName;
@property (nonatomic, copy) NSString* nickName;
@property (nonatomic, copy) NSString* fullName;
@property (nonatomic, copy) NSString* strPIN;
@property (nonatomic, copy) NSString* exchangeRateSource;
@property (nonatomic) bool bNameOnPayments;
@property (nonatomic, copy) NSString* denominationLabelShort;
@property (nonatomic) bool bSpendRequirePin;
@property (nonatomic) int64_t spendRequirePinSatoshis;
@property (nonatomic) bool bDisablePINLogin;

- (id)init:(ABCUser *)user localSettings:(id)local keyChain:(id)keyChain;

/// Loads all settings into [ABCSettings] structure
- (ABCConditionCode)loadSettings;

/// Saves all settings from [ABCSettings] structure
- (ABCConditionCode)saveSettings;

- (BOOL) touchIDEnabled;
- (BOOL) enableTouchID;
- (void) disableTouchID;

@end

