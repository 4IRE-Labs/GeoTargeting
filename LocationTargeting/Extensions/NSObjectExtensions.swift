//
//  NSObjectExtensions.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation

extension NSObject {
    var className: String {
        return type(of: self).className
    }
    
    class var className: String {
        return String(describing: self).components(separatedBy: ".").last!
    }
}
