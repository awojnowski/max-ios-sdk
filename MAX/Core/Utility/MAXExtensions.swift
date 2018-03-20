//
//  MAXExtensions.swift
//  MAX
//
//  Created by Bryan Boyko on 3/13/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
