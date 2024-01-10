//
//  RecordingStorage.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 25.01.2023.
//

import Foundation

class RecordingStorage {
    
    static let shared = RecordingStorage()
    
    private let fileManager = FileManager.default
    
    func getRecordingRanges() -> [RangeRecording] {
        if let savedData = UserDefaults.standard.data(forKey: "rangeRecordings") {
            
            let decoder = JSONDecoder()
            
            do {
                let loadedRangeRecordings = try decoder.decode([RangeRecording].self, from: savedData)
                // Now you have your array of RangeRecording objects back
                return loadedRangeRecordings
            } catch {
                print("Failed to decode array of RangeRecordings: \(error)")
                return []
            }
        }

        return []
    }
    
    func recordingExists(_ recordingId: String) -> Bool {
        let path = getPath(for: recordingId).path
        return fileManager.fileExists(atPath: path)
    }
    
    func deleteRecording(_ recordingId: String) {
        if recordingId.isEmpty {
            return
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(recordingId).m4a")
        try? fileManager.removeItem(at: audioFilename)
        
    }
    
    func getPath(for recordingId: String) -> URL {
        getDocumentsDirectory().appendingPathComponent("\(recordingId).m4a")
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
}
