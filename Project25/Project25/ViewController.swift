//
//  ViewController.swift
//  Project25
//
//  Created by Loris on 6/29/19.
//  Copyright © 2019 Loris. All rights reserved.
//

import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    var images = [UIImage]()
    
    // Identify who you are
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    
    // Every Connections of users in you app
    var mcSession: MCSession?
    
    // Class that manages every connectons bewteen users in your session and display your session to others
    var mcAdevtiserAssistant: MCAdvertiserAssistant?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        
        let importPictureBtn = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        let sendMessageBtn = UIBarButtonItem(title: "Chat", style: .plain, target: self, action: #selector(sendMessage))
        navigationItem.rightBarButtonItems = [importPictureBtn, sendMessageBtn]
        
        let actionBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        let peerConnectedBtn = UIBarButtonItem(title: "Users", style: .plain, target: self, action: #selector(showConnectedPeers))
        navigationItem.leftBarButtonItems = [actionBtn, peerConnectedBtn]
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    @objc func sendMessage() {
        guard let mcSession = mcSession else { return }
        
        if mcSession.connectedPeers.count > 0 {
            
            let ac = UIAlertController(title: "Send a message", message: nil, preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Send", style: .default) { action in
                guard ac.textFields?[0].text?.count != 0 else { return }
                
                let stringToSend = mcSession.myPeerID.displayName + ": " + (ac.textFields?[0].text)!
                let stringData = Data(stringToSend.utf8)
                
                // Try to send data to peers
                do {
                    try mcSession.send(stringData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    // show a message in case of an error
                    let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            } )
            
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "There are no users connected", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
    }
    
    @objc func showConnectedPeers() {
        guard let mcSession = mcSession else { return }
        
        if mcSession.connectedPeers.count == 0 {
            let ac = UIAlertController(title: "There are no users connected", message: "Try to host a session, or join one", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            var peers = ""
            
            for (index, peer) in mcSession.connectedPeers.enumerated() {
                peers += "\(index + 1). " + peer.displayName + "\n"
            }
            
            let ac = UIAlertController(title: "Connected Peers:", message: peers, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        
        // .viewWithTag() can search inside the subclasses to return a view with a specified tag
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.row]
        }
        
        return cell
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        // Send data to peers
        guard let mcSession = mcSession else { return }
        
        // If there are people connected
        if mcSession.connectedPeers.count > 0 {
            // If we can create PNG data from an image
            if let imageData = image.pngData() {
                do {
                    // send the data to all the peers (users) connected
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    // show a message in case of an error
                    let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }

    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        mcAdevtiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        mcAdevtiserAssistant?.start()
    }
    
    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    // 3 methods required for MCSessionDelegate
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    // 2 methods required to implement when finishing or canceling the MCBrowserViewController
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    // methods required to implement MCSessionDelegate and MCBrowserViewControllerDelegate
    // can be used to see the state (connected, connecting, disconnected) of the peer (user)
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            DispatchQueue.main.async { [weak self] in
                let ac = UIAlertController(title: "Connected: \(peerID.displayName)", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true)
            }
            
            
        case .connecting:
            print("Connecting: \(peerID.displayName)")
            
            
        case .notConnected:
            DispatchQueue.main.async { [weak self] in
                let ac = UIAlertController(title: "Not Connected: \(peerID.displayName)", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true)
            }
            
            
        @unknown default:
            DispatchQueue.main.async { [weak self] in
                let ac = UIAlertController(title: "Unknown state received: \(peerID.displayName)", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true)
            }
            
        }
    }
    
    // methods required to implement MCSessionDelegate and MCBrowserViewControllerDelegate
    // With this method you can manipulate data sent between peers
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            } else {
                let message = String(decoding: data, as: UTF8.self)
                
                let ac = UIAlertController(title: "You recieved a message", message: message, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true)
            }
        }
    }

}

