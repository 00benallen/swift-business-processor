//
//  BenchmarkEvent.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-18.
//

import Foundation

class BenchmarkEvent: HttpInputEvent<BenchmarkEvent.Body> {
    
    class Body: Decodable {
        var value: Int
        
        init(value: Int) {
            self.value = value
        }
    }
    
    override func process() {
        sleep(5)
        
        
        print("Benchmark event w/ UUID \(eventID) finished processing")
    }
    
    
}
