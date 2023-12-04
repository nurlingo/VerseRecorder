//
//  RecordingStorage.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 25.01.2023.
//

import Foundation

class Storage: NSObject {
    
    static let shared = Storage()
    
    func store(_ anyObject: Any, forKey key: String) {
        UserDefaults.standard.set(anyObject, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func retrieve(forKey key: String) -> Any? {
        if let any = UserDefaults.standard.object(forKey: key) {
            return any
        } else {
            return nil
        }
    }
    
    func remove(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    func getAllItemKeys(withPrefix: String) -> [String] {
        return Array(UserDefaults.standard.dictionaryRepresentation().keys.filter { (key) -> Bool in
            return key.contains(withPrefix)
        })
    }
    
}

class RecordingStorage {
    
    static let shared = RecordingStorage()
    
    private let fileManager = FileManager.default
        
    func getRecordings() -> [Recording] {
        
        if let savedRecording = Storage.shared.retrieve(forKey: "recordings") as? Data {
            let decoder = JSONDecoder()
            if let loadedRecording = try? decoder.decode([Recording].self, from: savedRecording) {
                return loadedRecording
            }
        }
        return []
    }
    
    func addRecording(_ recording: Recording) {
        var recordings = getRecordings()
        recordings.append(recording)
        let encoder = JSONEncoder()
        if let encodedRecordings = try? encoder.encode(recordings) {
            Storage.shared.store(encodedRecordings, forKey: "recordings")
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        var recordings = getRecordings()
        recordings.removeAll(where: {$0.uid == recording.uid})
        let encoder = JSONEncoder()
        if let encodedRecordings = try? encoder.encode(recordings) {
            Storage.shared.store(encodedRecordings, forKey: "recordings")
        }
    }
    
    func getCountryCode() -> String {
        Storage.shared.retrieve(forKey: "countryCode") as? String ?? ""
    }
    
    func getPlatform() -> String {
        "ios"
    }
    
    func getQiraaah() -> String {
        "qaloon"
    }
    
    func recordingExists(_ recordingId: String) -> Bool {
        let path = getPath(for: recordingId).path
        return fileManager.fileExists(atPath: path)
    }
    
    func deleteRecording(_ recordingId: String) {
        if recordingId.isEmpty {
            return
        }
        
        let recordingUrl = getPath(for: recordingId)
        try? fileManager.removeItem(at: recordingUrl)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getPath(for recordingId: String) -> URL {
        getDocumentsDirectory().appendingPathComponent("\(recordingId.replacingOccurrences(of: "-", with: "")).m4a")
    }
}



