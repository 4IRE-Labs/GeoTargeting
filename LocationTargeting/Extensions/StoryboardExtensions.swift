//
//  StoryboardExtensions.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import UIKit

extension UIStoryboard {
    func instatiate<T: UIViewController> (identifier: String = T.className) -> T {
        return instantiateViewController(withIdentifier: identifier) as! T
    }
    
    static var main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
}
