//
//  AudioPlayer.swift
//  namaz
//
//  Created by Daniya on 11/01/2020.
//  Copyright © 2020 Nursultan Askarbekuly. All rights reserved.
//

import Foundation

public struct Credentials {
    let remoteAPI: String
    let username: String
    let password: String
    
    public init(remoteAPI: String, username: String, password: String) {
        self.remoteAPI = remoteAPI
        self.username = username
        self.password = password
    }
}


public protocol ClientStorage {
    
    func saveRecordProgress(_ recordingId: String, progress: Double)
    func getRecordProgress(_ recordingId: String) -> Double
    
    func saveUploadProgress(_ recordingId: String, progress: Double)
    func getUploadProgress(_ recordingId: String) -> Double
    
    func getReciterId() -> String
    func saveReciterId(_ reciterId: String)
    func getGender() -> String
    func getCountryCode() -> String
    func getAge() -> String
    func getPlatform() -> String
    func getQiraaah() -> String
    
}


@available(iOS 15.0.0, *)
class QuranAppUploader {
    
    let rangeRecordingStorage = RangeRecordingStorage.shared
    
    func upload(_ recording: RangeRecording) async {
        
        // FIXME: this is not reusable actually.
        
        guard let startSurahNumber = Int(recording.start.prefix(3)),
           let startAyahNumber = Int(recording.start.suffix(3)),
           let endSurahNumber = Int(recording.end.prefix(3)),
              let endAyahNumber = Int(recording.end.suffix(3)) else {
            print("error getting surah and ayah numbers")
            return
        }
        
        print("uploading \(recording.id.uuidString)")
        
        let recordingData: [String: Any] = [
            "start": [
                "surah_number": startSurahNumber,
                "ayah_in_surah_number": startAyahNumber,
                "part_number": 0
            ],
            "end": [
                "surah_number": endSurahNumber,
                "ayah_in_surah_number": endAyahNumber,
                "part_number": 1
            ],
            "riwayah": "Qaloon",
            "user_id": "1"
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: recordingData)
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) }

        guard let encodedJsonString = jsonString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("failed to encode the json string")
            return
        }
        
        let urlString = "https://quranapp-91342138aec0.herokuapp.com/recordings/upload?recording_data=\(encodedJsonString)"
        
        guard let url = URL(string: urlString) else {
            print("error: URL creation failed")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let path = rangeRecordingStorage.getPath(for: recording.id.uuidString)
            let audioData = try Data(contentsOf: path)
            
            var data = Data()
            
            // Add the image data to the raw http request data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"\(recording.id.uuidString).m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
            
            if let string = String(data: responseData, encoding: .utf8) {
                print(string)
            }
        
            print(response)
            
            
        } catch {
            print(#file, #function, #line, #column, error.localizedDescription)
        }
    }
    
    func getRecordings() async -> RangeRecording {
        return RangeRecording(start: "", end: "")
    }
}
