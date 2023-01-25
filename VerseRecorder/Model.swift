//
//  Model.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import Foundation

protocol Groupable {
    var id: String {get}
    var title: String {get}
    var items: [Listable] { get }
}

public protocol Listable {
    var id: String {get}
    var title: String {get}
    var isShown: Int {get}
}

public protocol ContentMolecule {
    var id: String {get}
    var title: String {get}
    var atoms: [ContentAtom] {get}
}

public protocol ContentAtom {
    var id: String {get}
    var text: String {get}
    var meaning: String {get}
    var commentary: String {get}
    var image: String {get}
}


@available(iOS 15.0.0, *)
public struct AudioGroup: Decodable, Groupable, Identifiable {
    
    public let id: String
    let ru, en: String
    
    public var title: String {
        isRussian ? ru : en
    }
    
    public var isShown: Int {
        1
    }
    
    public var items: [Listable] {
        
        guard let items = ContentStorage.shared.audios[id] else {
            return []
        }
        
        return items.filter { item in
            
            item.isShown > 0
            
        }
    }
    
}

@available(iOS 15.0.0, *)
public struct AudioTrack: Codable, Listable, ContentMolecule {
    
    public let id: String
    let en, ru: String
    public let isShown: Int

    public var atoms: [ContentAtom] {
        ContentStorage.shared.audioContents[id] ?? []
    }
    
    public var title: String {
        return isRussian ? ru : en
    }
    
}

public struct AudioAtom: Codable, ContentAtom {
    
    public var text: String {
        uthmani
    }
    
    public var meaning: String {
        isRussian ? ru : en
    }
    
    public var commentary: String {
        return isRussian ? ruTranslit : enTranslit
    }
    
    public var image: String {
        ""
    }
    
    public let id: String
    let index: Int
    let clean, uthmani: String
    let en, ru: String
    let enTranslit, ruTranslit: String
}
