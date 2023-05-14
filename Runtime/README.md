# Runtime

根据Swift ABI规则，读取类型元信息中存储的每个属性的地址偏移值  
栈上类型的基地址是变量的地址，堆上类型的基地址是变量的值  
以基地址和地址偏移，来直接读写内存，达到KVC的目的

```swift
struct User {
    let id: Int
    let username: String
    let email: String
}

var a = User(id: 0, username: "", email: "")
Object(&a).setValue("ericliu", forKey: "username")
print(Object(&a).value(forKey: "username") as String?)
```
