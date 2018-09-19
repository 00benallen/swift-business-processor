//
//  System.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-10.
//

import Foundation

public class BusinessProcessor {
    
    static var server: HttpServer<HttpHandler>?
    
    static let pathHandlerRegistry: PathHandlerRegistry = PathHandlerRegistry()
    
    static let eventProcessingQueue = DispatchQueue(
        label: "BusinessProcessor[\(UUID.init())]-dispatchQueue",
        qos: .userInteractive,
        attributes: DispatchQueue.Attributes.concurrent,
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit)
    
    private static var started = false
    
    struct Configuration {
        var httpServerPort: Int
        var pathHandlers: [URL: (Data)->Void]?
    }
    
    enum BusinessProcessorError: Error {
        case HttpServerCouldNotStart
    }
    
    static func start(config: Configuration) throws {
        
        if config.pathHandlers != nil {
            
            for handlerEntry in config.pathHandlers! {
                try pathHandlerRegistry.register(key: handlerEntry.key, item: handlerEntry.value)
            }
            
        }
        
        do {
            print("Starting up HttpServer")
            try self.server = HttpServer(port: config.httpServerPort, autostart: false, httpHandler: HttpHandler())
            let closeFuture = try self.server?.start(port: 8080)
            started = true
            
            try closeFuture?.wait() //blocks forever
        } catch {
            throw BusinessProcessorError.HttpServerCouldNotStart
        }
    }
    
    static func stop() {
        
        do {
            guard let server = server else {
                print("No server online, terminating business processor.")
                exit(-1)
            }
            
            guard let loopGroup = server.loopGroup else {
                print("No threads to terminate, terminating business processor.")
                exit(-1)
            }
            
            try loopGroup.syncShutdownGracefully()
            
        } catch {
            print("Graceful shutdown failed, immediate shutdown executing.")
            exit(-1)
        }
        
        print("Shutting down...")
    }
}
