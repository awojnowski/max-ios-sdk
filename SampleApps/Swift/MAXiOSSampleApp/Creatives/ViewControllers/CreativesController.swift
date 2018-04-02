//
//  SecondViewController.swift
//  MAXiOSSampleApp
//
//  Created by John Pena on 11/13/17.
//  Copyright © 2017 MAXAds. All rights reserved.
//

import UIKit

class CreativesController: UITableViewController {
    
    var creativeStore: CreativeStore = CreativeStore()
    
    static let creativeCellId = "CreativeCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = false
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CreativesController.creativeCellId)
    }
    
    
    //MARK: UITableViewDelegate and UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creativeStore.creatives.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CreativesController.creativeCellId, for: indexPath)
        let creative = creativeStore.creatives[indexPath.row]
        cell.textLabel?.text = creative.name
        cell.detailTextLabel?.text = creative.format
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let creative = creativeStore.creatives[indexPath.row]
        let creativeVC = CreativeController()
        creativeVC.creative = creative
        navigationController?.pushViewController(creativeVC, animated: true)
    }
}
