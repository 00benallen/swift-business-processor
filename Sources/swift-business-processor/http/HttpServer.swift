//
//  http-server.swift
//  swift-business-processor
//
//  Created by Ben Pinhorn on 2018-09-02.
//

import Foundation
import NIO
import NIOHTTP1

class HttpServer<T: ChannelInboundHandler> {
    
    enum HttpServerError: Error {
        case ServerStartFailed
    }
    
    let bootstrap: ServerBootstrap
    var serverChannel: Channel?
    var loopGroup: MultiThreadedEventLoopGroup?
    
    init(port: Int = 8080, autostart: Bool = false, httpHandler: T) throws {
        
        //Initialize event loop group, works like a concurrent queue of events-ish
        let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.loopGroup = loopGroup
        
        //Initialize socket configuration properties
        let reuseAddrOpt = ChannelOptions.socket(
            SocketOptionLevel(SOL_SOCKET),
            SO_REUSEADDR)
        
        //Use NIOs convenience bootstrap system, to initialize a server which will listen for HTTP
        let bootstrap = ServerBootstrap(group: loopGroup)
           
            //Backlog of HTTP requests to store before processing
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            
            //Initialize a channel
            // this is where to add more things to the pipeline (may make a initialization structure for this later)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().then { _ in
                    
                    channel.pipeline.add(handler: httpHandler)
                    
                }
            }
            
            .childChannelOption(ChannelOptions.socket(
                IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(reuseAddrOpt, value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead,
                                value: 1)
        
        self.bootstrap = bootstrap
        
        print("HttpServer boostrapped. Autostart: \(autostart)")
        
        if autostart {
            try start(port: port)
        }
    }
    
    func start(port: Int) throws {
        
        do {
            serverChannel =
                try bootstrap.bind(host: "localhost", port: port)
                    .wait()
            print("Server running on:", serverChannel?.localAddress ?? "unknown")
            
            try serverChannel?.closeFuture.wait() // runs forever
        }
        catch {
            throw HttpServerError.ServerStartFailed
        }
    }
}
















