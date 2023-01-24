//
//  Language.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 24.01.2023.
//

import Foundation

enum Language: Int {
    case english = 0
    case russian = 1
}


var globalLanguage: Language {
    
    /// check if language is already set
    if let langIndex = UserDefaults(suiteName: "group.com.nurios.namazapp")?.object(forKey: "language") as? Int {
        return Language(rawValue: langIndex) ?? .english
    }
    
    /// check if language is already set
    if let langIndex = UserDefaults.standard.object(forKey: "language") as? Int {
        return Language(rawValue: langIndex) ?? .english
    }
    
    /// if not set the app language according to the device language
    let langIndex: Int = Locale.current.languageCode == "ru" ? 1 : 0
    return Language(rawValue: langIndex) ?? .english
    
}

var isRussian: Bool {
    globalLanguage == .russian
}
