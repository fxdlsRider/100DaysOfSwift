//
//  ViewController.swift
//  Milestone Project 13-15
//
//  Created by Loris on 5/17/19.
//  Copyright © 2019 Loris. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    var countries = [Country]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Country Facts"
        
        if let urlPath = Bundle.main.url(forResource: "countries", withExtension: "json") {
            if let data = try? Data(contentsOf: urlPath) {
                parse(json: data)
            }
        }
    
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Country", for: indexPath)
        cell.textLabel?.text = countries[indexPath.row].name
        return cell
    }
    
    func parse(json: Data) {
        let decoder = JSONDecoder()
        
        if let data = try? decoder.decode([Country].self, from: json) {
            countries = data
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "DetailCountry") as? DetailCountry {
            vc.country = countries[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // https://restcountries.eu/rest/v2/all?fields=name;region;capital;population;demonym;nativeName
}

