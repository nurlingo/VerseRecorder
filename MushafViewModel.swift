//
//  MushafViewModel.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 26.11.2023.
//
import SwiftUI
import AVFoundation

@available(iOS 15.0, *)
public class MushafViewModel: PrayerViewModel {
    
    public var mushafPublication: MushafPublication = .qaloonMadinan
    private var audioSource: AudioSource = .alafasyHafs
    
    @Published var showNavigation = false
    
    @Published var currentSurahIndex: Int =  UserDefaults.standard.integer(forKey: "currentSurahIndex"){
        didSet {
            if navigation == .surah {
                currentRange = surahAyahs[SurahNames.juzAmma.keys.sorted()[currentSurahIndex]] ?? []
                
                /// check that the page actually needs to change to avoid circular calls
                
                let surahPageNumbers = Array(Set(currentRange.map{ $0.pageNumber })).sorted()
                
                if !surahPageNumbers.contains(pages[currentPageIndex]),
                   let pageNumber = currentRange.first?.pageNumber,
                   let pageIndex = pages.firstIndex(where: {$0 == pageNumber}){
                    currentPageIndex = pageIndex
                }
                
            }
            UserDefaults.standard.set(currentSurahIndex, forKey: "currentSurahIndex")
        }
    }
    
    @Published var currentPageIndex: Int = UserDefaults.standard.integer(forKey: "currentPageIndex") {
        didSet {
            if navigation == .surah {
                /// if the current surah is not present on the new page
                /// then put the first surah on that page as the current
                if !currentRange.contains(where: { $0.pageNumber == pages[currentPageIndex] } ) {
                    
                    let pageNumber = pages[currentPageIndex]
                    
                    if let beginningOfSurahOnThePage = pageAyahs[pageNumber]?.first(where: { $0.ayahNumber == 0 }) {
                        let surahNumbers = SurahNames.juzAmma.keys.sorted()
                        if let surahIndex = surahNumbers.firstIndex(where: {$0 == beginningOfSurahOnThePage.surahNumber}),
                           currentSurahIndex != surahIndex {
                            currentSurahIndex = surahIndex
                        }
                    } else if let firstAyahOnThePage = pageAyahs[pageNumber]?.first {
                        let surahNumbers = SurahNames.juzAmma.keys.sorted()
                        if let surahIndex = surahNumbers.firstIndex(where: {$0 == firstAyahOnThePage.surahNumber}),
                           currentSurahIndex != surahIndex {
                            currentSurahIndex = surahIndex
                        }
                    }
                }
                
                setRectanglesForCurrentRange()
                
            } else {
                currentRange = pageAyahs[pages[currentPageIndex]] ?? []
            }
            
            UserDefaults.standard.set(currentPageIndex, forKey: "currentPageIndex")
        }
    }
    
    
    @Published var ayahRectangles: [RectangleData] = []
    @Published var isHidden = false {
        didSet {
            setRectanglesForCurrentRange()
        }
    }
    
    @Published var rangeString = ""
    
    @Published var activeAyah: AyahPart? = nil
    
    @Published var currentRange = [AyahPart]() {
        didSet {
            print(currentRange.map({$0.id}))
            UserDefaults.standard.set(currentRange.map({$0.id}), forKey: "currentRangeIds")
            UserDefaults.standard.synchronize()
            
            if isPlaying {
                pausePlayer()
                setRectanglesForCurrentAyah()
            } else {
                setRectanglesForCurrentRange()
            }
            
            if !currentRange.isEmpty,
               let first = currentRange.first,
               let last = currentRange.last,
               let firstSurahName = SurahNames.juzAmma[first.surahNumber]?.1,
               let lastSurahName = SurahNames.juzAmma[last.surahNumber]?.1 {
                activeAyah = currentRange[0]
                
                rangeString = firstSurahName == lastSurahName ? "\(first.surahNumber). \(firstSurahName) \(first.ayahNumber):\(last.ayahNumber)" : "\(first.surahNumber). \(firstSurahName) \(first.ayahNumber) : \(last.surahNumber). \(lastSurahName) \(last.ayahNumber)"
            }
        }
    }
    
    enum NavigationMode: String {
        case page
        case surah
    }
    
    private var navigation: NavigationMode = .surah
    
    lazy var surahAyahs: [Int:[AyahPart]] = {
        var dict = [Int:[AyahPart]]()
        SurahNames.juzAmma.keys.forEach { surahNumber in
            dict[surahNumber] = ayahs.filter({ $0.surahNumber == surahNumber})
        }
        return dict
    }()
    
    lazy var pageAyahs: [Int:[AyahPart]] = {
        var dict = [Int:[AyahPart]]()
        pages.forEach { pageNumber in
            dict[pageNumber] = ayahs.filter({ $0.pageNumber == pageNumber})
        }
        return dict
    }()
    
    lazy var pages: [Int] = {
        let array = ayahs.map({$0.pageNumber})
        let set = Set(array)
        let unique = Array(set)
        return unique.sorted()
    }()
    
    var currentRangePages: [Int] {
        Array(Set(currentRange.map( {$0.pageNumber} ))).sorted()
    }
    
    public var activeItemIndex: Int {
        if let activeAyah = self.activeAyah,
           let index = currentRange.firstIndex(where: {$0.id == activeAyah.id}) {
            return index
        } else {
            return -1
        }
    }
    
    public func setAudioSource(_ source: AudioSource) {
        self.audioSource = source
    }
    
    public func handleNextRangeButton() {
        self.pausePlayer()
        self.navigation = .surah
        goToNextRange()
    }
    
    public func handlePreviousRangeButton() {
        self.pausePlayer()
        self.navigation = .surah
        goToPreviousRange()
    }
    
    override public init(ayahs: [AyahPart]) {
        super.init(ayahs: ayahs)
        if let currentRangeIds: [String] = UserDefaults.standard.stringArray(forKey: "currentRangeIds")  {
            self.currentRange = ayahs.filter({ currentRangeIds.contains($0.id) })
        } else {
            self.currentRange = pageAyahs[pages[currentPageIndex]] ?? []
        }
        
        self.standardMessage = "Husary (Qaloon)"
    }
    
    var source: AudioSource = .husaryHafs
    
    override public func playActiveItem() {
        
        if activeAyah == nil {
            activeAyah = currentRange.first
        }
        
        guard let activeAyah = activeAyah else {return}
        
        let currentPageNumber = pages[currentPageIndex]
        if activeAyah.pageNumber != currentPageNumber,
           let pageIndex = pages.firstIndex(where: {$0 == activeAyah.pageNumber}) {
            currentPageIndex = pageIndex
        }
        
        
        self.isPlaying = true
        self.isHidden = false
                
        if mushafPublication == MushafPublication.hafsMadinan {
            /// detect if it's basmala that needs to be played
            let pattern = ".*[^1]000$"
            let regex = try! NSRegularExpression(pattern: pattern)
            
            if let _ = regex.firstMatch(in: activeAyah.id, range: NSRange(activeAyah.id.startIndex..., in: activeAyah.id)) {
                activeItemId = "001000"
            } else {
                activeItemId = activeAyah.id
            }
        } else {
            activeItemId = activeAyah.id
        }
        
        setRectanglesForCurrentAyah()
        
        Task {
            do {
                
                if let path = Bundle.main.path(forResource: activeItemId, ofType: "mp3") {
                    
                    let defaultAudioURL = URL(fileURLWithPath: path)
                    PrayerViewModel.player = try AVAudioPlayer(contentsOf: defaultAudioURL)
                    
                } else if doesAudioExist(for: source, trackId: activeItemId) {
                    let locallyStoredUrl = getPath(for: source, trackId: activeItemId)
                    PrayerViewModel.player = try AVAudioPlayer(contentsOf: locallyStoredUrl)
                } else if source == .husaryQaloon {
                    
                    let remoteUrl = URL(string: "\(source.rawValue)/\(activeItemId).mp3")!
                    let localAudioURL = getPath(for: source, trackId: activeItemId)
                    print(localAudioURL.path)
                    try await downloadAudio(from: remoteUrl, to: localAudioURL)
                    PrayerViewModel.player = try AVAudioPlayer(contentsOf: localAudioURL)
                    
                } else if let surahNumber = Int(activeItemId.prefix(3)),
                          let ayahNumber = Int(activeItemId.suffix(3)) {
                    let surah = try await fetchSurah(surahNumber: surahNumber)
                    if let ayah = surah.ayahs.first(where: {$0.numberInSurah == ayahNumber}) {
                        let remoteUrl = URL(string: "\(source.rawValue)/\(ayah.number).mp3")!
                        
                        let localAudioURL = getPath(for: source, trackId: activeItemId)
                        print(localAudioURL.path)
                        try await downloadAudio(from: remoteUrl, to: localAudioURL)
                        PrayerViewModel.player = try AVAudioPlayer(contentsOf: localAudioURL)
                    } else {
                        PrayerViewModel.player = nil
                    }
                    
                } else {
                    PrayerViewModel.player = nil
                }
                
                DispatchQueue.main.async {
                    PrayerViewModel.player?.delegate = self
                    PrayerViewModel.player?.enableRate = true
                    PrayerViewModel.player?.rate = self.speed
                    PrayerViewModel.player?.prepareToPlay()
                    PrayerViewModel.player?.play()
                    self.setupNowPlaying()
                }
                
            } catch let error as NSError {
                print(#function, error.description)
            }
        }
        
    }
    
    func setRectanglesForCurrentRange() {
        self.ayahRectangles = []
        
        let lines = currentRange.filter( { $0.pageNumber == pages[currentPageIndex] } ).flatMap( {$0.lines })
        extractRectanges(from: lines)
        
    }
    
    func setRectanglesForCurrentAyah() {
        self.ayahRectangles = []
        
        if let activeAyah = activeAyah {
            extractRectanges(from: activeAyah.lines)
        }
    }
    
    private func extractRectanges(from lines: [[WordCoordinate]]) {
        for line in lines {
            
            if let lastPoint = line.last,
               let firstPoint = line.first {
                let x = lastPoint.x
                let y = min(firstPoint.y1,firstPoint.y2)
                let height = abs(firstPoint.y1 - firstPoint.y2)
                let width = abs(firstPoint.x-lastPoint.x)
                ayahRectangles.append(RectangleData(rect:CGRect(x: x, y: y, width: width, height: height)))
            }
        }
    }
    
    private func goToNextRange(){
        if let lastPageInCurrenRange = currentRangePages.last,
           lastPageInCurrenRange > pages[currentPageIndex] {
            currentPageIndex += 1
        } else if currentSurahIndex < SurahNames.juzAmma.keys.count - 1 {
            self.currentSurahIndex += 1
        } else {
            self.currentSurahIndex = SurahNames.juzAmma.keys.count - 1
        }
    }
    
    private func goToPreviousRange() {
        
        if let firstPageInCurrenRange = currentRangePages.first,
           firstPageInCurrenRange < pages[currentPageIndex] {
            currentPageIndex -= 1
        } else if currentSurahIndex <= 0 {
            currentSurahIndex = 0
        } else if currentSurahIndex <= SurahNames.juzAmma.keys.count - 1 {
            self.currentSurahIndex -= 1
        }
    }
    
    public override func goToNextItem(){
        
        if activeItemIndex < 0 {
            /// player is inactive
            /// start from the first ayah in the current range
            activeAyah = currentRange.first
            playActiveItem()
        } else if activeItemIndex < currentRange.count - 1 {
            /// more items ahead in the current range
            /// keep playing
            self.activeAyah = currentRange[activeItemIndex+1]
            playActiveItem()
        } else if isRepeatOn {
            /// repeat is on and we finished playing the range
            /// play the same range from start
            self.activeAyah = currentRange.first
            playActiveItem()
        } else if navigation == .page && currentPageIndex < pages.count - 1 {
            /// range is done playing and repeat is off
            /// go to next range
            self.currentPageIndex += 1
            playActiveItem()
        } else if navigation == .surah && currentSurahIndex < SurahNames.juzAmma.keys.count - 1 {
            /// range is done playing and repeat is off
            /// go to next range
            self.currentSurahIndex += 1
            playActiveItem()
        } else {
            /// we reached the end
            /// stop playing
            self.activeAyah = nil
            stopPlayer()
            PrayerViewModel.player = nil
        }
    }
    
    
    public override func goToPreviousItem() {
        
        if activeItemIndex <= 0 { // either first ayah on the page or no active ayah
            activeAyah = currentRange.first // go to previous page
            playActiveItem()
        } else { // we reached the end, go to fatiha and stop playing
            activeAyah = currentRange[activeItemIndex-1]
            playActiveItem()
        }
    }
    
    func fetchSurah(surahNumber: Int) async throws -> Surah {
        let url = URL(string: "https://api.alquran.cloud/v1/surah/\(surahNumber)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(SurahData.self, from: data).data
        } catch {
            throw error
        }
    }
    
}


