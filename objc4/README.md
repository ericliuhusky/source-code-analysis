# objc4

```cpp
typedef struct objc_object *id;
typedef struct objc_class *Class;

struct objc_object {
  Class isa;
};

struct objc_class : objc_object {
  Class superclass;
  const char *name;
  vector<Method> methods;
  bool isMetaClass;
};
```

`objc_allocateClassPair`分配一个类和一个元类，类的isa指针指向元类，类的suerpclass指针指向父类
`objc_registerClassPair`向全局类字典中插入类名和类

`class_addMethod`向类的方法列表中添加方法，实例方法添加到类中，类方法添加到元类中  
Method的name是方法的SEL，Method的imp是C函数的地址

`objc_msgSend`在对象的类或类的元类中遍历方法列表寻找与提供的SEL相同的方法，如果没有找到还会遍历继承链继续寻找
