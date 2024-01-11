//
//  Model.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import Foundation

public protocol ClientStorage {
    
    func getReciterId() -> String
    func saveReciterId(_ reciterId: String)
    func getGender() -> String
    func getCountryCode() -> String
    func getAge() -> String
    func getPlatform() -> String
    func getQiraaah() -> String
    
}

public protocol Range {
    var id: String {get}
    var title: String {get}
    var tracks: [Track] {get}
}

public protocol Track {
    var id: String {get}
    var text: String {get}
    var meaning: String {get}
}

public class RangeRecording: Codable, Identifiable {
    
    public let id: UUID
    let date: Date
    let audioId: String
    
    var tracks: [String: TrackRecording] = [:] {
        didSet {
            if tracks.isEmpty {
                deleteRange()
            } else {
                saveRange()
            }
        }
    }
    
    init(audioId: String) {
        self.id = UUID()
        self.audioId = audioId
        self.date = Date()
    }
    
    func saveRange() {
        
        var rangeRecordings = RecordingStorage.shared.getRecordingRanges()
        
        if let existingRangeRecordingIndex = rangeRecordings.firstIndex(where: {$0.id == self.id}) {
            rangeRecordings[existingRangeRecordingIndex] = self
        } else {
            rangeRecordings.append(self)
        }
                
        do {
            let encodedData = try JSONEncoder().encode(rangeRecordings)
            UserDefaults.standard.set(encodedData, forKey: "rangeRecordings")
        } catch {
            print("Failed to encode RangeRecording: \(error)")
        }
    }
    
    func deleteRange() {

        var rangeRecordings = RecordingStorage.shared.getRecordingRanges()
        
        if let index = rangeRecordings.firstIndex(where: { $0.id == self.id }) {
            rangeRecordings.remove(at: index)
        }

        do {
            let encodedData = try JSONEncoder().encode(rangeRecordings)
            UserDefaults.standard.set(encodedData, forKey: "rangeRecordings")
        } catch {
            print("Failed to encode updated array of RangeRecordings: \(error)")
        }
    }
    
    func addTrack(_ trackId: String) {
        tracks[trackId] = TrackRecording(id: trackId, remoteId: nil)
    }
    
    func getPathForTrack(_ trackId: String) -> URL {
        RecordingStorage.shared.getPath(for: "\(id.uuidString)-\(trackId)")
    }
    
    func trackRecordingExists(_ trackId: String) -> Bool {
        RecordingStorage.shared.recordingExists("\(id.uuidString)-\(trackId)")
    }
    
    func trackRecordingUploaded(_ trackId: String) -> Bool {
        tracks[trackId]?.remoteId != nil
    }
    
    func hasTrackRecordingsToUpload() -> Bool {
        !tracks.values.filter({ $0.remoteId == nil }).isEmpty
    }
    
    func deleteTrackRecording(_ trackId: String) {
        RecordingStorage.shared.deleteRecording("\(id.uuidString)-\(trackId)")
        tracks[trackId] = nil
    }
    
    func getTrackRecordingLabel(_ trackId: String) -> TrackRecording.RecitationLabel? {
        tracks[trackId]?.label
    }
}


public struct TrackRecording: Codable, Identifiable {
    public let id: String
    public var remoteId: String?
    public var label: RecitationLabel?

    public enum RecitationLabel: String, Codable {
        case correct // checkmark.circle
        case in_correct // xmark.circle
        case not_related_quran // exclamationmark.circle
        case not_match_aya // arrow.left.arrow.right
        case multiple_aya // number.circle
        case in_complete // ellipsis.circle
    }
    
    func updatedRecordingWithRemoteId(_ remoteId: String) -> TrackRecording {
        TrackRecording(id: id, remoteId: remoteId, label: label)
    }
    
    func updatedRecordingWithLabel(_ labelString: String) -> TrackRecording {
        TrackRecording(id: id, remoteId: remoteId, label: RecitationLabel(rawValue: labelString))
    }
}
