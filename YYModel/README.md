# YYModel

遍历字典，设置每个属性的值

KVC会遍历继承链，每次解析模型都遍历继承链太慢了，遂不用之

1. 用Runtime得到属性列表，根据规则计算setter和getter的SEL
2. 遍历字典，用Runtime向SEL发送消息，以设置每个属性的值
- 遍历继承链，得到包括父类的所有属性列表，以设置父类属性的值
- 用全局缓存字典缓存元信息，使仅模型第一次解析的时候需要遍历继承链和获取属性列表
- 发送消息时要区分OC的id类型和C的基础数据类型，C的基础数据类型要把NSNumber转化为C基础数据类型

```swift
let json: [String: Any] = [
    "uid": 123,
    "name": NSString("Harry"),
]

@objcMembers
class User: NSObject {
    var uid: UInt64 = 0
    var name: NSMutableString!
}

let user = User.yy_model(with: json)!
let dict = user.yy_modelToJSONObject()
dump(user)
print(dict)
```
