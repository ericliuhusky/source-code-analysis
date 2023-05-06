#ifndef YYModel_h
#define YYModel_h

#import <Foundation/Foundation.h>

@interface NSObject(YYModel)

+ (instancetype)yy_modelWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary<NSString*, id>*)yy_modelToJSONObject;

@end

#endif
