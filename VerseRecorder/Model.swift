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
    
    public var id: String {
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

public struct RangeRecording: Codable, Identifiable {
    let date: Date
    let start: String
    let end: String
    public let id: UUID
    
    init(start: String, end: String) {
        self.date = Date()
        self.start = start
        self.end = end
        self.id = UUID()
    }
    
    var title: String {
        
        if let startSurahNumber = Int(start.prefix(3)),
           let startAyahNumber = Int(start.suffix(3)),
            let startSurahName = SurahNames.juzAmma[startSurahNumber]?.1,
           let endSurahNumber = Int(end.prefix(3)),
              let endAyahNumber = Int(end.suffix(3)),
           let endSurahName = SurahNames.juzAmma[endSurahNumber]?.1 {
            
            let title = startSurahNumber == endSurahNumber ? "\(startSurahName) \(startAyahNumber)-\(endAyahNumber)" : "\(startSurahName) \(startAyahNumber) - \(endSurahName) \(endAyahNumber)"
            return title
        } else {
            return ""
        }
        
    }
    
    var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm"
        let dateString = formatter.string(from: date)
        return dateString
    }
    
    var url: URL {
        RecordingStorage.shared.getPath(for: id.uuidString)
    }
}
