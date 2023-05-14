public class Object<T> {
    let stackPointer: UnsafeMutablePointer<T>
    let kind: Kind
    let propertyOffsetDict: [String: Int]
    
    public init(_ stackPointer: UnsafeMutablePointer<T>) {
        self.stackPointer = stackPointer
        kind = Kind(type: T.self)
        
        switch kind {
        case .struct:
            let meta = unsafeBitCast(T.self, to: UnsafeMutablePointer<StructMetadata>.self)
            propertyOffsetDict = meta.pointee.propertyOffsetDict
        case .class:
            let meta = unsafeBitCast(T.self, to: UnsafeMutablePointer<ClassMetadata>.self)
            propertyOffsetDict = meta.pointee.propertyOffsetDict
        case .tuple:
            let meta = unsafeBitCast(T.self, to: UnsafeMutablePointer<TupleMetadata>.self)
            propertyOffsetDict = meta.pointee.propertyOffsetDict
        }
    }
    
    func propertyPointer<Value>(forKey key: String, type: Value.Type) -> UnsafeMutablePointer<Value>? {
        if let offset = propertyOffsetDict[key] {
            switch kind {
            case .struct, .tuple:
                let propertyPointer = UnsafeMutableRawPointer(stackPointer).advanced(by: offset).assumingMemoryBound(to: Value.self)
                return propertyPointer
            case .class:
                let heapPointer = unsafeBitCast(stackPointer.pointee, to: UnsafeMutableRawPointer.self)
                let propertyPointer = heapPointer.advanced(by: offset).assumingMemoryBound(to: Value.self)
                return propertyPointer
            }
        }
        return nil
    }
    
    public func setValue<Value>(_ value: Value, forKey key: String) {
        if let property = propertyPointer(forKey: key, type: Value.self) {
            property.pointee = value
        }
    }
    
    public func value<Value>(forKey key: String) -> Value? {
        if let property = propertyPointer(forKey: key, type: Value.self) {
            return property.pointee
        }
        return nil
    }
}

enum Kind {
    case `struct`
    case `class`
    case tuple

    init<T>(type: T.Type) {
        let kind = unsafeBitCast(type, to: UnsafePointer<Int>.self)
        switch kind.pointee {
        case 0:
            self = .class
        case 0x200:
            self = .struct
        case 0x301:
            self = .tuple
        default:
            self = .class
        }
    }
}

protocol TypeMetadata {
    associatedtype SomeTypeDescriptor: TypeDescriptor
    associatedtype FieldOffsetType: BinaryInteger
    var typeDescriptor: UnsafeMutablePointer<SomeTypeDescriptor> { get }
}

extension TypeMetadata {
    var fieldOffsets: [Int] {
        mutating get {
            let offset = typeDescriptor.pointee.offsetToTheFieldOffsetVector
            let filedOffsetVector = withUnsafePointer(to: &self) { pointer in
                pointer.withMemoryRebound(to: Int.self, capacity: 1) { pointer in
                    pointer.advanced(by: Int(offset)).withMemoryRebound(to: FieldOffsetType.self, capacity: 1, { $0 })
                }
            }
            return UnsafeBufferPointer(start: filedOffsetVector, count: typeDescriptor.pointee.numberOfFields).map(Int.init)
        }
    }
    
    var propertyOffsetDict: [String: Int] {
        mutating get {
            var dict = [String: Int]()
            let offsets = fieldOffsets
            let fields = typeDescriptor.pointee.fieldDescriptor.pointee.fields
            for i in 0..<typeDescriptor.pointee.numberOfFields {
                let fieldName = fields[i].fieldName
                dict[fieldName] = offsets[i]
            }
            return dict
        }
    }
}

struct StructMetadata: TypeMetadata {
    typealias FieldOffsetType = Int32
    
    let __unusedPlaceholder: Int
    var typeDescriptor: UnsafeMutablePointer<StructDescriptor>
}

struct ClassMetadata: TypeMetadata {
    typealias FieldOffsetType = Int
    
    let __unusedPlaceholder1: Int
    var superClass: Any.Type
    let __unusedPlaceholder2: (Int, Int, Int, Int, Int, Int)
    var typeDescriptor: UnsafeMutablePointer<ClassDescriptor>
}

protocol TypeDescriptor {
    var _numberOfFields: Int32 { get }
    var fieldDescriptorOffset: Int32 { get set }
    var offsetToTheFieldOffsetVector: Int32 { get }
}

extension TypeDescriptor {
    var fieldDescriptor: UnsafeMutablePointer<FieldDescriptor> {
        mutating get {
            let offset = fieldDescriptorOffset
            let fieldDescriptor = withUnsafePointer(to: &fieldDescriptorOffset) { p in
                UnsafeMutableRawPointer(mutating: p).advanced(by: Int(offset))
                    .assumingMemoryBound(to: FieldDescriptor.self)
            }
            return fieldDescriptor
        }
    }
    
    var numberOfFields: Int {
        Int(_numberOfFields)
    }
}

struct StructDescriptor: TypeDescriptor {
    let __unusedPlaceholder: (Int, Int)
    var fieldDescriptorOffset: Int32
    var _numberOfFields: Int32
    var offsetToTheFieldOffsetVector: Int32
}

struct ClassDescriptor: TypeDescriptor {
    let __unusedPlaceholder1: (Int, Int)
    var fieldDescriptorOffset: Int32
    let __unusedPlaceholder2: (Int32, Int32, Int32, Int32)
    var _numberOfFields: Int32
    var offsetToTheFieldOffsetVector: Int32
}

struct FieldDescriptor {
    let __unusedPlaceholder: (Int, Int)
    var _fields: Field
    
    var fields: UnsafeMutablePointer<Field> {
        mutating get {
            withUnsafeMutablePointer(to: &_fields, { $0 })
        }
    }
}

struct Field {
    let __unusedPlaceholder: (Int32, Int32)
    var fieldNameOffset: Int32
    
    var fieldName: String {
        mutating get {
            let offset = fieldNameOffset
            let namePtr = withUnsafePointer(to: &fieldNameOffset) { pointer in
                UnsafeRawPointer(pointer).advanced(by: Int(offset)).assumingMemoryBound(to: CChar.self)
            }
            return String(cString: namePtr)
        }
    }
}

struct TupleMetadata {
    var _kind: Int
    var numberOfElements: Int
    var _labels: UnsafeMutablePointer<CChar>
    var _elements: TupleElement
    
    var elements: UnsafeMutablePointer<TupleElement> {
        mutating get {
            withUnsafeMutablePointer(to: &_elements, { $0 })
        }
    }
    
    var labels: [String] {
        String(cString: _labels).split(separator: " ").map(String.init)
    }
    
    var elementOffsets: [Int] {
        mutating get {
            (0..<numberOfElements).map { i in
                elements[i].offset
            }
        }
    }
    
    var propertyOffsetDict: [String: Int] {
        mutating get {
            var dict = [String: Int]()
            for i in 0..<numberOfElements {
                dict[labels[i]] = elementOffsets[i]
            }
            return dict
        }
    }
}

struct TupleElement {
    var type: Any.Type
    var offset: Int
}
