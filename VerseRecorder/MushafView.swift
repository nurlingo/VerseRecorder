
//
//  MushafView.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 16.09.2023.
//

import SwiftUI

import AVFoundation
import MediaPlayer

// Define a struct to hold the ayah counts for each surah (you can extend this as needed)
struct QuranData {
    
    static var ayatBySurah: [[String]] = {
        
        let ayahCounts: [Int: Int] = [
            1: 7,
            78: 40,
            79: 46,
            80: 42,
            81: 29,
            82: 19,
            83: 36,
            84: 25,
            85: 22,
            86: 17,
            87: 19,
            88: 26,
            89: 30,
            90: 20,
            91: 15,
            92: 21,
            93: 11,
            94: 8,
            95: 8,
            96: 19,
            97: 5,
            98: 8,
            99: 8,
            100: 11,
            101: 11,
            102: 8,
            103: 3,
            104: 9,
            105: 5,
            106: 4,
            107: 7,
            108: 3,
            109: 6,
            110: 3,
            111: 5,
            112: 4,
            113: 5,
            114: 6
        ]
        
        var nestedAyahNumbers: [[String]] = []

        for surahNumber in ayahCounts.keys.sorted() {
            
            guard let ayahCount = ayahCounts[surahNumber]
            else {
                continue
            }
            
            var surahAyahs: [String] = []
            for ayahNumber in 1...ayahCount {
                let ayah = String(format: "%03d%03d", surahNumber, ayahNumber)
                surahAyahs.append(ayah)
            }
            
            nestedAyahNumbers.append(surahAyahs)
        }
        
        return nestedAyahNumbers
    }()
    
    static var ayatByPage: [[String]] = {
        
        let hafsUthmaniRanges: [Int: [ClosedRange<Int>]] = [
            1: [1000...1007],
            582: [78000...78030],
            583: [78031...78040, 79000...79015],
            584: [7916...79046],
            585: [80000...80042],
            586: [81000...81029],
            587: [82000...82019, 83000...83006],
            588: [83007...83034],
            589: [83035...83036, 84000...84025],
            590: [85000...85022],
            591: [86000...86017, 87000...87015],
            592: [87016...87019, 88000...88026],
            593: [89000...89023],
            594: [89024...89030, 89000...89020],
            595: [91000...91015, 92000...92014],
            596: [92015...92021, 93000...93011,94000...94008],
            597: [95000...95008,96000...96019],
            598: [97000...97005,98000...98007],
            599: [98008...98008, 99000...99008,100000...100009],
            600: [100010...100011,101000...101011,102000...102008],
            601: [103000...103003, 104000...104009, 105000...105005],
            602: [106000...106004,107000...107007, 108000...108003],
            603: [109000...109006,110000...110003,111000...111005],
            604: [112000...112004,113000...113005,114000...114006]
        ]
        
        var nestedAyahNumbers: [[String]] = []

        for pageNumber in pagesToDisplay {
            
            guard let pageRanges = hafsUthmaniRanges[pageNumber]
            else {
                continue
            }
            
            var pageAyahs: [String] = []
            
            for range in pageRanges {
                range.forEach {
                    let ayah = String(format: "%06d", $0)
                    pageAyahs.append(ayah)
                }
            }
            
            
            
            nestedAyahNumbers.append(pageAyahs)
        }
        
        return nestedAyahNumbers
    }()
    
    
    static var pagesToDisplay: [Int] = {
        var pages = Array<Int>()
        pages.append(1)
        for i in 582...604 {
            pages.append(i)
        }
        return pages
    }()
}

@available(iOS 15.0.0, *)
public struct MushafView: View {
    
    @ObservedObject private var mushafVM = MushafViewModel()
    
    public init() {}
    
    public var body: some View {
        
        Text(String(mushafVM.pages[mushafVM.currentPageIndex]))
        
        TabView(selection: $mushafVM.currentPageIndex) {
            ForEach(0..<mushafVM.pages.count, id: \.self) { index in
                Image(String(mushafVM.pages[index]))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//        .environment(\.layoutDirection, .rightToLeft)
        
        MushafPanel(mushafVM: mushafVM)
            .frame(height: 50)
            .onDisappear {
                mushafVM.resetPlayer()
//                mushafVM.resetRecorder()
            }
    }
    
}


@available(iOS 15.0, *)
struct MushafPanel: View {
    
    @StateObject var mushafVM: MushafViewModel
        
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                
                Text(mushafVM.activeItemId.isEmpty ? "Ready to play" : mushafVM.activeItemId)
                
                HStack{
                    
                    Button {
                        mushafVM.handlePreviousButton()
                        print("backward tapped!")
                    } label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 40, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    
                    Button {
                        mushafVM.handleNextButton()
                        print("forward tapped!")
                    } label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 40, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
        
            Spacer()
            
            
            
            
            Button {
                mushafVM.handlePlayButton()
            } label: {
                Image(systemName: mushafVM.isPlaying ? "pause.circle" : "play.circle")
                    .resizable()
                    .scaledToFit()
                    .font(.system(size: 20, weight: .light))
                    .frame(width: 70, height: 70)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }
}


public enum AudioSource: String {
    case userRecording
    case husaryQaloon = "https://www.namaz.live/ar.husary.qaloon"
    case alafasyHafs = "https://cdn.islamic.network/quran/audio/64/ar.alafasy"
    case husaryHafs = "https://cdn.islamic.network/quran/audio/64/ar.husary"
    case abdulbasitHafs = "https://cdn.islamic.network/quran/audio/64/ar.abdulbasitmurattal"
}

@available(iOS 15.0, *)
public class MushafViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    public var pages = QuranData.pagesToDisplay
    public var tracks: [[String]] = QuranData.ayatByPage
    private var audioSource: AudioSource = .alafasyHafs
    
    @Published var currentPageIndex = 0
    @Published var activeItemId: String = ""
    
    @Published var speed: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(speed, forKey: "playSpeed")
            UserDefaults.standard.synchronize()
            
            if let player = player, player.isPlaying {
                
                player.stop()
                player.rate = speed
                player.prepareToPlay()
                player.play()
            }
        }
    }
    let step: Float = 0.25
    let range: ClosedRange<Float> = 1.00...2.00
        
    @Published var isPlaying: Bool = false
    @Published var isRepeatOn: Bool = false
    @Published var isShowingText = false
        
    public var activeItemIndex: Int {
        if let index = tracks[currentPageIndex].firstIndex(of: activeItemId) {
            return index
        } else {
            return -1
        }
    }
 
    private var player: AVAudioPlayer?
    private var updater : CADisplayLink! = nil
    private var runCount: Double = 0

    
    enum ProgressMode {
        case rowBased
        case durationBased
    }
    
    public func setAudioSource(_ source: AudioSource) {
        self.audioSource = source
    }
    
    public func handlePlayButton() {
        if let player = player,
            player.isPlaying {
            /// pause the player
            pausePlayer()
            return
        }
        
        
        self.play(itemId: activeItemId)
        isPlaying = true
        
    }
    
    public func handleNextButton() {
        goToNextItem()
    }
    
    public func handlePreviousButton() {
        goToPreviousItem()
    }
    
    public func resetPlayer() {
        activeItemId = ""
        player?.stop()
        player = nil
    }

    
    override public init() {
        super.init()
        setupPlayer()
        registerForInterruptions()
    }
    
    deinit {
        resetPlayer()
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        updater = nil
    }
    
    private func play(from source: AudioSource = .husaryHafs, itemId: String) {
        
        if itemId.isEmpty, let first = tracks[currentPageIndex].first  {
            activeItemId = first
        } else {
            activeItemId = itemId
        }

        /// detect if it's basmala that needs to be played
        let itemToPlay: String
        let pattern = ".*[^1]000$"
        let regex = try! NSRegularExpression(pattern: pattern)

        if let _ = regex.firstMatch(in: activeItemId, range: NSRange(activeItemId.startIndex..., in: activeItemId)) {
            itemToPlay = "001001"
        } else {
            itemToPlay = activeItemId
        }
        
        Task {
            do {
                
                if let path = Bundle.main.path(forResource: itemToPlay, ofType: "mp3") {
                    
                    let defaultAudioURL = URL(fileURLWithPath: path)
                    player = try AVAudioPlayer(contentsOf: defaultAudioURL)

                } else if doesAudioExist(for: source, trackId: itemToPlay) {
                    let locallyStoredUrl = getPath(for: source, trackId: itemToPlay)
                    player = try AVAudioPlayer(contentsOf: locallyStoredUrl)
                } else if let surahNumber = Int(itemToPlay.prefix(3)),
                          let ayahNumber = Int(itemToPlay.suffix(3)) {
                    
                    
                    let surah = try await fetchSurah(surahNumber: surahNumber)
                    if let ayah = surah.ayahs.first(where: {$0.numberInSurah == ayahNumber}) {
                        let remoteUrl = URL(string: "\(source.rawValue)/\(ayah.number).mp3")!
                        let localAudioURL = getPath(for: source, trackId: "\(ayah.number)")
                        print(localAudioURL.path)
                        try await downloadAudio(from: remoteUrl, to: localAudioURL)
                        player = try AVAudioPlayer(contentsOf: localAudioURL)
                    } else {
                        player = nil
                    }
                    
                } else {
                    player = nil
                }
                
                DispatchQueue.main.async {
                    self.player?.delegate = self
                    self.player?.prepareToPlay()
                    self.player?.play()
                }
                
                
            } catch let error as NSError {
                print(#function, error.description)
            }
        }
                
        
        
        
        
    }
    
    private func pausePlayer() {
        isPlaying = false
        self.player?.pause()
    }
    
    private func stopPlayer() {
        isPlaying = false
        self.player?.stop()
    }
    
    private func goToNextItem(){
        if activeItemIndex < 0 {
            activeItemId = tracks[currentPageIndex].first ?? ""
            play(itemId: activeItemId)
        } else if activeItemIndex < tracks[currentPageIndex].count - 1 { /// moreItemsAhead
            self.activeItemId = tracks[currentPageIndex][activeItemIndex+1]
            if isPlaying {
                play(itemId:activeItemId)
            }
        } else if isPlaying && isRepeatOn { // repeat the same page
            self.activeItemId = tracks[currentPageIndex].first ?? ""
        } else if currentPageIndex < tracks.count - 1 { // go to next page
            self.currentPageIndex += 1
            self.activeItemId = tracks[currentPageIndex].first ?? ""
            if isPlaying {
                play(itemId:activeItemId)
            }
        } else { // we reached the end, go to fatiha and stop playing
            self.currentPageIndex = 0
            self.activeItemId = ""
            stopPlayer()
            player = nil
        }
    }
    
    
    private func goToPreviousItem() {
        
        if activeItemIndex <= 0 { // either first ayah on the page or no active ayah
            currentPageIndex = currentPageIndex > 0 ? currentPageIndex - 1 : pages.count - 1 // go to previous page
            activeItemId = tracks[currentPageIndex].last ?? ""
            if isPlaying {
                play(itemId: activeItemId)
            }
        } else { // we reached the end, go to fatiha and stop playing
            activeItemId = tracks[currentPageIndex][activeItemIndex-1]
            if isPlaying {
                play(itemId: activeItemId)
            }
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        goToNextItem()
    }
    
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func doesAudioExist(for source: AudioSource, trackId: String, fileExtension: String = "mp3") -> Bool {
        let path = getDocumentsDirectory().appendingPathComponent("\(source)-\(trackId).\(fileExtension)").path
        return FileManager.default.fileExists(atPath: path)
    }
    
    func getPath(for source: AudioSource, trackId: String, fileExtension: String = "mp3") -> URL {
        return getDocumentsDirectory().appendingPathComponent("\(source)-\(trackId).\(fileExtension)")
    }

    func downloadAudio(from remoteUrl: URL, to localStorageUrl: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: remoteUrl)
        try data.write(to: localStorageUrl)
        print("Audio data saved to: \(localStorageUrl.path)")

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

@available(iOS 15.0, *)
extension MushafViewModel {
    
    private func setupPlayer() {
        if let actualSpeedValue = UserDefaults.standard.object(forKey: "playSpeed") as? Float {
            self.speed = actualSpeedValue
        }
        
        do {
            AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playAndRecord)
        } catch let error as NSError {
            print(#function, error.description)
        }
        
    }
    
    private func registerForInterruptions() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(handleInterruption),
                                       name: AVAudioSession.interruptionNotification,
                                       object: nil)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        // put the player to pause in case of an interruption (e.g. incoming phone call)
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            pausePlayer()
        }
        
    }
}


//if !mushafVM.isRecording,
//   mushafVM.recordingExists(mushafVM.activeItemId) {
//    Button {
//        mushafVM.handlePlayButton()
//    } label: {
//
//        Image(systemName: mushafVM.isPlaying ? "stop.circle" : "play.circle")
//            .resizable()
//            .scaledToFit()
//            .font(.system(size: 16, weight: .light))
//            .frame(width: 45, height: 45)
//    }
//    .buttonStyle(PlainButtonStyle())
//} else {
//
//    Button {
//        mushafVM.handleRecordButton()
//    } label: {
//        Image(systemName: mushafVM.isRecording ? "stop.circle.fill" : "mic.circle.fill")
//            .resizable()
//            .scaledToFit()
//            .font(.system(size: 16, weight: .light))
//            .frame(width: 45, height: 45)
//    }
//    .buttonStyle(PlainButtonStyle())
//}

//
//
//public var clientStorage: ClientStorage
//
//lazy var recordingStorage: RecordingStorage = RecordingStorage.shared
//lazy var uploader: UploaderService = UploaderService(credentials: credentials, clientStorage: clientStorage)
//@Published var isRecording: Bool = false
//
//var isWaitingForUpload: Bool {
//    for track in tracks.flatMap({$0}) {
//        if recordingExists(track) && !recordingUploaded(track) {
//            return true
//        }
//    }
//
//    return false
//}
//
//private var audioRecorder: AVAudioRecorder?
//
//private func playRecording(_ trackId: String) {
//
//    let url = recordingStorage.getPath(for: trackId)
//
//    player = nil
//
//    do {
//        player = try AVAudioPlayer(contentsOf: url)
//        guard let player = player else { return }
//        player.delegate = self
//        player.enableRate = true
//
//        /// if output volume is ON, limit playspeed to 1.75 (specific to namazapp)
//        let isVolumeOn = AVAudioSession.sharedInstance().outputVolume > 0
//        player.rate = isVolumeOn ? min(speed, 1.75) : speed
//
//
//        player.prepareToPlay()
//        player.play()
//        DispatchQueue.main.async {
//            self.isPlaying = true
//        }
//    } catch let error as NSError {
//        print(#file, #function, #line, #column, error.description)
//    }
//
//}
//
//

//public func handleNextButton() {
//
//    if isRecording {
//        recordNextItem()
//    } else if isPlaying {
//        playNextItem()
//    } else if currentlyActiveIndex < tracks.flatMap({$0}).count - 1 { /// moreItemsAhead
//        self.activeItemId = tracks.flatMap({$0})[currentlyActiveIndex+1]
//    } else {
//        self.activeItemId = tracks.flatMap({$0}).first ?? ""
//    }
//}
//
//public func handlePreviousButton() {
//
//    if isRecording {
//        recordPreviousItem()
//    } else if isPlaying {
//        playPreviousItem()
//    } else if currentlyActiveIndex > 0 {
//        self.activeItemId = tracks.flatMap({$0})[currentlyActiveIndex-1]
//    }
//
//}

//public func handleRecordButton() {
//    if isRecording {
//        finishRecording()
//        activeItemId = "" //FIXME: what should it be?
//    } else {
//        stopPlayer()
//        startRecording()
//    }
//}
//
//public func handleUploadButton() {
//    if isRecording {
//        finishRecording()
//    }
//
//    if isPlaying {
//        pausePlayer()
//    }
//
//    uploader.uploadNewlyRecordedAudios(tracks.flatMap({$0}))
//    var count = tracks.count + 3
//    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
//        count -= 1
//        self.activeItemId = self.activeItemId
//        if count <= 0 {
//            timer.invalidate()
//        }
//    }
//}
//
//public func recordingExists(_ trackId: String) -> Bool {
//    recordingStorage.doesRecordingExist(trackId)
//}
//
//public func recordingUploaded(_ trackId: String) -> Bool {
//    recordingStorage.didUploadRecording(trackId)
//}
//
//
//
//public func resetRecorder() {
//    audioRecorder?.stop()
//    audioRecorder = nil
//    isRecording = false
//}
//
//private func startRecording() {
//
//    if activeItemId.isEmpty, let first = tracks.flatMap({$0}).first  {
//        activeItemId = first
//    }
//
//    stopPlayer()
//
//    let audioFilename = recordingStorage.getPath(for: activeItemId)
//
//    let settings = [
//        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//        AVSampleRateKey: 16000,
//        AVNumberOfChannelsKey: 1,
//        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//    ]
//
//    do {
//        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
//        audioRecorder?.delegate = self
//        audioRecorder?.record()
//
//        print("recorded audio:", audioFilename)
//        isRecording = true
//    } catch {
//        print(#file, #function, #line, #column, "recording failed:", error.localizedDescription)
//    }
//}
//
//private func finishRecording() {
//    recordingStorage.registerRecordingDate(activeItemId)
//    saveRecordingProgress()
//    resetRecorder()
//}
//
//private func saveRecordingProgress() {
//    var recorded = 0
//    for track in tracks.flatMap({$0}) {
//        if recordingStorage.doesRecordingExist(track) {
//            recorded += 1
//        }
//    }
//    clientStorage.saveRecordProgress(audioId, progress: Double(recorded)/Double(tracks.count))
//}
//
//private func recordNextItem(){
//    finishRecording()
//
//    if currentlyActiveIndex < tracks.count - 1 {
//        /// moreItemsAhead
//        self.activeItemId = tracks.flatMap({$0})[currentlyActiveIndex+1]
//        startRecording()
//    } else {
//        activeItemId = tracks.flatMap({$0}).first ?? ""
//    }
//}
//
//
//private func recordPreviousItem() {
//
//    finishRecording()
//
//    if currentlyActiveIndex > 0 {
//        activeItemId = tracks.flatMap({$0})[currentlyActiveIndex-1]
//        startRecording()
//    }
//}
