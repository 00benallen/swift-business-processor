//
//  PathHandlerRegistry.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-10.
//

import Foundation

public class PathHandlerRegistry: Registry {
    
    public typealias RegistryKey = URL
    
    public typealias RegistryItem = (Data) -> Void
    
    public var registry: [URL : RegistryItem] {
        get {
            return _registry
        }
    }
    
    private var _registry: [RegistryKey : RegistryItem]
    
    init() {
        _registry = [:]
    }
    
    public func register(key: RegistryKey, item: @escaping RegistryItem) throws {
        _registry[key] = item
    }
    
    public func retrieve(key: RegistryKey) -> RegistryItem? {
        return registry[key]
    }
    
}
