#import <Foundation/Foundation.h>
#import <objc/message.h>

@interface YYProperty : NSObject

@property NSString *name;
@property bool isObject;

@end

@implementation YYProperty

- (instancetype)initWithProperty:(objc_property_t)prop {
    NSString *name = [[NSString alloc] initWithUTF8String:property_getName(prop)];
    const char *encoding = property_copyAttributeValue(prop, "T");
    bool isObject = encoding[0] == '@' && encoding[1] != '?';
    self.name = name;
    self.isObject = isObject;
    return self;
}

- (SEL)getter {
    return sel_registerName([self.name cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (SEL)setter {
    NSString *cap = [self.name capitalizedString];
    NSString *setter = [[NSString alloc] initWithFormat:@"set%@:", cap];
    return sel_registerName([setter cStringUsingEncoding:NSASCIIStringEncoding]);
}

@end

@interface YYClass : NSObject

@property NSArray<YYProperty*> *properties;
@property YYClass *superCls;
@property NSArray<YYProperty*>* allProperties;

@end

NSMutableDictionary<NSString*, YYClass*> *cacheDict;

@implementation YYClass

+ (instancetype)cachedWithClass:(Class)cls {
    if (!cacheDict) {
        cacheDict = [[NSMutableDictionary alloc] init];
    }
    NSString *key = [[NSString alloc] initWithUTF8String:class_getName(cls)];
    YYClass *meta = cacheDict[key];
    if (meta) {
        return meta;
    }
    meta = [[YYClass alloc] initWithClass:cls];
    cacheDict[key] = meta;
    return meta;
}

- (instancetype)initWithClass:(Class)cls {
    Class superCls = class_getSuperclass(cls);
    if (!superCls) {
        return nil;
    }
    self.superCls = [[YYClass alloc] initWithClass:superCls];
    
    uint32_t propertyCount;
    objc_property_t *propertiesPtr = class_copyPropertyList(cls, &propertyCount);
    NSMutableArray *properties = [[NSMutableArray alloc] init];
    for (int i = 0; i < propertyCount; i++) {
        YYProperty *property = [[YYProperty alloc] initWithProperty:propertiesPtr[i]];
        [properties addObject:property];
    }
    free(propertiesPtr);
    self.properties = properties;
    return self;
}

- (NSArray<YYProperty*>*)allPropertiesWithSuper {
    if (!self.allProperties) {
        NSMutableArray<YYProperty*>* allProperties = [[NSMutableArray alloc] init];
        YYClass *cls = self;
        while (cls != nil) {
            [allProperties addObjectsFromArray:cls.properties];
            cls = cls.superCls;
        }
        self.allProperties = allProperties;
    }
    return self.allProperties;
}

@end


@implementation NSObject(YYModel)

+ (instancetype)yy_modelWithDictionary:(NSDictionary *)dictionary {
    YYClass *cls = [YYClass cachedWithClass:[self class]];
    id obj = [[[self class] alloc] init];
    if ([cls allPropertiesWithSuper].count >= dictionary.count) {
        for (NSString *key in dictionary.allKeys) {
            YYProperty *property;
            for (YYProperty *prop in [cls allPropertiesWithSuper]) {
                if ([prop.name isEqualToString:key]) {
                    property = prop;
                    break;
                }
            }
            id value = dictionary[key];
            if (property.isObject) {
                ((void (*)(id, SEL, id))objc_msgSend)(obj, [property setter], value);
            } else {
                NSNumber *n = value;
                ((void (*)(id, SEL, unsigned long))objc_msgSend)(obj, [property setter], n.unsignedLongValue);
            }
        }
    }
    return obj;
}

- (NSDictionary<NSString*, id>*)yy_modelToJSONObject {
    YYClass *cls = [YYClass cachedWithClass:[self class]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (YYProperty *property in [cls allPropertiesWithSuper]) {
        if (property.isObject) {
            dict[property.name] = ((id (*)(id, SEL))objc_msgSend)(self, [property getter]);
        } else {
            unsigned long n = ((unsigned long (*)(id, SEL))objc_msgSend)(self, [property getter]);
            dict[property.name] = [[NSNumber alloc] initWithUnsignedLong:n];;
        }
    }
    return dict;
}

@end
