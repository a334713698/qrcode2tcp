//
//  Const.swift
//  qrcode2tcp
//
//  Created by fcn on 2020/9/28.
//

import Foundation

typealias FlagType = UInt8
typealias ProtocolStatus = UInt8

let Flag_FIN: FlagType = 1
let Flag_SYN: FlagType = 1 << 1
let Flag_ACK: FlagType = 1 << 4
let Flag_SYN_ACK: FlagType = Flag_ACK + Flag_SYN
let Flag_FIN_ACK: FlagType = Flag_ACK + Flag_FIN

let Status_WAIT: ProtocolStatus  = 0
let Status_RUN: ProtocolStatus  = 1
let Status_CLOSE_WAIT: ProtocolStatus  = 2
let Status_FIN: ProtocolStatus  = 3
let Status_FIN_WAIT: ProtocolStatus  = 4
let Status_CLOSE: ProtocolStatus  = 5

func getFlagType(_ flag: FlagType) -> String? {
    switch (flag) {
        case Flag_FIN:
            return "FIN"
        case Flag_SYN:
            return "SYN"
        case Flag_ACK:
            return "ACK"
        case Flag_SYN_ACK:
            return "SYN_ACK"
        case Flag_FIN_ACK:
            return "FIN_ACK"
        default:
            return nil
    }
}


func getProtocolStatus(_ status: ProtocolStatus) -> String?{
    switch (status) {
        case Status_WAIT:
            return "WAIT"
        case Status_RUN:
            return "RUN"
        case Status_CLOSE_WAIT:
            return "CLOSE_WAIT"
        case Status_FIN:
            return "FIN"
        case Status_FIN_WAIT:
            return "FIN_WAIT"
        case Status_CLOSE:
            return "CLOSE"
        default:
            return "unknow"
    }
}

func checkFlag(_ flag: FlagType, _ status: ProtocolStatus) -> Bool{
    if (status == Status_CLOSE) {
        return false
    }

    if (status == Status_WAIT &&  flag == Flag_SYN_ACK){
        return false
    }

    if (status == Status_RUN && (flag == Flag_ACK || flag == Flag_FIN)){
        return false
    }

    if (status == Status_CLOSE_WAIT && flag == Flag_ACK){
        return false
    }

    if (status == Status_FIN && flag == Flag_ACK) {
        return false
    }

    if (status == Status_FIN_WAIT && flag == Flag_FIN_ACK){
        return false
    }

    return true
}

