//
//  ABCCurrency.m
//  Airbitz
//

#import "AirbitzCore+Internal.h"

@interface ABCCurrency ()
{
}

@end

static ABCCurrency              *staticNoCurrency = nil;
static ABCCurrency              *staticDefaultCurrency = nil;
static NSMutableDictionary      *currencyCodesCache = nil;
static NSMutableDictionary      *currencySymbolCache = nil;
static NSArray                  *arrayCurrency = nil;
static NSArray                  *arrayCurrencyNums = nil;
static NSArray                  *arrayCurrencyCodes = nil;
static NSArray                  *arrayCurrencyStrings = nil;

@implementation ABCCurrency

+ (ABCCurrency *)noCurrency;
{
    if (!staticNoCurrency)
    {
        staticNoCurrency = [ABCCurrency alloc];
        staticNoCurrency.code = @"";
        staticNoCurrency.textDescription = @"";
        staticNoCurrency.symbol = @"";
        staticNoCurrency.currencyNum = 0;
    }
    return staticNoCurrency;
}
+ (ABCCurrency *)defaultCurrency;
{
    if (!staticDefaultCurrency)
    {
        staticDefaultCurrency = [ABCCurrency alloc];
        staticDefaultCurrency.code = @"USD";
        staticDefaultCurrency.textDescription = @"USD - US Dollar";
        staticDefaultCurrency.symbol = @"$";
        staticDefaultCurrency.currencyNum = 840;
    }
    return staticNoCurrency;
}

+ (NSArray *) listCurrencies;
{
    if (!arrayCurrency)
        [ABCCurrency initializeCurrencyArrays];
    
    return arrayCurrency;
}

+ (NSArray *) listCurrencyCodes;
{
    if (!arrayCurrency)
        [ABCCurrency initializeCurrencyArrays];
    return arrayCurrencyCodes;
}

+ (NSArray *) listCurrencyStrings;
{
    if (!arrayCurrency)
        [ABCCurrency initializeCurrencyArrays];
    return arrayCurrencyStrings;
}

+ (NSArray *) listCurrencyNums;
{
    if (!arrayCurrency)
        [ABCCurrency initializeCurrencyArrays];
    
    return arrayCurrencyNums;
}

const NSString *syncToken = @"ABCCurrencySyncToken";

+ (void) initializeCurrencyArrays
{
    @synchronized(syncToken)
    {
        tABC_Error          error;
        tABC_Currency       *aCurrencies = nil;
        int                 currencyCount;
        
        ABC_GetCurrencies(&aCurrencies, &currencyCount, &error);
        if ([ABCError makeNSError:error]) return;
        
        // set up our internal currency arrays
        NSMutableArray *lArrayCurrency = [[NSMutableArray alloc] initWithCapacity:currencyCount];
        NSMutableArray *lArrayCurrencyNums = [[NSMutableArray alloc] initWithCapacity:currencyCount];
        NSMutableArray *lArrayCurrencyCodes = [[NSMutableArray alloc] initWithCapacity:currencyCount];
        NSMutableArray *lArrayCurrencyStrings = [[NSMutableArray alloc] initWithCapacity:currencyCount];
        
        for (int i = 0; i < currencyCount; i++)
        {
            ABCCurrency *currency = [ABCCurrency alloc];
            
            currency.textDescription = [NSString stringWithFormat:@"%s - %@",
                                        aCurrencies[i].szCode,
                                        [NSString stringWithUTF8String:aCurrencies[i].szDescription]];
            currency.code = [NSString stringWithUTF8String:aCurrencies[i].szCode];
            currency.currencyNum = aCurrencies[i].num;
            
            for (NSString *l in NSLocale.availableLocaleIdentifiers) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.locale = [NSLocale localeWithLocaleIdentifier:l];
                if ([f.currencyCode isEqualToString:currency.code]) {
                    currency.symbol = f.currencySymbol;
                    break;
                }
            }
            
            [lArrayCurrency addObject:currency];
            [lArrayCurrencyCodes addObject:currency.code];
            [lArrayCurrencyNums addObject:[NSNumber numberWithInt:aCurrencies[i].num]];
            [lArrayCurrencyStrings addObject:currency.textDescription];
        }
        arrayCurrency          = lArrayCurrency;
        arrayCurrencyNums      = lArrayCurrencyNums;
        arrayCurrencyStrings   = lArrayCurrencyStrings;
        arrayCurrencyCodes     = lArrayCurrencyCodes;
    }
}

- (NSString *)doubleToPrettyCurrencyString:(double) fCurrency;
{
    return [self doubleToPrettyCurrencyString:fCurrency withSymbol:true];
}

- (NSString *)doubleToPrettyCurrencyString:(double) fCurrency withSymbol:(bool)symbol
{
    NSNumberFormatter *f = [ABCCurrency generateNumberFormatter];
    [f setNumberStyle: NSNumberFormatterCurrencyStyle];
    if (symbol) {
        NSString *symbol = self.symbol;
        [f setNegativePrefix:[NSString stringWithFormat:@"-%@ ",symbol]];
        [f setNegativeSuffix:@""];
        [f setCurrencySymbol:[NSString stringWithFormat:@"%@ ", symbol]];
    } else {
        [f setCurrencySymbol:@""];
    }
    return [f stringFromNumber:[NSNumber numberWithFloat:fCurrency]];
}

+ (NSNumberFormatter *)generateNumberFormatter;
{
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setMinimumFractionDigits:2];
    [f setMaximumFractionDigits:2];
    [f setLocale:locale];
    return f;
}


//+ (NSString *)currencyAbbrevLookup:(int)currencyNum
//{
//    ABCLog(2,@"ENTER currencyAbbrevLookup: %@", [NSThread currentThread].name);
////    NSNumber *c = [NSNumber numberWithInt:currencyNum];
////    NSString *cached = [currencyCodesCache objectForKey:c];
////    if (cached != nil) {
////        ABCLog(2,@"EXIT currencyAbbrevLookup CACHED code:%@ thread:%@", cached, [NSThread currentThread].name);
////        return cached;
////    }
//    tABC_Error error;
//    int currencyCount;
//    tABC_Currency *currencies = NULL;
//    ABC_GetCurrencies(&currencies, &currencyCount, &error);
//    ABCLog(2,@"CALLED ABC_GetCurrencies: %@ currencyCount:%d", [NSThread currentThread].name, currencyCount);
//    if (error.code == ABC_CC_Ok) {
//        for (int i = 0; i < currencyCount; ++i) {
//            if (currencyNum == currencies[i].num) {
//                NSString *code = [NSString stringWithUTF8String:currencies[i].szCode];
//                [currencyCodesCache setObject:code forKey:c];
//                ABCLog(2,@"EXIT currencyAbbrevLookup code:%@ thread:%@", code, [NSThread currentThread].name);
//                return code;
//            }
//        }
//    }
//    ABCLog(2,@"EXIT currencyAbbrevLookup code:NULL thread:%@", [NSThread currentThread].name);
//    return @"";
//}
//
//- (NSString *)currencySymbolLookup:(int)currencyNum
//{
//    NSNumber *c = [NSNumber numberWithInt:currencyNum];
//    NSString *cached = [currencySymbolCache objectForKey:c];
//    if (cached != nil) {
//        return cached;
//    }
//    NSNumberFormatter *formatter = nil;
//    NSString *code = [ABCCurrency currencyAbbrevLookup:currencyNum];
//    for (NSString *l in NSLocale.availableLocaleIdentifiers) {
//        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
//        f.locale = [NSLocale localeWithLocaleIdentifier:l];
//        if ([f.currencyCode isEqualToString:code]) {
//            formatter = f;
//            break;
//        }
//    }
//    if (formatter != nil) {
//        [currencySymbolCache setObject:formatter.currencySymbol forKey:c];
//        return formatter.currencySymbol;
//    } else {
//        return @"";
//    }
//}
//
//
//
@end