import MachO.dyld

typealias MachHeader = mach_header_64
typealias Segment = segment_command_64
typealias Section = section_64

var rebindingDict = [String: (UnsafeRawPointer) -> UnsafeRawPointer]()

public func rebindSymbol<CFunc>(name: String, block: @escaping (_ oldFunc: CFunc) -> CFunc) {
    rebindingDict["_\(name)"] = {
        unsafeBitCast(block(unsafeBitCast($0, to: CFunc.self)), to: UnsafeRawPointer.self)
    }
}

public func rebindWhenDyldAddImage() {
    _dyld_register_func_for_add_image { header, slide in
        guard let header = header?.withMemoryRebound(to: MachHeader.self, capacity: 1, { $0 }) else { return }
        
        _rebindSymbolsForImage(header: header, slide: slide)
    }
}

func _rebindSymbolsForImage(header: UnsafePointer<MachHeader>, slide: Int) {
    guard let symbolTable = SymbolTable(header: header, slide: slide) else { return }
    
    for section in header.gotSections {
        for i in 0..<(Int(section.size) / MemoryLayout<UnsafeRawPointer>.size) {
            guard let symbolName = symbolTable.indirectSymbolName(sectionIndex: Int(section.reserved1), index: i) else { continue }
            guard let rebindingBlock = rebindingDict[symbolName] else { continue }
            
            guard let indirectSymbolBindings = UnsafeMutablePointer<UnsafeRawPointer>(bitPattern: UInt(slide) + UInt(section.addr)) else { continue }
            let newFunc = rebindingBlock(indirectSymbolBindings[i])
            
            do {
                try protect(address: UInt(slide) + UInt(section.addr), size: UInt(section.size))
                indirectSymbolBindings[i] = newFunc
            } catch {}
        }
    }
}

struct SymbolTable {
    let symbolTable: UnsafePointer<nlist_64>
    let stringTable: UnsafePointer<CChar>
    let indirectSymbolTable: UnsafePointer<UInt32>
    
    init?(header: UnsafePointer<MachHeader>, slide: Int) {
        let segments = header.segments
        let linkedit_segment = segments.linkEditSegment
        let symtab_cmd = segments.symbolTableSegment
        let dysymtab_cmd = segments.dynamicSymbolTableSegment
        guard let linkedit_segment, let symtab_cmd, let dysymtab_cmd else { return nil }
        
        let linkedit_base = UInt(slide) + UInt(linkedit_segment.vmaddr - linkedit_segment.fileoff)
        guard let symtab = UnsafePointer<nlist_64>(bitPattern: linkedit_base + UInt(symtab_cmd.symoff)) else { return nil }
        guard let strtab = UnsafePointer<CChar>(bitPattern: linkedit_base + UInt(symtab_cmd.stroff)) else { return nil }
        guard let indirect_symtab = UnsafePointer<UInt32>(bitPattern: linkedit_base + UInt(dysymtab_cmd.indirectsymoff)) else { return nil }
        
        symbolTable = symtab
        stringTable = strtab
        indirectSymbolTable = indirect_symtab
    }
    
    func indirectSymbolName(sectionIndex: Int, index: Int) -> String? {
        let symbolTableIndex = indirectSymbolTable[sectionIndex + index]
        if symbolTableIndex == UInt32(INDIRECT_SYMBOL_ABS) || symbolTableIndex == INDIRECT_SYMBOL_LOCAL || symbolTableIndex == (UInt32(INDIRECT_SYMBOL_ABS) | INDIRECT_SYMBOL_LOCAL) {
            return nil
        }
        let stringTableIndex = symbolTable[Int(symbolTableIndex)].n_un.n_strx
        let symbolName = stringTable.advanced(by: Int(stringTableIndex))
        return String(cPointer: symbolName, count: strlen(symbolName))
    }
}

extension UnsafePointer<MachHeader> {
    var segmentPointers: [UnsafePointer<Segment>] {
        var segmentRawPointer = UnsafeRawPointer(advanced(by: 1))
        var segmentPointers = [UnsafePointer<Segment>]()
        for _ in 0..<pointee.ncmds {
            let segmentPointer = segmentRawPointer.assumingMemoryBound(to: Segment.self)
            segmentPointers.append(segmentPointer)
            segmentRawPointer = segmentRawPointer.advanced(by: Int(segmentPointer.pointee.cmdsize))
        }
        return segmentPointers
    }
    
    var segments: [Segment] {
        segmentPointers.map { pointer in
            pointer.pointee
        }
    }
    
    var gotSections: [Section] {
        var dataOrDataConstSections = [Section]()
        if let segment = segmentPointers.dataSegment {
            dataOrDataConstSections += segment.sections
        }
        if let segment = segmentPointers.dataConstSegment {
            dataOrDataConstSections += segment.sections
        }
        let gotSections = dataOrDataConstSections.filter { section in
            section.isGOT
        }
        return gotSections
    }
}

extension [Segment] {
    var linkEditSegment: Segment? {
        first { segment in
            segment.cmd == UInt32(LC_SEGMENT_64) && segment.segmentName == SEG_LINKEDIT
        }
    }
    
    var symbolTableSegment: symtab_command? {
        first { segment in
            segment.cmd == UInt32(LC_SYMTAB)
        }.map { segment in
            segment.toSymbolTableSegment()
        }
    }
    
    var dynamicSymbolTableSegment: dysymtab_command? {
        first { segment in
            segment.cmd == UInt32(LC_DYSYMTAB)
        }.map { segment in
            segment.toDynamicSymbolTableSegment()
        }
    }
}

extension Segment {
    var segmentName: String {
        String(cPointer: UnsafePointer(tuple: segname), count: 16)
    }
    
    func toSymbolTableSegment() -> symtab_command {
        withUnsafePointer(to: self) { pointer in
            pointer.withMemoryRebound(to: symtab_command.self, capacity: 1) { pointer in
                pointer.pointee
            }
        }
    }
    
    func toDynamicSymbolTableSegment() -> dysymtab_command {
        withUnsafePointer(to: self) { pointer in
            pointer.withMemoryRebound(to: dysymtab_command.self, capacity: 1) { pointer in
                pointer.pointee
            }
        }
    }
}

extension [UnsafePointer<Segment>] {
    var dataSegment: UnsafePointer<Segment>? {
        first { segment in
            segment.pointee.cmd == UInt32(LC_SEGMENT_64) && segment.pointee.segmentName == SEG_DATA
        }
    }
    
    var dataConstSegment: UnsafePointer<Segment>? {
        first { segment in
            segment.pointee.cmd == UInt32(LC_SEGMENT_64) && segment.pointee.segmentName == "__DATA_CONST"
        }
    }
}

extension UnsafePointer<Segment> {
    var sections: [Section] {
        let sectionPointer = advanced(by: 1).withMemoryRebound(to: Section.self, capacity: 1, { $0 })
        let buffer = UnsafeBufferPointer(start: sectionPointer, count: Int(pointee.nsects))
        return [Section](buffer)
    }
}

extension Section {
    var isGOT: Bool {
        Int32(flags) & SECTION_TYPE == S_LAZY_SYMBOL_POINTERS ||
        Int32(flags) & SECTION_TYPE == S_NON_LAZY_SYMBOL_POINTERS
    }
}

extension String {
    init(cPointer: UnsafePointer<CChar>, count: Int) {
        let buffer = UnsafeBufferPointer(start: cPointer, count: count)
        let cString = [CChar](buffer) + [0]
        self.init(cString: cString)
    }
}

extension UnsafePointer<CChar> {
    init(tuple: Any) {
        let pointer = withUnsafePointer(to: tuple) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { pointer in
                pointer
            }
        }
        self.init(pointer)
    }
}

func protect(address: UInt, size: UInt) throws {
    enum KernelError: Error {
        case notSuccess
    }
    
    let status = vm_protect(mach_task_self_, address, size, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY)
    if status != KERN_SUCCESS {
        throw KernelError.notSuccess
    }
}
