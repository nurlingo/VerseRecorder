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
}
