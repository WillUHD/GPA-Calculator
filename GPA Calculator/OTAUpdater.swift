//
//  OTAUpdater.swift
//  GPA Calculator
//
//  Created by WillUHD on 2025/11/22.
//
//  - Updates the plist document over the air, dynamically each startup
//

import Foundation

class OTAUpdater {
    
    static let shared = OTAUpdater()
    
    // using gh-proxy's edgeone cdn for fastest relay
    let updateURL = URL(string: "https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/presets.plist")!

    func checkForUpdates() {
        var request = URLRequest(url: self.updateURL)
        
        // IGNORE THE CACHE !!!
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30 // Don't wait forever
        
        DispatchQueue.global(qos: .background).async {
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                if let error = error {
                    print("GPA Update: Check failed (\(error))")
                    return
                }
                
                guard let data = data else { return }
                
                // verify
                do {
                    let newRoot = try PropertyListDecoder().decode(RootData.self, from: data)
                    
                    // save
                    if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = docDir.appendingPathComponent(fileConfig.presetsFilename + ".plist")
                        try data.write(to: fileURL)
                        
                        print("GPA Update: Downloaded version \(newRoot.lastUpdated ?? "unknown")")
                        
                        // notify download complete + verified
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("updatePreset"), object: nil)
                        }
                    }
                } catch {
                    print("GPA Update: Invalid data received")
                }
            }
            task.resume()
        }
    }
}
