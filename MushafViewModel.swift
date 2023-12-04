//
//  MushafViewModel.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 26.11.2023.
//

import SwiftUI
import AVFoundation
import MediaPlayer


public enum AudioSource: String {
    case recording
    case husaryQaloon = "https://nurlingo.github.io/qaloon/ar.husary"
    case alafasyHafs = "https://cdn.islamic.network/quran/audio/64/ar.alafasy"
    case husaryHafs = "https://cdn.islamic.network/quran/audio/64/ar.husary"
    case abdulbasitHafs = "https://cdn.islamic.network/quran/audio/64/ar.abdulbasitmurattal"
}

@available(iOS 15.0, *)
public class MushafViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    public var mushafPublication: MushafPublication = .qaloonMadinan
    private let ayahs: [AyahPart]
    private var audioSource: AudioSource = .alafasyHafs
    private var audioRecorder: AVAudioRecorder?
    
    private let speedDict: [Float:Float] = [
        1.0:1.25,
        1.25:1.5,
        1.5:1.75,
        1.75:2.0,
        2.0:1.0
    ]
    
    enum NavigationMode: String {
        case page
        case surah
    }
    
    var navigation: NavigationMode = .page
        
    lazy var pages: [Int] = {
        let array = ayahs.map({$0.pageNumber})
        let set = Set(array)
        let unique = Array(set)
        return unique.sorted()
    }()
    
    @Published var speed: Float = UserDefaults.standard.float(forKey: "playSpeed") {
        didSet {
            UserDefaults.standard.set(speed, forKey: "playSpeed")
            UserDefaults.standard.synchronize()
            
            if let player = player, player.isPlaying {
                player.stop()
                player.enableRate = true
                player.rate = speed
                player.prepareToPlay()
                player.play()
            }
        }
    }
    
    @Published var isRangeHighlighted: Bool = UserDefaults.standard.bool(forKey: "isRangeHighlighted") {
        didSet {
            UserDefaults.standard.set(isRangeHighlighted, forKey: "isRangeHighlighted")
            if isRangeHighlighted || isHidden {
                setRectanglesForCurrentRange()
            } else {
                ayahRectangles = []
            }
        }
    }
    
    @Published var currentPage: Int = UserDefaults.standard.integer(forKey: "currentPage") {
        didSet {
            currentRange = ayahs.filter({ $0.pageNumber == pages[currentPage]})
            UserDefaults.standard.set(currentPage, forKey: "currentPage")
        }
    }

    @Published var isPlaying: Bool = false
    @Published var ayahRectangles: [RectangleData] = []
    @Published var isHidden = false {
        didSet {
            if isRangeHighlighted || isHidden {
                setRectanglesForCurrentRange()
            } else {
                ayahRectangles = []
            }
        }
    }
    @Published var infoMessage = "Ready to play"
    @Published var activeRecording: Recording?
    @Published var isRecording: Bool = false
    @Published var isRepeatOn: Bool = false
    @Published var isShowingText = false
    
    
    @Published var currentRange = [AyahPart]() {
        didSet {
            print(currentRange.map({$0.id}))
            UserDefaults.standard.set(currentRange.map({$0.id}), forKey: "currentRangeIds")
            UserDefaults.standard.synchronize()
            
            if isPlaying {
                pausePlayer()
                setRectanglesForCurrentAyah()
            } else if isRangeHighlighted || isHidden {
                setRectanglesForCurrentRange()
            } else {
                ayahRectangles = []
            }
            
            if !currentRange.isEmpty,
                let first = currentRange.first,
                let last = currentRange.last,
                let firstSurahName = SurahNames.juzAmma[first.surahNumber]?.1,
                let lastSurahName = SurahNames.juzAmma[last.surahNumber]?.1 {
                activeAyah = currentRange[0]

                infoMessage = firstSurahName == lastSurahName ? "\(firstSurahName) \(first.ayahNumber) : \(last.ayahNumber)" : "\(firstSurahName) \(first.ayahNumber) : \(lastSurahName) \(last.ayahNumber)"
            }
        }
        
        
    }
    
    @Published var activeAyah: AyahPart? = nil
    
    public var activeItemIndex: Int {
        if let activeAyah = self.activeAyah,
           let index = currentRange.firstIndex(where: {$0.id == activeAyah.id}) {
            return index
        } else {
            return -1
        }
    }
    
    private var player: AVAudioPlayer?
    private var updater : CADisplayLink! = nil
    private var runCount: Double = 0
    
    lazy var recordingStorage: RecordingStorage = RecordingStorage.shared
    lazy var uploader: UploaderService = UploaderService(credentials: credentials)
    
    enum ProgressMode {
        case rowBased
        case durationBased
    }
    
    public func setAudioSource(_ source: AudioSource) {
        self.audioSource = source
    }
    
    public func handleRepeatButton() {
        isRepeatOn.toggle()
        
//        infoMessage = isRepeatOn ? "Repeat page is enabled" : "Repeat page is disabled"
    }
    
    public func handlePlayRecordingButton() {
        if let player = player,
           player.isPlaying {
            /// pause the player
            pausePlayer()
            return
        }
        
        self.playRecording(activeRecording?.uid.uuidString ?? "")
    }
    
    public func handlePlayButton() {
        if let player = player,
           player.isPlaying {
            /// pause the player
            pausePlayer()
            return
        }
        
        self.play()
    }
    
    public func handleNextButton() {
        goToNextItem()
    }
    
    public func handlePreviousButton() {
        goToPreviousItem()
    }
    
    public func handleSpeedButton() {
        speed = speedDict[speed] ?? 1.0
//        infoMessage = "Speed set to \(speed)x"
    }
    
    public func resetPlayer() {
        activeAyah = nil
        player?.stop()
        player = nil
    }
    
    
    public init(ayahs: [AyahPart]) {
        self.ayahs = ayahs
        super.init()
        if let currentRangeIds: [String] = UserDefaults.standard.stringArray(forKey: "currentRangeIds")  {
            self.currentRange = ayahs.filter({ currentRangeIds.contains($0.id) })
        } else {
            self.currentRange = ayahs.filter({ $0.pageNumber == pages[currentPage] })
        }
        setupPlayer()
        setupRemoteTransportControls()
        registerForInterruptions()
    }
    
    deinit {
        resetPlayer()
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        updater = nil
    }
    
    private func play(from source: AudioSource = .husaryHafs) {
        
        if activeAyah == nil {
            activeAyah = currentRange.first
        }
        
        guard let activeAyah = activeAyah else {return}
        
        self.isPlaying = true
        
        let itemToPlay: String
        
        if mushafPublication == MushafPublication.hafsMadinan {
            /// detect if it's basmala that needs to be played
            let pattern = ".*[^1]000$"
            let regex = try! NSRegularExpression(pattern: pattern)
            
            if let _ = regex.firstMatch(in: activeAyah.id, range: NSRange(activeAyah.id.startIndex..., in: activeAyah.id)) {
                itemToPlay = "001000"
            } else {
                itemToPlay = activeAyah.id
            }
        } else {
            itemToPlay = activeAyah.id
        }
        
        setRectanglesForCurrentAyah()
        
        Task {
            do {
                
                if let path = Bundle.main.path(forResource: itemToPlay, ofType: "mp3") {
                    
                    let defaultAudioURL = URL(fileURLWithPath: path)
                    player = try AVAudioPlayer(contentsOf: defaultAudioURL)
                    
                } else if doesAudioExist(for: source, trackId: itemToPlay) {
                    let locallyStoredUrl = getPath(for: source, trackId: itemToPlay)
                    player = try AVAudioPlayer(contentsOf: locallyStoredUrl)
                } else if source == .husaryQaloon {
                    
                    let remoteUrl = URL(string: "\(source.rawValue)/\(itemToPlay).mp3")!
                    let localAudioURL = getPath(for: source, trackId: itemToPlay)
                    print(localAudioURL.path)
                    try await downloadAudio(from: remoteUrl, to: localAudioURL)
                    player = try AVAudioPlayer(contentsOf: localAudioURL)
                    
                } else if let surahNumber = Int(itemToPlay.prefix(3)),
                          let ayahNumber = Int(itemToPlay.suffix(3)) {
                    let surah = try await fetchSurah(surahNumber: surahNumber)
                    if let ayah = surah.ayahs.first(where: {$0.numberInSurah == ayahNumber}) {
                        let remoteUrl = URL(string: "\(source.rawValue)/\(ayah.number).mp3")!
                        
                        let localAudioURL = getPath(for: source, trackId: itemToPlay)
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
                    self.player?.enableRate = true
                    self.player?.rate = self.speed
                    self.player?.prepareToPlay()
                    self.player?.play()
                    self.setupNowPlaying()
                }
                
                
            } catch let error as NSError {
                print(#function, error.description)
            }
        }
        
    }
    
    func setRectanglesForCurrentRange() {
        self.ayahRectangles = []

        let lines = currentRange.flatMap( {$0.lines })
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
    
    private func pausePlayer() {
        updateNowPlaying()
        self.player?.pause()
        self.isPlaying = false
    }
    
    private func stopPlayer() {
        updateNowPlaying()
        self.player?.stop()
        self.isPlaying = false
    }
    
    private func goToNextItem(){
        
        if activeItemIndex < 0 {
            /// player is inactive
            /// start from the first ayah in the current range
            activeAyah = currentRange.first
            play()
        } else if activeItemIndex < currentRange.count - 1 {
            /// more items ahead in the current range
            /// keep playing
            self.activeAyah = currentRange[activeItemIndex+1]
            play()
        } else if isRepeatOn {
            /// repeat is on and we finished playing the range
            /// play the same range from start
            self.activeAyah = currentRange.first
            play()
        } else if currentPage < pages.count - 1 {
            /// range is done playing and repeat is off
            /// go to next range
            self.currentPage += 1
            play()
        } else {
            /// we reached the end
            /// stop playing
            self.activeAyah = nil
            stopPlayer()
            player = nil
        }
    }
    
    
    private func goToPreviousItem() {
        
        if activeItemIndex <= 0 { // either first ayah on the page or no active ayah
            activeAyah = currentRange.first // go to previous page
            play()
        } else { // we reached the end, go to fatiha and stop playing
            activeAyah = currentRange[activeItemIndex-1]
            play()
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlaying = false
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
    
    private func playRecording(_ recordingId: String) {
        
        let url = recordingStorage.getPath(for: recordingId)
        
        player = nil
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.delegate = self
            player.enableRate = true
            
            /// if output volume is ON, limit playspeed to 1.75 (specific to namazapp)
            let isVolumeOn = AVAudioSession.sharedInstance().outputVolume > 0
            player.rate = isVolumeOn ? min(speed, 1.75) : speed
            
            
            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(#file, #function, #line, #column, error.description)
        }
        
    }
    
    public func handleRecordButton() {
        if isRecording {
            resetRecorder()
            if let activeRecording = activeRecording {
                print(activeRecording.date)
                //                uploader.upload(activeRecording)
            }
        } else {
            stopPlayer()
            startRecording()
        }
    }
    
    public func recordingExists(_ recordingId: String) -> Bool {
        recordingStorage.recordingExists(recordingId)
    }
    
    public func resetRecorder() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func startRecording() {
        
        stopPlayer()
        
        guard let first = currentRange.first?.id,
              let last = currentRange.last?.id else {
            return
        }
        
        activeRecording = Recording(first: first, last: last)
        recordingStorage.addRecording(activeRecording!)
        let audioFilename = recordingStorage.getPath(for: activeRecording!.uid.uuidString)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            print("recorded audio:", audioFilename)
            isRecording = true
        } catch {
            print(#file, #function, #line, #column, "recording failed:", error.localizedDescription)
        }
    }
}

@available(iOS 15.0, *)
extension MushafViewModel: AVAudioPlayerDelegate {
    
    private func setupPlayer() {
        if let actualSpeedValue = UserDefaults.standard.object(forKey: "playSpeed") as? Float {
            self.speed = actualSpeedValue
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
    
    private func setupRemoteTransportControls() {
        
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [unowned self] event in
            print("Play command - is playing: \(self.isPlaying)")
            if !self.isPlaying {
                self.handlePlayButton()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            print("Pause command - is playing: \(self.isPlaying)")
            if self.isPlaying {
                self.handlePlayButton()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            print("Next command - is playing: \(self.isPlaying)")
            self.handleNextButton()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            print("Previous command - is playing: \(self.isPlaying)")
            self.handlePreviousButton()
            return .success
        }
    }
    
    private func setupNowPlaying() {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = activeAyah?.id ?? ""
        
        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        
        guard let player = player else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        //        print("Now playing local: \(nowPlayingInfo)")
        //        print("Now playing lock screen: \(MPNowPlayingInfoCenter.default().nowPlayingInfo)")
    }
    
    private func updateNowPlaying() {
        // Define Now Playing Info
        
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo,
              let player = player else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
}
