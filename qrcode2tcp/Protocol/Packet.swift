//
//  Packet.swift
//  qrcode2tcp
//
//  Created by fcn on 2020/9/28.
//

import Foundation

let HEAD_SIZE = 8

struct Table {
    var entries: [UInt16] = [] //256位
    var reversed = false
    var noXOR = false
}

let CCITTFalsePoly = 0x1021


class Packet: NSObject {
    var seq: UInt16 = 0    // 序号
    var ack: UInt16 = 0    // 确认号
    var flag: UInt8 = 0    // 状态
    var window: UInt8 = 0  // 窗口大小
    var crc: UInt16 = 0    // 校验和
    var data: [UInt8] = [] // 数据
    var dLen: UInt16 = 0   // 数据长度
    static var CCITTFalseTable: Table = {
        var t = Table()
        t.reversed = true
        var poly = CCITTFalsePoly
        var width: UInt16 = 16
        for i in 0..<256{
            var crc = i << (width - 8)
            for j in 0..<8 {
                if (crc&(1<<(width-1))) != 0 {
                    crc = (crc << 1) ^ poly;
                } else {
                    crc <<= 1;
                }
            }
            t.entries[i] = UInt16(crc);
        }
        return t
    }()

    
    //PARAM MARK - 创建包
    class func createPacket(seq _seq: UInt16, ack _ack: UInt16, flag _flag: UInt8, window _window: UInt8, bytes _bytes: [UInt8], bytesLen _bytesLen: UInt16) -> Packet {
        let packet = Packet.init()
        packet.seq = _seq
        packet.ack = _ack
        packet.flag = _flag
        packet.window = _window
        packet.crc = 0
        packet.data = _bytes
        packet.dLen = _bytesLen
        
        let bData = packetToByte(packet)//封包
        packet.crc = getCrc16(bData)

        return Packet.init()
    }
    
    //PARAM MARK - Byte数组->数据包
    class func packetFromByte(_ bytes: [UInt8]) -> Packet{
        var b = bytes
        let p = Packet.init()

        let bLen: UInt32 = UInt32(bytes.count)
        if (bLen < HEAD_SIZE) {
            NSLog("data len %lu < headsize %d", bLen, HEAD_SIZE)
            return p;
        }
        let setCrc = (UInt16(b[6])) | (UInt16(b[7]))<<8
        b[6] = 0
        b[7] = 0
        let clcCrc = getCrc16(bytes);
        if (setCrc != clcCrc) {
            NSLog("crc check fail");
            return p;
        }

        p.seq = (UInt16(b[0])) | (UInt16(b[1])<<8);
        p.ack = (UInt16(b[2])) | (UInt16(b[3])<<8);
        p.flag = b[4];
        p.window = b[5];
        p.crc = setCrc;

        let pDataLen: UInt32 = bLen - UInt32(HEAD_SIZE);
        if pDataLen > 0 {
            let pData = b[8..<b.count]
            p.data = [UInt8](pData)
        }
        p.dLen = UInt16(pDataLen);
        return p;

    }

    //PARAM MARK - 数据包->Byte数组
    class func bussiness_packetToByte(_ p: Packet) -> [UInt8]{
        var r: [UInt8] = []
        r[0] = UInt8(p.seq);
        r[1] = UInt8(p.seq >> 8);
        r[2] = UInt8(p.seq >> 16);
        r[3] = UInt8(p.seq >> 24);
        r[4] = p.flag;
        r[5] = UInt8(p.crc);
        r[6] = UInt8(p.crc >> 8);
        r += p.data
        return r
    }
    
    //PARAM MARK - 数据包->Byte数组
    class func packetToByte(_ p: Packet) -> [UInt8] {
        var r: [UInt8] = []
        r[0] = UInt8(p.seq)
        r[1] = UInt8(p.seq >> 8)
        r[2] = UInt8(p.ack)
        r[3] = UInt8(p.ack >> 8)
        r[4] = UInt8(p.flag)
        r[5] = UInt8(p.window)
        r[6] = UInt8(p.crc)
        r[7] = UInt8(p.crc >> 8)
        r += p.data
        return r
    }
    
    
    
    //PARAM MARK - 计算crc
    class func getCrc16(_ bytes: [UInt8]) -> UInt16 {
        var b = bytes
        
        b[6] = 0
        b[7] = 0
        
        let crc = updateBitsReversed(0xffff, CCITTFalseTable, b)
        return crc
    }
    class func updateBitsReversed(_ crc: UInt16, _ tab: Table, _ bytes: [UInt8]) -> UInt16{
        var t_crc = crc
    
        for v in bytes {
            t_crc = tab.entries[Int(UInt16((UInt16(t_crc>>8)) ^ UInt16(v)))] ^ (t_crc << 8)
        }
        return t_crc;
    }

}


