//
//  ShutdownEvent.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-11.
//

import Foundation

class ShutdownEvent: Event {
    
    enum ShutdownUrgency: String, Decodable {
        case IMMEDIATE
        case GRACEFUL
    }
    
    class ShutdownData: Decodable {
        
        let urgency: ShutdownUrgency
        let reason: String
        
        init(urgency: ShutdownUrgency, reason: String) {
            self.urgency = urgency
            self.reason = reason
        }
    }
    
    typealias DataType = ShutdownData
    
    var eventID: UUID
    
    var eventData: ShutdownEvent.ShutdownData
    
    init(eventID: UUID, eventData: ShutdownData) {
        
        self.eventID = eventID
        self.eventData = eventData
    }
    
    func writeToQueue(eventQueue: Any) {
        
    }
    
    static func readFromQueue<EventType>(eventQueue: Any) -> EventType? where EventType : Event {
        
        return nil
    }
    
    func process() {
        
        DispatchQueue.global().async {
            switch self.eventData.urgency {
                
            case .IMMEDIATE:
                exit(-1)
                
            case .GRACEFUL:
                BusinessProcessor.stop()
            }
        }
    }
}
