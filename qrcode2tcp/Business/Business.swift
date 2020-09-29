//
//  Business.swift
//  qrcode2tcp
//
//  Created by fcn on 2020/9/29.
//

import Foundation


class Business: NSObject {
    var rData: [UInt8] = []
    var startDate: NSDate?
    var updateDate: NSDate?

    
    class func createBusiness(fromReader bytes: [UInt8]) -> Business {
        return Business.init()
    }
}
