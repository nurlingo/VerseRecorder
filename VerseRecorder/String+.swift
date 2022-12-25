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
            "Upload Audios": "Upload recorded audios?",
            "Upload": "Send recordings to the developer",
            "Upload Explanation": "Upload recorded audios: We'll use it to train a model that will assess our users' recitation automatically. InshaAllah if this endeavour is successful, we'll all get rewarded by Allah.",
            "Delete Audio": "Delete?",
            "Delete Current": "Delete current",
            "Delete All": "Delete All",
            "Delete Explanation": "Do you want to delete the recording?",
        ]
        
        return en[self] ?? self
    }
    
    public func getRussian() -> String {
        
        let ru = [
            "Upload Audios": "Отправить записанные аудио?",
            "Upload": "Поделиться записями с разработчиком",
            "Upload Explanation": "Мы используем записи для обучения модели искусственного интеллекта, чтобы в будущем уметь оценить правильности чтения автоматически. Если у нас получится внедрить эту модель и она будет полезна людям, то иншаАллаh вы получите награду от Аллаhа за участие в благом деле.",
            "Delete Audio": "Удалить?",
            "Delete Current": "Удалить выбранную",
            "Delete All": "Удалить все",
            "Delete Explanation": "Вы хотите удалить запись?",
        ]
        
        return ru[self] ?? self
    }
}
