
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
    
    @State private var imageSize: CGSize = .zero
    
    public var body: some View {
        HStack(alignment: .bottom) {
            Text(SurahNames.juzAmma[Int(mushafVM.activeItemId.dropLast(3)) ?? 1]?.1 ?? "")
            Spacer()
            Text(String(mushafVM.pages[mushafVM.currentRangeIndex].pageNumber))
            Spacer()
            Text(SurahNames.juzAmma[Int(mushafVM.activeItemId.dropLast(3)) ?? 1]?.0 ?? "")
        }
        .padding(.horizontal, 32)

        TabView(selection: $mushafVM.currentRangeIndex) {
            ForEach(0..<mushafVM.pages.count, id: \.self) { index in
                GeometryReader { geometry in
                    Image(String(mushafVM.pages[index].pageNumber)) // Replace with the name of your image asset
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            imageSize = CGSize(width: geometry.size.width, height: geometry.size.height)
//                            print("Image size: \(imageSize)")
                        }
                        .overlay(
                            ForEach(mushafVM.ayahRectangles) { rectangle in
                                Rectangle()
                                    .fill(Color.yellow) // Change color as needed
                                    .opacity(0.2) // Change opacity as needed
                                    .frame(width: rectangle.rect.width * min(imageSize.width/728, imageSize.height/1131), height: rectangle.rect.height * min(imageSize.width/728, imageSize.height/1131))
                                    .position(x: (rectangle.rect.origin.x + rectangle.rect.size.width / 2) * min(imageSize.width/728, imageSize.height/1131) + 1,
                                              y: (rectangle.rect.origin.y + rectangle.rect.size.height / 2) * min(imageSize.width/728, imageSize.height/1131))
                            }
                        )
                        .scaleEffect(x: -1, y: 1)
                }
                
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
    public var pages: [Page]
    private var audioSource: AudioSource = .alafasyHafs
    
    private let speedDict: [Float:Float] = [
        1.0:1.25,
        1.25:1.5,
        1.5:1.75,
        1.75:2.0,
        2.0:1.0
    ]
    
    @Published var ayahRectangles: [RectangleData] = []
    
    @Published var infoMessage = "Ready to play"
    
    @Published var currentRangeIndex = UserDefaults.standard.integer(forKey: "currentPageIndex") {
        didSet {
//            print(currentRangeIndex)
            UserDefaults.standard.set(speed, forKey: "currentPageIndex")
            UserDefaults.standard.synchronize()
            
            if player?.isPlaying ?? false {
                pausePlayer()
            }
            activeItemId = pages[currentRangeIndex].ayahs.first?.id ?? ""
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
        if let index = pages[currentRangeIndex].ayahs.firstIndex(where: {$0.id == activeItemId}) {
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
            
            if pages.count > currentRangeIndex,
               let surahNumber = Int(itemToPlay.prefix(3)),
               let ayahNumber = Int(itemToPlay.suffix(3)),
               let ayahCoordinates = pages[currentRangeIndex].ayahs.first(where: {$0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber})  {
                
                
                ayahRectangles = []
                for line in ayahCoordinates.lines {
                    
                    if let lastPoint = line.last,
                       let firstPoint = line.first {
                        let x = lastPoint.x
                        let y = min(firstPoint.y1,firstPoint.y2)
                        let height = abs(firstPoint.y1 - firstPoint.y2)
                        let width = abs(firstPoint.x-lastPoint.x)
                        ayahRectangles.append(RectangleData(rect:CGRect(x: x, y: y, width: width, height: height)))
                    }
                    
                    
                }
                print("Ayah rectangles: \(ayahRectangles)")

                
            }
            
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
//    for track in ayahRanges.flatMap({$0}) {
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
//    } else if currentlyActiveIndex < ayahRanges.flatMap({$0}).count - 1 { /// moreItemsAhead
//        self.activeItemId = ayahRanges.flatMap({$0})[currentlyActiveIndex+1]
//    } else {
//        self.activeItemId = ayahRanges.flatMap({$0}).first ?? ""
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
//        self.activeItemId = ayahRanges.flatMap({$0})[currentlyActiveIndex-1]
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
//    uploader.uploadNewlyRecordedAudios(ayahRanges.flatMap({$0}))
//    var count = ayahRanges.count + 3
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
//    if activeItemId.isEmpty, let first = ayahRanges.flatMap({$0}).first  {
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
//    for track in ayahRanges.flatMap({$0}) {
//        if recordingStorage.doesRecordingExist(track) {
//            recorded += 1
//        }
//    }
//    clientStorage.saveRecordProgress(audioId, progress: Double(recorded)/Double(ayahRanges.count))
//}
//
//private func recordNextItem(){
//    finishRecording()
//
//    if currentlyActiveIndex < ayahRanges.count - 1 {
//        /// moreItemsAhead
//        self.activeItemId = ayahRanges.flatMap({$0})[currentlyActiveIndex+1]
//        startRecording()
//    } else {
//        activeItemId = ayahRanges.flatMap({$0}).first ?? ""
//    }
//}
//
//
//private func recordPreviousItem() {
//
//    finishRecording()
//
//    if currentlyActiveIndex > 0 {
//        activeItemId = ayahRanges.flatMap({$0})[currentlyActiveIndex-1]
//        startRecording()
//    }
//}
