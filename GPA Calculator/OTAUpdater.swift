//
//  OTAUpdater.swift
//  GPA Calculator
//
//  Created by WillUHD on 2025/11/25.
//
//  - updates the GPA profile from a continuously updated link in my github
//  - using gh-proxy cloudflare mirror for china use
//  - cached and used until next update
//

import UIKit

class SplashViewController: UIViewController {

    // url link
    @IBOutlet weak var statusLabel: UILabel!
    
    // using gh-proxy's edgeone cdn for fastest relay
    let updateURL = URL(string: "https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/presets.plist")!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkForUpdates()
    }

    func checkForUpdates() {
        let task = URLSession.shared.dataTask(with: updateURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                
                // fallback if fail
                if let error = error {
                    self.statusLabel.text = "No internet, fallback to last cached: \(self.getLastUpdatedDate())"
                    print("GPA Startup - Update check failed due to \(error)")
                    self.proceed(delay: 0.0)
                    return
                }
                
                // got plist
                guard let data = data else {
                    self.proceed(delay: 0.0)
                    return
                }
                
                // check plist, fallback if wrong (happens during testing)
                // makes sure all plists are fine so the fatal in presets won't occur (theoretically)
                do {
                    let newRoot = try PropertyListDecoder().decode(RootData.self, from: data)
                    
                    // cache this for next time
                    if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = docDir.appendingPathComponent(fileConfig.presetsFilename + ".plist")
                        try data.write(to: fileURL)
                        self.statusLabel.text = "Wow! found a new update at \(newRoot.lastUpdated ?? "i forgor")"
                    }
                    self.proceed(delay: 0.0)
                    
                } catch {
                    self.statusLabel.text = "Updated file is invalid, fallback to last cached: \(self.getLastUpdatedDate())"
                    self.proceed(delay: 0.0)
                }
            }
        }
        task.resume()
    }
    
    func getLastUpdatedDate() -> String {
        // look at the date in plist
        let url = getPlistURL()
        if let data = try? Data(contentsOf: url),
           let root = try? PropertyListDecoder().decode(RootData.self, from: data) {
            return root.lastUpdated ?? "i forgor"
        }
        return "default"
    }

    func proceed(delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.performSegue(withIdentifier: "toMain", sender: nil)
        }
    }
}
