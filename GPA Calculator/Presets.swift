//
//  presets.swift
//  GPA Calculator
//
//  Created by michelg
//  Overhaul by WillUHD on 2025/11/18.
//
//  - updated version maps the data from plist into in-memory data
//  - accounts for complex course selection logic
//

import Foundation

// set name of the plist
struct fileConfig {
    static let presetsFilename = "presets"
}

// MARK: - datastructures
// must match with what plist says!
// kept michel's original names

struct ScoreToBaseGPAMap: Decodable {
    var percentageName:String
    var letterName:String
    var baseGPA:Double
}

struct Level: Decodable {
    var name: String
    var offset: Double
    var weightOverride: Double?
}

struct Subject: Decodable {
    var name: String
    var weight: Double
    var levels:[Level]
    var customScoreToBaseGPAMap:[ScoreToBaseGPAMap]?
}

struct Module: Decodable {
    var type: String // core/choice
    var name: String? // name of choice (M1, M2, etc)
    var selectionLimit: Int?
    var subjects: [Subject]
}

struct Preset: Decodable {
    var id: String
    var name: String
    var subtitle: String?
    var modules: [Module]
}

struct RootData: Decodable {
    var catalogName: String?
    var lastUpdated: String?
    var commonScoreMap: [ScoreToBaseGPAMap]
    var presets: [Preset]
}

// MARK: - global state
// the entire in-memory data model for the app

var rootData: RootData?
var presets: [Preset] = []
var commonScoreMap: [ScoreToBaseGPAMap] = []

// MARK: - initialize from plist

// get presets.plist, name customizable above
func getPlistURL() -> URL {
    let fileManager = FileManager.default
    
    // allow the method to point to the new plist file as soon as there is an update
    // dynamically updates each launch
    if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = documentDirectory.appendingPathComponent(fileConfig.presetsFilename + ".plist")
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
    }
    return Bundle.main.url(forResource: fileConfig.presetsFilename, withExtension: "plist")!
}

func initPresets() {
    let url = getPlistURL()
    guard let data = try? Data(contentsOf: url) else {
        
        // usually will never happen because the ota will check
        // but it will crash if some random thing happens
        fatalError("Could not load data from Presets.plist.")
    }
    
    let decoder = PropertyListDecoder()
    do {
        rootData = try decoder.decode(RootData.self, from: data)
        presets = rootData?.presets ?? []
        commonScoreMap = rootData?.commonScoreMap ?? []
    } catch {
        print("Failed to decode Presets.plist: \(error)")
        fatalError()
    }
}

// get the last selection made by user
func getActiveSubjects(for preset: Preset) -> [Subject] {
    var active: [Subject] = []
    let defaults = UserDefaults.standard
    
    for (modIndex, module) in preset.modules.enumerated() {
        if module.type == "core" {
            active.append(contentsOf: module.subjects)
        } else if module.type == "choice" {
            // check for each module
            let key = "config_\(preset.id)_mod_\(modIndex)"
            if let savedIndices = defaults.array(forKey: key) as? [Int] {
                for index in savedIndices {
                    if index < module.subjects.count {
                        active.append(module.subjects[index])
                    }
                }
            } else {
                // defaults to first i of selection
                let limit = module.selectionLimit ?? 0
                for i in 0..<min(limit, module.subjects.count) {
                    active.append(module.subjects[i])
                }
            }
        }
    }
    return active
}
