//
//  ListViewModel.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//

import Foundation

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

@available(iOS 13.0, *)
public class FontViewModel: NSObject, ObservableObject {
    
    @Published var fontSize: Float = 30.0 {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "fontSize")
            UserDefaults.standard.synchronize()
        }
    }
    let fontStep: Float = 5.0
    let fontRange: ClosedRange<Float> = 20.00...50.00
    
    public override init() {
        super.init()
        setupFont()
    }
    
    private func setupFont() {
        
        if let fontSize = UserDefaults.standard.object(forKey: "fontSize") as? Float {
            self.fontSize = fontSize
        }
        
        //        for family in UIFont.familyNames.sorted() {
        //            let names = UIFont.fontNames(forFamilyName: family)
        //            print("Family: \(family) Font names: \(names)")
        //        }
        
    }
}    
    
    
