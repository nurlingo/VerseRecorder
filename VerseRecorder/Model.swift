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

// MARK: - PageElement
public struct Page: Codable {
    let pageNumber: Int
    let ayahs: [AyahCoordinate]

    enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case ayahs
    }
}

// MARK: - Ayah
public struct AyahCoordinate: Codable {
    let surahNumber, ayahNumber: Int
    let lines: [[WordCoordinate]]

    enum CodingKeys: String, CodingKey {
        case surahNumber = "surah_number"
        case ayahNumber = "ayah_number"
        case lines = "lines"
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
