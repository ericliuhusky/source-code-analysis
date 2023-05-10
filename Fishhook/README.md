# Fishhook

遍历每个二进制镜像，遍历`__DATA`段和`__DATA_CONST`段的`got`(Global Offset Table)节  
在got中每个间接绑定地址的符号名如果和提供的重绑定符号名一样，返回间接绑定地址即为旧函数地址，并把间接绑定地址修改为新函数地址

在修改got的时候要调用`vm_protect`修改内存读写权限

```swift
import Darwin.C.stdlib
import Fishhook

typealias ExitFunc = @convention(c) (Int32) -> Void
var oldExit: (ExitFunc)?
rebindSymbol(name: "exit") { oldFunc in
    oldExit = oldFunc
    return { code in
        print("hooked")
        oldExit?(code + 3)
    } as ExitFunc
}
rebindWhenDyldAddImage()

exit(0)
```
