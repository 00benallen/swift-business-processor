//
//  EventProtocls.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-07.
//

import Foundation

public protocol Event {
    
    static var eventID: UUID { get }
    var eventData: Any { get set }
    
}

public protocol EventManipulator {
    static var manipulatableEventID: UUID { get }
}

public protocol EventBuilder: EventManipulator {
    
    func buildEvent(input: Any) -> Event
    
}

public protocol EventQueueWriter: EventManipulator {
    
    var builder: EventBuilder? {get set}
    
    func writeToQueue(input: Event) -> Void
    
}

public protocol EventQueueReader: EventManipulator {
    
    func readFromQueue() -> Event
    
}

public protocol EventProcessor: EventManipulator {
    
    func processEvent(input: Event) -> Any?
    
}
