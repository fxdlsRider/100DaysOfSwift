//
//  ViewController.swift
//  Project5
//
//  Created by Loris on 4/5/19.
//  Copyright © 2019 Loris. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startGame))
        
        if let startWordText = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordText) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        else if usedWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        startGame()
        
        usedWords = defaults.object(forKey: "usedWords") as? [String] ?? [String]()
        title = defaults.object(forKey: "title") as? String ?? allWords.randomElement()
    }
    
    @objc func startGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Insert word here:", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Add Word!", style: .default) {
            [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        if isPossible(word: lowerAnswer) {
            if isOriginal(word: lowerAnswer) {
                if isReal(word: lowerAnswer) {
                    if lowerAnswer.count > 3 {
                        if !(lowerAnswer == title) {
                            usedWords.insert(lowerAnswer, at: 0)
                            
                            save()
                            
                            let indexPath = IndexPath(row: 0, section: 0)
                            
                            tableView.insertRows(at: [indexPath], with: .automatic)
                            
                            return
                        } else {
                            showErrorMessage(errorTitle: "Too easy!", errorMessage: "Try another one.")
                        }
                    } else {
                        showErrorMessage(errorTitle: "Too Short", errorMessage: "Youre word is too short, try to make it at least 4.")
                    }
                } else {
                    showErrorMessage(errorTitle: "Word not recognized", errorMessage: "You can't just make that up, you know!")
                }
            } else {
                showErrorMessage(errorTitle: "World already used", errorMessage: "Be more original!")
            }
        } else {
            showErrorMessage(errorTitle: "World not possible", errorMessage: "You can't spell that word from \(title!.lowercased())")
        }
    }
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func showErrorMessage(errorTitle: String, errorMessage: String) {
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func save() {
        defaults.set(usedWords, forKey: "usedWords")
        defaults.set(title, forKey: "title")
    }
}

