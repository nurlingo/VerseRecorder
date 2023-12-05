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


struct SurahNames {
    static let juzAmma: [Int: (String, String)] = [
        1: ("الفاتحة", "Al-Fatiha"),
        78: ("النبأ", "An-Naba"),
        79: ("النازعات", "An-Nazi'at"),
        80: ("عبس", "Abasa"),
        81: ("التكوير", "At-Takwir"),
        82: ("الإنفطار", "Al-Infitar"),
        83: ("المطففين", "Al-Mutaffifin"),
        84: ("الإنشقاق", "Al-Inshiqaq"),
        85: ("البروج", "Al-Buruj"),
        86: ("الطارق", "At-Tariq"),
        87: ("الأعلى", "Al-Ala"),
        88: ("الغاشية", "Al-Ghashiyah"),
        89: ("الفجر", "Al-Fajr"),
        90: ("البلد", "Al-Balad"),
        91: ("الشمس", "Ash-Shams"),
        92: ("الليل", "Al-Lail"),
        93: ("الضحى", "Adh-Dhuha"),
        94: ("الشرح", "Ash-Sharh"),
        95: ("التين", "At-Tin"),
        96: ("العلق", "Al-Alaq"),
        97: ("القدر", "Al-Qadr"),
        98: ("البينة", "Al-Bayyinah"),
        99: ("الزلزلة", "Az-Zalzalah"),
        100: ("العاديات", "Al-Adiyat"),
        101: ("القارعة", "Al-Qari'a"),
        102: ("التكاثر", "At-Takathur"),
        103: ("العصر", "Al-Asr"),
        104: ("الهمزة", "Al-Humazah"),
        105: ("الفيل", "Al-Fil"),
        106: ("قريش", "Quraish"),
        107: ("الماعون", "Al-Ma'un"),
        108: ("الكوثر", "Al-Kawthar"),
        109: ("الكافرون", "Al-Kafirun"),
        110: ("النصر", "An-Nasr"),
        111: ("المسد", "Al-Masad"),
        112: ("الإخلاص", "Al-Ikhlas"),
        113: ("الفلق", "Al-Falaq"),
        114: ("الناس", "An-Nas")
    ]
}
