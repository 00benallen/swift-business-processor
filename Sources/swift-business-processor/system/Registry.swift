//
//  Registry.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-10.
//

import Foundation

public protocol Registry {
    
    associatedtype RegistryKey: Hashable
    associatedtype RegistryItem
    
    var registry: [RegistryKey: RegistryItem] { get }
    
    func register(key: RegistryKey, item: RegistryItem) throws
    func retrieve(key: RegistryKey) -> RegistryItem?
    
}
