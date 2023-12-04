//
//  Model.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import Foundation

public protocol RecorderItem {
    var id: String {get}
    var text: String {get}
    var meaning: String {get}
    var commentary: String {get}
    var image: String {get}
}

// MARK: - Ayah
public struct AyahPart: Codable {
    let pageNumber,surahNumber, ayahNumber: Int
    let partNumber: Int?
    let lines: [[WordCoordinate]]

    enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case surahNumber = "surah_number"
        case ayahNumber = "ayah_number"
        case lines = "lines"
        case partNumber = "part_number"
    }
    
    var id: String {
        let formattedSurahNumber = String(format: "%03d", surahNumber)
        let formattedAyahNumber = String(format: "%03d", ayahNumber)
        return "\(formattedSurahNumber)\(formattedAyahNumber)"
    }
}

// MARK: - WordCoordinate
public struct WordCoordinate: Codable {
    let x, y1, y2: CGFloat
}

struct RectangleData: Identifiable {
    var id: UUID = UUID()
    var rect: CGRect
}

struct Recording: Codable {
    let date: Date
    let first: String
    let last: String
    let uid: UUID
    
    init(first: String, last: String) {
        self.date = Date()
        self.first = first
        self.last = last
        self.uid = UUID()
    }
}
