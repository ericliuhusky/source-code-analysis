#ifndef LZH_OBJC_H
#define LZH_OBJC_H

#include "stdbool.h"
#include <stddef.h>
#include <stdlib.h>

typedef struct objc_object *id;
typedef struct objc_class *Class;
typedef struct method_t *Method;
typedef uint8_t *SEL;
typedef id (*IMP)(id, SEL);

struct objc_object {
  Class isa;
};

struct method_t {
  SEL name;
  const char *types;
  IMP imp;
};

#ifdef __cplusplus
extern "C" {
#endif

Class objc_allocateClassPair(Class superclass, const char *name,
                             size_t extraBytes);
void objc_registerClassPair(Class cls);
Class objc_getClass(const char *name);
id objc_msgSend(id self, SEL sel);
bool class_addMethod(Class cls, SEL name, IMP imp, const char *types);
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
SEL sel_registerName(const char *name);
Class object_getClass(id obj);
Method class_getClassMethod(Class cls, SEL sel);
Method class_getInstanceMethod(Class cls, SEL sel);
IMP method_getImplementation(Method m);
const char *method_getTypeEncoding(Method m);
void method_exchangeImplementations(Method m1, Method m2);

void createNSObject(void);

#ifdef __cplusplus
}
#endif

#endif
