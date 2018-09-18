//
//  EventProtocls.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-07.
//

import Foundation

public protocol Event {
    
    associatedtype DataType
    var eventID: UUID { get }
    var eventData: DataType { get set }
    
    func process() -> Void
    
}
