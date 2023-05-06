#include "objc.h"
#include <map>
#include <vector>

using namespace std;

struct objc_class : objc_object {
  Class superclass;
  const char *name;
  vector<Method> methods;
  bool isMetaClass;
};

map<const char *, Class> gdb_objc_realized_classes;

Class objc_allocateClassPair(Class superclass, const char *name,
                             size_t extraBytes) {
  if (gdb_objc_realized_classes.find(name) != gdb_objc_realized_classes.end()) {
    return NULL;
  }

  Class cls = (Class)calloc(1, sizeof(objc_class) + extraBytes);
  Class meta = (Class)calloc(1, sizeof(objc_class) + extraBytes);

  cls->name = name;
  meta->name = name;

  meta->isMetaClass = true;

  cls->isa = meta;
  cls->superclass = superclass;
  if (superclass != NULL) {
    Class supermeta = superclass->isa;
    meta->isa = supermeta->isa;
    meta->superclass = supermeta;
  }

  return cls;
}

void objc_registerClassPair(Class cls) {
  gdb_objc_realized_classes[cls->name] = cls;
}

Class objc_getClass(const char *name) {
  return gdb_objc_realized_classes[name];
}

Method getMethodNoSuper(Class cls, SEL sel) {
  for (int i = 0; i < cls->methods.size(); i++) {
    if (cls->methods[i]->name == sel) {
      return cls->methods[i];
    }
  }
  return NULL;
}

Method getMethod(Class cls, SEL sel) {
  while (cls != NULL) {
    Method method = getMethodNoSuper(cls, sel);
    if (method != NULL) {
      return method;
    }
    cls = cls->superclass;
  }
  return NULL;
}

IMP addMethod(Class cls, SEL name, IMP imp, const char *types, bool replace) {
  Method method = getMethodNoSuper(cls, name);
  if (method != NULL) {
    if (!replace) {
      return method->imp;
    } else {
      IMP old = method->imp;
      method->imp = imp;
      return old;
    }
  }

  method = (Method)calloc(1, sizeof(method_t));
  method->name = name;
  method->types = types;
  method->imp = imp;
  cls->methods.push_back(method);
  return NULL;
}

bool class_addMethod(Class cls, SEL name, IMP imp, const char *types) {
  if (cls == NULL) {
    return false;
  }

  return addMethod(cls, name, imp, types, false) == NULL;
}

IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types) {
  if (cls == NULL) {
    return NULL;
  }

  return addMethod(cls, name, imp, types, true);
}

IMP lookUpImp(Class cls, SEL sel) { return getMethod(cls, sel)->imp; }

IMP lookUpImpOrForward(Class cls, SEL sel) {
  IMP imp = lookUpImp(cls, sel);
  if (imp == NULL) {
    // resolveMethod
  }
  if (imp == NULL) {
    // messageForward
  }
  return imp;
}

id objc_msgSend(id self, SEL sel) {
  IMP imp = lookUpImpOrForward(self->isa, sel);
  return ((id(*)(id, SEL))imp)(self, sel);
}

SEL sel_registerName(const char *name) { return (SEL)name; }

Class object_getClass(id obj) { return obj->isa; }

Method class_getClassMethod(Class cls, SEL sel) {
  return getMethod(cls->isa, sel);
}

Method class_getInstanceMethod(Class cls, SEL sel) {
  return getMethod(cls, sel);
}

IMP method_getImplementation(Method m) { return m->imp; }

const char *method_getTypeEncoding(Method m) { return m->types; }

void method_exchangeImplementations(Method m1, Method m2) {
  IMP imp1 = m1->imp;
  IMP imp2 = m2->imp;
  m1->imp = imp2;
  m2->imp = imp1;
}

id alloc(id self) {
  id obj = (id)calloc(1, sizeof(self));
  obj->isa = (Class)self;
  return obj;
}

id init(id self) { return self; }

void createNSObject() {
  Class NSObject = objc_allocateClassPair(NULL, "NSObject", 0);
  objc_registerClassPair(NSObject);
  class_addMethod(object_getClass((id)NSObject), sel_registerName("alloc"),
                  (IMP)alloc, NULL);
  class_addMethod(NSObject, sel_registerName("init"), (IMP)init, NULL);
}
