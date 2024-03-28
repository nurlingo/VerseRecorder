//
//  String+.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
extension Font {
    /// get "Open Sans" font or fallbacks to the system font in case the custom font was not registered
    /// - Parameter size: size of font
    /// - Returns: "Open Sans" font (or sytem font as fallback)
    static func uthmanicHafsScript(size: CGFloat) -> Font {
        guard UIFont.familyNames.contains("KFGQPC Uthmanic Script HAFS") else {
            return Font.system(size: size)
        }
        return .custom("KFGQPCUthmanicScriptHAFS", size: size)
    }
    
    static func uthmanicTahaScript(size: CGFloat) -> Font {
        guard UIFont.familyNames.contains("KFGQPC Uthman Taha Naskh") else {
            return Font.system(size: size)
        }
        return .custom("KFGQPCUthmanTahaNaskh", size: size)
    }
    
    
}


extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}


extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}


extension String {
    func localized() -> String {
        
        if isRussian {
            return getRussian()
        } else {
            return getEnglish()
        }
    }
    
    public func getEnglish() -> String {
        let en = [
            "Surahs": "Surahs (Juz 30)",
            "My recordings": "My recordings",
            "Pick a surah to record": "Pick a surah to record",
            "recording": "recording",
            "Upload Audios": "Upload recorded audios?",
            "Upload": "Send recordings to the developer",
            "Upload Explanation": "We'll ask volunteers to check your recitation, and can display the results once they are ready.\n\nImportant: We'll use your audios to train AI and for research. InshaAllah, this will become something beneficial in the future.",
            "Delete Audio": "Delete?",
            "Delete Current": "Delete current",
            "Delete All": "Delete All",
            "Delete Explanation": "Do you want to delete the recording?",
            "correct": "Correct: pronunciation and memorization are acceptable. Please note: we do not assess the tajweed rules.",
            "in_correct": "Incorrect: pronunciation and/or memorization mistakes were identified by the volunteers.",
            "not_related_quran": "Not Quran: the recording has something unrelated.",
            "not_match_aya": "Wrong Ayah: the recording has a different ayah from what it is supposed to be.",
            "multiple_aya": "Multiple Ayahs: the recording has several ayahs instead of one.",
            "in_complete": "Incomplete: the recording is missing a part of the ayah",
            "Feedback explained": "Feedback explaination",
            "Waiting to be checked": "Waiting to be checked",
        ]
        
        return en[self] ?? self
    }
    
    public func getRussian() -> String {
        
        let ru = [
            "Surahs": "Суры (30й джуз)",
            "My recordings": "Мои записи",
            "Pick a surah to record": "Выберите суру для записи",
            "recording": "запись",
            "Upload Audios": "Отправить записанные аудио?",
            "Upload": "Отправить записи разработчику",
            "Upload Explanation": "Правильность вашего чтения проверят волонтеры, и как будет готов результат, отобразим его в этом же разделе иншаАллах.\n\nВажно: мы используем аудиозаписи для обучения ИИ и исследований. ИншаАллах, в этом будет польза для мусульман.",
            "Delete Audio": "Удалить?",
            "Delete Current": "Удалить выбранную",
            "Delete All": "Удалить все",
            "Delete Explanation": "Вы хотите удалить запись?",
            "correct": "Правильное чтение: произношение и запоминание на приемлемом уровне. Соответствие правилам таджвида не проверялось.",
            "in_correct": "Обнаружены ошибки: в произношении и/или запоминании.",
            "not_related_quran": "Не Коран: запись содержит что-то не из Корана.",
            "not_match_aya": "Не тот аят: запись содержит другой аят, а не тот, который должен быть.",
            "multiple_aya": "Несколько аятов: запись содержит несколько аятов вместо одного.",
            "in_complete": "Неполный аят: в записи отсутствует часть аята.",
            "Feedback explained": "Пояснение к записи",
            "Waiting to be checked": "Ждет проверки",
        ]
        
        return ru[self] ?? self
    }
}
