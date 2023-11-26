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
    public var pages: [Page]
    private var audioSource: AudioSource = .alafasyHafs
    private var audioRecorder: AVAudioRecorder?
    
    private let speedDict: [Float:Float] = [
        1.0:1.25,
        1.25:1.5,
        1.5:1.75,
        1.75:2.0,
        2.0:1.0
    ]
    
    enum Mode {
        case player
        case recorder
    }
    @Published var mode: Mode = .player {
        didSet {
            if mode == .recorder {
                setRectanglesForCurrentRange()
            } else {
                setRectanglesForCurrentAyah()
            }
        }
    }
    @Published var ayahRectangles: [RectangleData] = []
    
    @Published var isHidden = false
    @Published var infoMessage = "Ready to play"
    @Published var activeRecording: Recording?
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isRepeatOn: Bool = false
    @Published var isShowingText = false
    
    @Published var activeItemId: String = UserDefaults.standard.string(forKey: "activeItemId") ?? "001000" {
        didSet {
            UserDefaults.standard.set(activeItemId, forKey: "activeItemId")
            UserDefaults.standard.synchronize()
            self.infoMessage = isPlaying ? String(self.activeItemId.dropFirst(3)) : ""
        }
    }
    
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
    
    @Published var currentRangeIndex = UserDefaults.standard.integer(forKey: "currentPageIndex") {
        didSet {
            UserDefaults.standard.set(speed, forKey: "currentPageIndex")
            UserDefaults.standard.synchronize()
            
            if player?.isPlaying ?? false {
                pausePlayer()
            }
            activeItemId = pages[currentRangeIndex].ayahs.first?.id ?? ""
            if mode == .recorder {
                setRectanglesForCurrentRange()
            } else {
                setRectanglesForCurrentAyah()
            }
        }
    }
    
    public var activeItemIndex: Int {
        if let index = pages[currentRangeIndex].ayahs.firstIndex(where: {$0.id == activeItemId}) {
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
        
        infoMessage = isRepeatOn ? "Repeat page is enabled" : "Repeat page is disabled"
    }
    
    public func handlePlayRecordingButton() {
        if let player = player,
           player.isPlaying {
            /// pause the player
            pausePlayer()
            return
        }
        
        self.playRecording(activeRecording?.uid.uuidString ?? "")
        isPlaying = true
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
    
    public func handleSpeedButton() {
        speed = speedDict[speed] ?? 1.0
        
        infoMessage = "Speed set to \(speed)x"
    }
    
    public func resetPlayer() {
        activeItemId = ""
        player?.stop()
        player = nil
    }
    
    
    public init(pages: [Page]) {
        self.pages = pages
        super.init()
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
    
    private func play(from source: AudioSource = .husaryHafs, itemId: String) {
        
        if itemId.isEmpty,
           let firstAyahId = pages[currentRangeIndex].ayahs.first?.id  {
            activeItemId = firstAyahId
        } else {
            activeItemId = itemId
        }
        
        let itemToPlay: String
        
        if mushafPublication == MushafPublication.hafsMadinan {
            /// detect if it's basmala that needs to be played
            let pattern = ".*[^1]000$"
            let regex = try! NSRegularExpression(pattern: pattern)
            
            if let _ = regex.firstMatch(in: activeItemId, range: NSRange(activeItemId.startIndex..., in: activeItemId)) {
                itemToPlay = "001000"
            } else {
                itemToPlay = activeItemId
            }
        } else {
            itemToPlay = activeItemId
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

        let lines = pages[currentRangeIndex].ayahs.flatMap( {$0.lines })
        extractRectanges(from: lines)
        
    }
    
    func setRectanglesForCurrentAyah() {
        self.ayahRectangles = []

        if pages.count > currentRangeIndex,
           let surahNumber = Int(activeItemId.prefix(3)),
           let ayahNumber = Int(activeItemId.suffix(3)),
           let ayahCoordinates = pages[currentRangeIndex].ayahs.first(where: {$0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber})  {
            
            extractRectanges(from: ayahCoordinates.lines)
            
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
        isPlaying = false
        updateNowPlaying()
        self.player?.pause()
    }
    
    private func stopPlayer() {
        isPlaying = false
        updateNowPlaying()
        self.player?.stop()
    }
    
    private func goToNextItem(){
        if activeItemIndex < 0 {
            /// player is inactive
            /// start from the first ayah in the current range
            activeItemId = pages[currentRangeIndex].ayahs.first?.id ?? ""
            play(itemId: activeItemId)
        } else if activeItemIndex < pages[currentRangeIndex].ayahs.count - 1 {
            /// more items ahead in the current range
            /// keep playing
            self.activeItemId = pages[currentRangeIndex].ayahs[activeItemIndex+1].id
            if isPlaying {
                play(itemId:activeItemId)
            }
        } else if isPlaying && isRepeatOn {
            /// repeat is on and we finished playing the range
            /// play the same range from start
            self.activeItemId = pages[currentRangeIndex].ayahs.first?.id ?? ""
        } else if currentRangeIndex < pages.count - 1 {
            /// range is done playing and repeat is off
            /// go to next range
            self.currentRangeIndex += 1
            self.activeItemId = pages[currentRangeIndex].ayahs.first?.id ?? ""
            if isPlaying {
                play(itemId:activeItemId)
            }
        } else {
            /// we reached the end
            /// stop playing
            self.currentRangeIndex = 0
            self.activeItemId = ""
            stopPlayer()
            player = nil
        }
    }
    
    
    private func goToPreviousItem() {
        
        if activeItemIndex <= 0 { // either first ayah on the page or no active ayah
            currentRangeIndex = currentRangeIndex > 0 ? currentRangeIndex - 1 : pages.count - 1 // go to previous page
            activeItemId = pages[currentRangeIndex].ayahs.last?.id ?? ""
            if isPlaying {
                play(itemId: activeItemId)
            }
        } else { // we reached the end, go to fatiha and stop playing
            activeItemId = pages[currentRangeIndex].ayahs[activeItemIndex-1].id
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
            DispatchQueue.main.async {
                self.isPlaying = true
            }
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
        
        guard let first = pages[currentRangeIndex].ayahs.first?.id,
              let last = pages[currentRangeIndex].ayahs.last?.id else {
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
        nowPlayingInfo[MPMediaItemPropertyTitle] = activeItemId
        
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
