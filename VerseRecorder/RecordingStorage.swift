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
        
    private var recordingDates: [String:Date] = {
        if let dict: [String:Date] = UserDefaults.standard.object(forKey: "recordingDates") as? [String:Date] {
            return dict
        } else {
            return [:]
        }
    }() {
        didSet {
            UserDefaults.standard.set(recordingDates, forKey: "recordingDates")
        }
    }
    
    private var uploadedRecordingDates: [String:Date] = {
        if let dict: [String:Date] = UserDefaults.standard.object(forKey: "uploadedRecordingDates") as? [String:Date] {
            return dict
        } else {
            return [:]
        }
    }() {
        didSet {
            UserDefaults.standard.set(uploadedRecordingDates, forKey: "uploadedRecordingDates")
        }
    }
    
    func recordingExists(_ trackId: String) -> Bool {
        let path = getPath(for: trackId).path
        return fileManager.fileExists(atPath: path)
    }
    
    func deleteRecording(_ trackId: String) {
        if trackId.isEmpty {
            return
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording-\(trackId).m4a")
        try? fileManager.removeItem(at: audioFilename)
        
        unregisterRecordingDate(trackId)
        unregisterUploadingDate(trackId)
    }
    
    func doesRecordingExist(_ trackId: String) -> Bool {
        let path = getDocumentsDirectory().appendingPathComponent("recording-\(trackId).m4a").path
        return fileManager.fileExists(atPath: path)
    }
    
    func registerRecordingDate(_ trackId: String) {
        recordingDates[trackId] = Date()
    }
    
    private func unregisterRecordingDate(_ trackId: String) {
        recordingDates.removeValue(forKey: trackId)
    }
    
    func registerUploadingDate(_ trackId: String) {
        self.uploadedRecordingDates[trackId] = self.recordingDates[trackId]
    }
    
    private func unregisterUploadingDate(_ trackId: String) {
        self.uploadedRecordingDates.removeValue(forKey: trackId)
    }
    
    func didUploadRecording(_ trackId: String) -> Bool {
        
        guard doesRecordingExist(trackId) else {return false}
        
        guard self.recordingDates[trackId] != nil else {return false}
        
        let didUpload = self.uploadedRecordingDates[trackId] == self.recordingDates[trackId]
        
        return didUpload
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getPath(for trackId: String) -> URL {
        getDocumentsDirectory().appendingPathComponent("recording-\(trackId).m4a")
    }
}
