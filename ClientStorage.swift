//
//  ClientStorage.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 25.01.2023.
//

import Foundation

public protocol ClientStorage {
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
