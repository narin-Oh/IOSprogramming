#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"hansung.ac.kr.DailyQ";

/// The "BackgroundColor" asset catalog color resource.
static NSString * const ACColorNameBackgroundColor AC_SWIFT_PRIVATE = @"BackgroundColor";

/// The "BlueColor" asset catalog color resource.
static NSString * const ACColorNameBlueColor AC_SWIFT_PRIVATE = @"BlueColor";

/// The "GrayColor" asset catalog color resource.
static NSString * const ACColorNameGrayColor AC_SWIFT_PRIVATE = @"GrayColor";

/// The "LetterColor" asset catalog color resource.
static NSString * const ACColorNameLetterColor AC_SWIFT_PRIVATE = @"LetterColor";

/// The "LightGrayColor" asset catalog color resource.
static NSString * const ACColorNameLightGrayColor AC_SWIFT_PRIVATE = @"LightGrayColor";

/// The "MainColor" asset catalog color resource.
static NSString * const ACColorNameMainColor AC_SWIFT_PRIVATE = @"MainColor";

/// The "logo" asset catalog image resource.
static NSString * const ACImageNameLogo AC_SWIFT_PRIVATE = @"logo";

#undef AC_SWIFT_PRIVATE