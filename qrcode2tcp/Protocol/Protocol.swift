//
//  Protocol.swift
//  qrcode2tcp
//
//  Created by fcn on 2020/9/29.
//

import Foundation

@objc protocol ProtocolDelegate: NSObjectProtocol{
    func showQRCode(_ cont: String)
    func finish(_ pro: Protocol)
    func resetTimeSeconds(_ pro: Protocol)
}

class Protocol: NSObject{
    var seq: UInt16 = 0
    var nseq: UInt16 = 0
    var rseq: UInt16 = 0
    var status: ProtocolStatus = Status_CLOSE
    weak var delegate: ProtocolDelegate?
    var currentBusiness: Business?
    lazy var readStream: StreamTool = {
        let stream = StreamTool()
        stream.setup()
        return stream
    }()
    
    
    //PARAM MARK - 结果回调展示二维码
    func send(flag _flag: FlagType, payload _payload: [UInt8]) {
        var seqAdd: UInt64 = 0
        
        if _payload.count == 0 {
            seqAdd = 1
        }else{
            seqAdd = UInt64(_payload.count)
        }
            
        let p: Packet = Packet.createPacket(seq: self.nseq, ack: self.rseq+1, flag: _flag, window: WINDOWS_SIZE, bytes: _payload, bytesLen: UInt16(_payload.count))
        
        self.seq = self.nseq;
        self.nseq += UInt16(seqAdd);
        
        let b: [UInt8] = Packet.packetToByte(p)
        let data = NSData.init(bytes: b, length: b.count)
        let base64Str = data.base64EncodedString(options: .lineLength64Characters)
        if self.delegate != nil && self.delegate!.responds(to: #selector(delegate?.showQRCode(_:))) {
            self.delegate!.showQRCode(base64Str)
        }        
    }
    
    //PARAM MARK -
    func receive_packet(_ p: Packet){
        if p.flag == Flag_SYN {
            self.open(p)
        }else{
            self.handle_run(p)
        }
    }

    //PARAM MARK -
    func open(_ p: Packet) {
        if self.status != Status_WAIT {
            NSLog("protocol status is not wait")
            return
        }
        
        self.resetTimeSecondsCallback()
        
        self.status = Status_RUN
        
        //回复：SYN_ACK
        self.send(flag: Flag_SYN_ACK, payload: [])
    }
    
    //PARAM MARK -
    func handle_run(_ p: Packet) {
        
        if checkFlag(p.flag, self.status){
            NSLog("protocol status check packet flag fail.")
            
        }else if (p.flag == Flag_FIN){
            self.rseq = p.seq;
            self.status = Status_CLOSE_WAIT;
            self.perform(#selector(firstFinalPacket))
            self.perform(#selector(secondFinalPacket), with: nil, afterDelay: 3)
            self.perform(#selector(finish), with: nil, afterDelay: 6)
            
        }else if !self.check_ack(p) {
    //        NSLog(@"protocol check ack fail.");
        
        }else{// 加锁{}
            
            self.resetTimeSecondsCallback()

            self.rseq = p.seq
            
            let data = self.readStream.readData()
            
            var payload: [UInt8] = []
            if (data.length > 0) {
                payload = [UInt8](data)
            }
            self.send(flag: Flag_ACK, payload: payload)//发送确认报文，有数据带着数据出去
            
            //存储数据
            if (p.data.count > 0) {
                let bodyData = NSData.init(bytes: p.data, length: p.data.count)
                                

                if self.currentBusiness != nil {
                    self.currentBusiness!.rData += p.data
                    self.currentBusiness!.updateDate = NSDate.init()
                    self.handle_business()
                }else{
                    let business: Business = Business.createBusiness(fromReader: [UInt8](bodyData))
                    self.currentBusiness = business
                    self.currentBusiness!.startDate = NSDate.init()
                    self.currentBusiness!.updateDate = NSDate.init()
                    self.handle_business()
                }
            }
        }
    }
    
    //PARAM MARK -
    func handle_close_wait(_ p: Packet) {
        
    }
    
    //PARAM MARK -
    func handle_fin_wait(_ p: Packet) {
        
    }
    
    func handle_business() {
        
    }
    
    @objc func firstFinalPacket(){
        NSLog("第一个FIN包")
        self.send(flag: Flag_ACK, payload: [])
    }

    @objc func secondFinalPacket(){
        NSLog("第二个FIN包")
        self.send(flag: Flag_FIN_ACK, payload: [])
    }

    @objc func finish(){
        if self.delegate != nil && self.delegate!.responds(to: #selector(delegate?.finish(_:))) {
            self.delegate!.finish(self)
        }
    }

    func check_ack(_ p: Packet) -> Bool {
        if (p.ack != self.seq + 1){
    //        NSLog("read packet ack %d is not add 1 for self seq %d",p.ack,self.seq);
            return false
        }else{
            return true
        }
    }

    //PARAM MARK - 重设计时秒数
    func resetTimeSecondsCallback() {
        if self.delegate != nil && self.delegate!.responds(to: #selector(delegate?.resetTimeSeconds(_:))) {
            self.delegate!.resetTimeSeconds(self)
        }
    }
    class func randomSeqNum() -> UInt16{
        let seq = arc4random_uniform(UInt32(UINT16_MAX))
        return UInt16(seq)
    }

}
