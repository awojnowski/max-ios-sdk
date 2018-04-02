//
//  CreativeStore.swift
//  MAXiOSSampleApp
//
//  Created by Bryan Boyko on 1/23/18.
//  Copyright © 2018 MAXAds. All rights reserved.
//

import Foundation

class CreativeStore {
    
    var creatives: Array<Creative> = []
    
    // Ideally Assets directory is not in the top level, but for some reason assets couldn't be loaded for /MAXiOSSampleApp/Creatives/Assets
    static let creativesPath = "/Creatives"
    
    init() {
        let errorCreative = Creative(
            name: "No Creatives Found",
            adMarkup: "<html><h1>No creatives found in Creatives directory</h1></html>",
            format: "Error"
        )
        
        guard let path = Bundle.main.resourcePath else {
            print("Error opening Creatives directory: main resource path was undefined")
            self.creatives.append(errorCreative)
            return
        }
        
        var creativeDir: [String]? = nil
        do {
            creativeDir = try FileManager.default.contentsOfDirectory(atPath: path + CreativeStore.creativesPath)
        } catch {
            print("Error while enumerating files \(path + CreativeStore.creativesPath): \(error.localizedDescription)")
            self.creatives.append(errorCreative)
            return
        }
        
        for directory in creativeDir! {
            guard let formatDir = try? FileManager.default.contentsOfDirectory(atPath: path + CreativeStore.creativesPath + "/" + directory) else {
                print("Error opening Creatives sub-directory: \(directory)")
                self.creatives.append(errorCreative)
                return
            }
            
            for file in formatDir {
                let name = file
                let parts = file.components(separatedBy: ".")
                let format: String = parts[0]
                let filepath = "\(path)\(CreativeStore.creativesPath)/\(directory)/\(file)"
                let adMarkup = try! String(contentsOfFile: filepath)
                self.creatives.append(Creative(
                    name: name,
                    adMarkup: adMarkup,
                    format: format
                ))
            }
        }
        
        self.creatives = self.creatives.sorted(by: { $0.name < $1.name })
    }
}
