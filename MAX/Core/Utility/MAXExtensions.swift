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

extension String {
    internal static func jsonToString(json: [String : Any]) -> String {
        do {
            let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
            let convertedString = String(data: data1, encoding: String.Encoding.utf8)
            return convertedString!
        } catch let myJSONError {
            print(myJSONError)
        }
        return ""
    }
}
