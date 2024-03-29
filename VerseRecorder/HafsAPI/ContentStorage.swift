//
//  Storage.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import Foundation

@available(iOS 15.0.0, *)
public class ContentStorage: NSObject {
    
    public static let shared = ContentStorage()
    public var surahs: [String:Surah] = [:]
    var enSurahs: [String:Surah] = [:]
    var ruSurahs: [String:Surah] = [:]
    
    var mushaf: Mushaf?
    var enMushaf: Mushaf?
    var ruMushaf: Mushaf?
    
    override init() {
        super.init()        
    }
    
    public func loadMasahif() async throws {
        do {
            self.mushaf = try await ContentStorage.shared.fetchQuranEdition(edition: "quran-simple-enhanced")
            self.ruMushaf = try await ContentStorage.shared.fetchQuranEdition(edition: "ru.kuliev")
            self.enMushaf = try await ContentStorage.shared.fetchQuranEdition(edition: "en.sahih")
            
            self.enMushaf?.data.surahs.forEach({
                self.enSurahs[$0.id] = $0
            })
            
            self.ruMushaf?.data.surahs.forEach({
                self.ruSurahs[$0.id] = $0
            })
            
            self.mushaf?.data.surahs.forEach({
                var surah = $0
                for i in 0..<surah.ayahs.count {
                    guard let enMeaning = self.enMushaf?.data.surahs[$0.number-1].ayahs[i].text else {
                        break
                    }
                    surah.ayahs[i].enMeaning = enMeaning
                }
                
                self.surahs[$0.id] = surah
            })
            
            
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    //   http://api.alquran.cloud/v1/meta
    //   https://cdn.islamic.network/quran/audio/128/ru.kuliev-audio/28.mp3
    //   https://cdn.islamic.network/quran/audio/192/ar.abdulbasitmurattal/28.mp3
    //   let quranMeta = try? newJSONDecoder().decode(MushafMeta.self, from: jsonData)

    enum FetchError: Error {
        case failedRequestInitialization
        case failedUrlInitialization
        case failedTemporaryUrlInitialization
        case failedToLoadData
    }
    
    @available(iOS 15.0.0, *)
    public func fetchQuranEdition(edition: String) async throws -> Mushaf {
        
        // Compute a path to the URL in the cache
        let filePath = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "mushaf_\(edition)",
                isDirectory: false
            )
        
        
        // If the data exists in the cache,
        // load the data from the cache and exit
        if FileManager.default.fileExists(atPath: filePath.path),
            let data = try? Data(contentsOf: filePath) {
            let quranEdition = try JSONDecoder().decode(Mushaf.self, from: data)
            return quranEdition
        }
        
        guard let urlCustomMethod = URL(string: "https://api.alquran.cloud/v1/quran/\(edition)") else {
            throw FetchError.failedUrlInitialization
        }
        
        let (data, _) = try await URLSession.shared.data(from: urlCustomMethod)
        let mushaf = try JSONDecoder().decode(Mushaf.self, from: data)
        
        // Remove any existing document at file
        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)
        }

        // Cache the file
        FileManager.default.createFile(atPath: filePath.path, contents: data)
        
        return mushaf
        
    }
    
    @available(iOS 15.0.0, *)
    public func fetchMeta() async throws -> MushafMeta {
        
        
        // Compute a path to the URL in the cache
        let filePath = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "quran_meta",
                isDirectory: false
            )
        
        
        // If the data exists in the cache,
        // load the data from the cache and exit
        if FileManager.default.fileExists(atPath: filePath.path),
            let data = try? Data(contentsOf: filePath) {
            let quranMetaData = try JSONDecoder().decode(MushafMeta.self, from: data)
            return quranMetaData
        }
        
        guard let urlCustomMethod = URL(string: "https://api.alquran.cloud/v1/meta") else {
            throw FetchError.failedUrlInitialization
        }
        
        let (data, _) = try await URLSession.shared.data(from: urlCustomMethod)
        let quranMetaData = try JSONDecoder().decode(MushafMeta.self, from: data)
        
        // Remove any existing document at file
        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)
        }

        // Cache the file
        FileManager.default.createFile(atPath: filePath.path, contents: data)
        
        return quranMetaData
        
    }
    
    @available(iOS 15.0.0, *)
    public func loadAyahAudio(ayahNumber: String, bitRate: UInt, editing: String) async throws -> URL {
        // Compute a path to the URL in the cache
        let filePath = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(ayahNumber).mp3",
                isDirectory: false
            )
        
        
        // If the data exists in the cache,
        // load the data from the cache and exit
        if FileManager.default.fileExists(atPath: filePath.path),
           let _ = try? Data(contentsOf: filePath) {
            return filePath
        }
        
        // If the image does not exist in the cache,
        // download the image to the cache
        if let _ = try? await downloadAyahAudio(ayahNumber: ayahNumber, bitRate: bitRate, editing: editing, toFile: filePath) {
            return filePath
        }
        
        throw FetchError.failedToLoadData

    }
    
    @available(iOS 15.0.0, *)
    public func downloadAyahAudio(ayahNumber: String, bitRate: UInt, editing: String, toFile file: URL) async throws -> Data {
        
        /// FIXME: remove forced unwraps
        let url = URL(string: "https://cdn.islamic.network/quran/audio/\(bitRate)/\(editing)/\(ayahNumber).mp3")!
        
        do {
            // Download the remote URL to a file
            let (data, response) = try await URLSession.shared.data(from: url)
            
            print(response)
            
            // Remove any existing document at file
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }

            // Cache the file
            FileManager.default.createFile(atPath: file.path, contents: data)
            
            return data
            
        } catch {
            throw error
        }
        
    }
    
}
