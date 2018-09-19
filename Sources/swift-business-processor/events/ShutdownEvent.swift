//
//  ShutdownEvent.swift
//
//  Created by Ben Pinhorn on 2018-09-11.
//

import Foundation

class ShutdownEvent: HttpInputEvent<ShutdownEvent.ShutdownData> {
    
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
    
    init(eventID: UUID, eventData: Data) throws {
        
        try super.init(eventID: eventID, rawHttpBody: eventData)
        
    }
    
    override func process() {
        
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
