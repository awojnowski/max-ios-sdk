//
//  MAXAdViewAdapterGeneratorStub.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
@testable import MAX

class MAXAdViewAdapterGeneratorStub: MAXAdViewAdapterGenerator {
    var identifier: String = ""
    func getAdViewAdapter(fromResponse: MAXAdResponse,
                          withSize: CGSize,
                          rootViewController: UIViewController?) -> MAXAdViewAdapter? {
        return MAXAdViewAdapterStub()
    }
}
