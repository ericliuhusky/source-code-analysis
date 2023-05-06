#ifndef apple
#include "objc.h"
#else
#include "objc/message.h"
#endif
#include "stdio.h"

void classMethod(id self) { printf("classMethod\n"); }

void instanceMethod(id self) { printf("instanceMethod\n"); }

void swizzledMethod(id self) { printf("swizzled\n"); }

void swizzleInstanceMethod(Class oldCls, SEL oldSel, Class newCls, SEL newSel) {
  Method oldMethod = class_getInstanceMethod(oldCls, oldSel);
  Method newMethod = class_getInstanceMethod(newCls, newSel);

  if (class_addMethod(oldCls, oldSel, method_getImplementation(newMethod),
                      method_getTypeEncoding(newMethod))) {
    class_replaceMethod(newCls, newSel, method_getImplementation(oldMethod),
                        method_getTypeEncoding(oldMethod));
  } else {
    method_exchangeImplementations(oldMethod, newMethod);
  }
}

void swizzleClassMethod(Class oldCls, SEL oldSel, Class newCls, SEL newSel) {
  Method oldMethod = class_getClassMethod(oldCls, oldSel);
  Method newMethod = class_getClassMethod(newCls, newSel);

  if (class_addMethod(object_getClass((id)oldCls), oldSel,
                      method_getImplementation(newMethod),
                      method_getTypeEncoding(newMethod))) {
    class_replaceMethod(object_getClass((id)newCls), newSel,
                        method_getImplementation(oldMethod),
                        method_getTypeEncoding(oldMethod));
  } else {
    method_exchangeImplementations(oldMethod, newMethod);
  }
}

id call(id self, const char *sel) {
  return ((id(*)(id, SEL))objc_msgSend)(self, sel_registerName(sel));
}

int main() {
#ifndef apple
  createNSObject();
#endif

  Class A = objc_allocateClassPair(objc_getClass("NSObject"), "A", 0);
  objc_registerClassPair(A);

  class_addMethod(object_getClass((id)A), sel_registerName("classMethod"),
                  (IMP)classMethod, NULL);
  class_addMethod(A, sel_registerName("instanceMethod"), (IMP)instanceMethod,
                  NULL);

  // [A classMethod];
  call((id)A, "classMethod");
  // [[[A alloc] init] instanceMethod];
  call(call(call((id)A, "alloc"), "init"), "instanceMethod");

  Class B = objc_allocateClassPair(objc_getClass("NSObject"), "B", 0);
  objc_registerClassPair(B);

  class_addMethod(object_getClass((id)B), sel_registerName("swizzledMethod"),
                  (IMP)swizzledMethod, NULL);
  class_addMethod(B, sel_registerName("swizzledMethod"), (IMP)swizzledMethod,
                  NULL);

  swizzleClassMethod(A, sel_registerName("classMethod"), B,
                     sel_registerName("swizzledMethod"));
  swizzleInstanceMethod(A, sel_registerName("instanceMethod"), B,
                        sel_registerName("swizzledMethod"));

  call((id)A, "classMethod");
  call(call(call((id)A, "alloc"), "init"), "instanceMethod");

  return 0;
}
