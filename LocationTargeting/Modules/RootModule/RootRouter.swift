//
//  RootRouter.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 15.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import UIKit

class RootRouter {
    func presentMapScreen(in window: UIWindow) {
        window.makeKeyAndVisible()
        window.rootViewController = MapViewRouter.assembleModule()
    }
}
