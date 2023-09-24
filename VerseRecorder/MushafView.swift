
//
//  MushafView.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 16.09.2023.
//

import SwiftUI

import AVFoundation
import MediaPlayer

public enum MushafPublication {
    case hafsMadinan
    case qaloonMadinan
}

struct SurahNames {
    
    static let juzAmma: [Int: (String, String)] = [
        1: ("الفاتحة", "Al-Fatiha"),
        78: ("النبأ", "An-Naba"),
        79: ("النازعات", "An-Nazi'at"),
        80: ("عبس", "Abasa"),
        81: ("التكوير", "At-Takwir"),
        82: ("الإنفطار", "Al-Infitar"),
        83: ("المطففين", "Al-Mutaffifin"),
        84: ("الإنشقاق", "Al-Inshiqaq"),
        85: ("البروج", "Al-Buruj"),
        86: ("الطارق", "At-Tariq"),
        87: ("الأعلى", "Al-Ala"),
        88: ("الغاشية", "Al-Ghashiyah"),
        89: ("الفجر", "Al-Fajr"),
        90: ("البلد", "Al-Balad"),
        91: ("الشمس", "Ash-Shams"),
        92: ("الليل", "Al-Lail"),
        93: ("الضحى", "Adh-Dhuha"),
        94: ("الشرح", "Ash-Sharh"),
        95: ("التين", "At-Tin"),
        96: ("العلق", "Al-Alaq"),
        97: ("القدر", "Al-Qadr"),
        98: ("البينة", "Al-Bayyina"),
        99: ("الزلزلة", "Az-Zalzalah"),
        100: ("العاديات", "Al-Adiyat"),
        101: ("القارعة", "Al-Qari'a"),
        102: ("التكاثر", "At-Takathur"),
        103: ("العصر", "Al-Asr"),
        104: ("الهمزة", "Al-Humazah"),
        105: ("الفيل", "Al-Fil"),
        106: ("قريش", "Quraish"),
        107: ("الماعون", "Al-Ma'un"),
        108: ("الكوثر", "Al-Kawthar"),
        109: ("الكافرون", "Al-Kafirun"),
        110: ("النصر", "An-Nasr"),
        111: ("المسد", "Al-Masad"),
        112: ("الإخلاص", "Al-Ikhlas"),
        113: ("الفلق", "Al-Falaq"),
        114: ("الناس", "An-Nas")
    ]

    
}


@available(iOS 15.0.0, *)
public struct MushafView: View {
    
    @ObservedObject private var mushafVM: MushafViewModel
    
    public init(mushafVM: MushafViewModel) {
        self.mushafVM = mushafVM
    }
    
    public var body: some View {
        Spacer()
        HStack(alignment:.bottom) {
            Text(SurahNames.juzAmma[Int(mushafVM.activeItemId.dropLast(3)) ?? 1]?.1 ?? "")
            Spacer()
            Text(String(mushafVM.pages[mushafVM.currentPageIndex]))
            Spacer()
            Text(SurahNames.juzAmma[Int(mushafVM.activeItemId.dropLast(3)) ?? 1]?.0 ?? "")
        }
        .padding(.horizontal, 32)

        TabView(selection: $mushafVM.currentPageIndex) {
            ForEach(0..<mushafVM.pages.count, id: \.self) { index in
                Image(String(mushafVM.pages[index]))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(x: -1, y: 1)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .scaleEffect(x: -1, y: 1)
        
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
        HStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                
                Text(mushafVM.infoMessage)
                
                HStack{
                    
                    Button {
                        mushafVM.handleRepeatButton()
                        print("repeat tapped")
                    } label: {
                        Image(systemName: mushafVM.isRepeatOn ? "repeat.circle.fill" : "repeat.circle")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        mushafVM.handlePreviousButton()
                        print("backward tapped!")
                    } label: {
                        Image(systemName: "backward.circle")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    
                    Button {
                        mushafVM.handleNextButton()
                        print("forward tapped!")
                    } label: {
                        Image(systemName: "forward.circle")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        mushafVM.handleSpeedButton()
                        print("speed tapped:", mushafVM.speed)
                    } label: {
                        Image(systemName: "speedometer")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 30, height: 30)
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
                    .font(.system(size: 20, weight: .ultraLight))
                    .frame(width: 70, height: 70)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}


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
    public var pages: [Int]
    public var tracks: [[String]]
    private var audioSource: AudioSource = .alafasyHafs
    
    private let speedDict: [Float:Float] = [
        1.0:1.25,
        1.25:1.5,
        1.5:1.75,
        1.75:2.0,
        2.0:1.0
    ]
    
    @Published var infoMessage = "Ready to play"
    
    @Published var currentPageIndex = UserDefaults.standard.integer(forKey: "currentPageIndex") {
        didSet {
            print(currentPageIndex)
            UserDefaults.standard.set(speed, forKey: "currentPageIndex")
            UserDefaults.standard.synchronize()
            
            if player?.isPlaying ?? false {
                pausePlayer()
            }
            activeItemId = tracks[currentPageIndex].first ?? ""
        }
    }
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
    
    public func handleRepeatButton() {
        isRepeatOn.toggle()
        
        infoMessage = isRepeatOn ? "Repeat page is enabled" : "Repeat page is disabled"
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

    
    public init(pages: [Int], tracks: [[String]]) {
        self.pages = pages
        self.tracks = tracks
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
        
        if itemId.isEmpty, let first = tracks[currentPageIndex].first  {
            activeItemId = first
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
