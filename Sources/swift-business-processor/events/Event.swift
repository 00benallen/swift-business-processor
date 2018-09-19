//
//  Event.swift
//
//  Created by Ben Pinhorn on 2018-09-07.
//

import Foundation


/**
 Protocol for a generic business event to be processed by the `BusinessProcessor`
 
 Conform to this Protocol to create a business event to be processed.
 
 */
public protocol Event {
    
    associatedtype DataType
    var eventID: UUID { get }
    var eventData: DataType { get set }
    
    func process() -> Void
    
}
