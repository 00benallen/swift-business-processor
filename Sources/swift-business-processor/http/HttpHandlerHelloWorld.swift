//
//  HttpHandlerHelloWorld.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-06.
//

import Foundation
import NIO
import NIOHTTP1

class HttpHandlerHelloWorld: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart: HTTPServerRequestPart = unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let header):
            print("req:", header)
            
            let head = HTTPResponseHead(version: header.version,
                                        status: .ok)
            let part = HTTPServerResponsePart.head(head)
            _ = ctx.channel.write(part)
            
            var buffer = ctx.channel.allocator.buffer(capacity: 42)
            buffer.write(string: "Hello World!")
            let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))
            _ = ctx.channel.write(bodypart)
            
            let endpart = HTTPServerResponsePart.end(nil)
            _ = ctx.channel.writeAndFlush(endpart).then {
                ctx.channel.close()
            }
            
        // ignore incoming content to keep it micro :-)
        case .body, .end: break
        }
    }
}
