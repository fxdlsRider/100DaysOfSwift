//
//  ViewController.swift
//  Project7
//
//  Created by Loris on 4/12/19.
//  Copyright © 2019 Loris. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    var petitions = [Petition]()
    var filteredResults = [Petition]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Credit", style: .plain, target: self, action: #selector(showCredit))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(submitFilter))
        
        let urlString: String
        
        if navigationController?.tabBarItem.tag == 0 {
            urlString = "https://api.whitehouse.gov/v1/petitions.json?limit=100"
        } else {
            urlString = "https://api.whitehouse.gov/v1/petitions.json?signatureCountFloor=10000&limit=100"
        }
        
        if let url = URL(string: urlString) {
            if let data = try? Data(contentsOf: url) {
                parse(json: data)
                return
            }
        }
        
        showError()
    }
    
    @objc func submitFilter() {
        let ac = UIAlertController(title: "What are you looking for?", message: nil, preferredStyle: .alert)
        
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Search", style: .default) {
            [weak self, weak ac] _ in
            guard let filterString = ac?.textFields?[0].text else { return }
            self?.search(filter: filterString)
        })
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func search(filter: String) {
        for item in petitions {
            if item.title.contains(filter) || item.body.contains(filter) {
                filteredResults.insert(item, at: 0)
            }
        }
        petitions = filteredResults
        tableView.reloadData()
    }
    
    @objc func showCredit() {
        let ac = UIAlertController(title: "Credit:", message: "This data comes from the We The People API of the Whitehouse.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func showError() {
        let ac = UIAlertController(title: "Loading error", message: "there was a problem loading the feed; please check your connection and try again.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func parse(json: Data) {
        let decoder = JSONDecoder()
        
        if let data = try? decoder.decode(Petitions.self, from: json) {
            petitions = data.results
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return petitions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let petition = petitions[indexPath.row]
        cell.textLabel?.text = petition.title
        cell.detailTextLabel?.text = petition.body
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DetailViewController()
        vc.detailItem = petitions[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

