//
//  PlayerView.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import SwiftUI
import AVFoundation

@available(iOS 15.0, *)
struct PlayerView: View {
    
    @Environment(\.colorScheme) var colorScheme
    let audio: Surah
    
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var fontVM = FontViewModel()
    
    @State private var didLoad = false
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(audio.ayahs, id: \.id ) { ayah in
                    HStack{
                        Spacer().frame(width:16)
                        VStack{
                            
                            Spacer().frame(height:2)
                            
                            HStack {
                                
                                Text(audio.id != "1" ? ayah.text.deletingPrefix("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ").deletingPrefix("بِّسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ") : ayah.text)
                                    .frame(maxWidth: .infinity, alignment: Alignment.topLeading)
                                    .font(.uthmanicTahaScript(size: CGFloat(fontVM.fontSize)))
                                    .minimumScaleFactor(0.01)
                                    .multilineTextAlignment(.leading)
                                    .allowsTightening(true)
                                    .lineSpacing(CGFloat(fontVM.fontSize/6))
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .onDisappear {
                                        //                            print("disappearing:", atom.id)
                                        playerVM.setVisibility(for: ayah.id, isVisible: false)
                                    }
                            }
                            
                            Spacer().frame(height:8)
                            
                            Text(ayah.meaning)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font.system(size: CGFloat(fontVM.fontSize/2)))
                                .fixedSize(horizontal: false, vertical: true)
                                .listRowBackground(Color.clear)
                                .onAppear {
                                    //                            print("appearing:", atom.id)
                                    playerVM.setVisibility(for: ayah.id, isVisible: true)
                                }
                            
                            Spacer().frame(height:8)
                        }
                        Spacer().frame(width:12)
                        if playerVM.activeItemId == ayah.id {
                            Color.blue.frame(width:3)
                        } else {
                            Color.clear.frame(width:3)
                        }
                        Spacer().frame(width:1)
                    }
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {
                        playerVM.handleRowTap(at: ayah.id)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: playerVM.activeItemId, perform: { newId in
                
                if playerVM.getVisibility(for: newId) {return}
                withAnimation {
                    proxy.scrollTo(newId, anchor: .topLeading)
                }
            })
            
        }.onAppear {
            if didLoad == false {
                didLoad = true
                playerVM.tracks = audio.ayahs.map { $0.id }
            }
            
        }.onDisappear {
            playerVM.resetPlayer()
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                
                
                Menu {
                    Stepper(value: $fontVM.fontSize,
                            in: fontVM.fontRange,
                            step: fontVM.fontStep) {
                        Text("Font: \(Int(fontVM.fontSize))")
                    }
                    Stepper(value: $playerVM.speed,
                            in: playerVM.range,
                            step: playerVM.step) {
                        Text("Speed: \(String(format: "%.2f", playerVM.speed))x")
                    }
                } label: {
                    Image(systemName:"ellipsis.circle")
                }
                
                
                
            }
        }
        
        
        
        ProgressView(value: playerVM.progress, total: 1)
            .tint(Color.primary)
        HStack {
            PlayerControlPanel(playerVM: playerVM)
                .frame(height: 50)
        }
        
        
    }
    
    private func isRowOutsideScreen(_ geometry: GeometryProxy) -> Bool {
        // Alternatively, you can also check for geometry.frame(in:.global).origin.y if you know the button height.
        if geometry.frame(in: .global).maxY <= 0 {
            return true
        }
        return false
    }
    
}

@available(iOS 15.0, *)
struct PlayerControlPanel: View {
    
    @StateObject var playerVM: PlayerViewModel
    
    var body: some View {
        HStack {
            Spacer().frame(width:16)
            GeometryReader { geo in
                HStack{
                    
                    Spacer()
                    
                    Button {
                        playerVM.handlePreviousButton()
                        print("backward tapped!")
                    } label: {
                        PanelButton(imageName: "backward.fill", height: geo.size.height * 0.4)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button {
                        playerVM.handlePlayButton()
                    } label: {
                        PanelButton(imageName: playerVM.isPlayOn ? "pause.circle" : "play.circle", height: geo.size.height * 0.8)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        playerVM.handleNextButton()
                        print("forward tapped!")
                    } label: {
                        PanelButton(imageName: "forward.fill", height: geo.size.height * 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button {
                        playerVM.handleClockButton()
                    } label: {
                        PanelButton(imageName: "stopwatch", height: geo.size.height * 0.5)
                            .foregroundColor(playerVM.isClockOn ? Color.primary : Color(UIColor.tertiaryLabel))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        playerVM.handleRepeatButton()
                    } label: {
                        
                        switch playerVM.repeatMode {
                        case .repeatOff:
                            PanelButton(imageName: "repeat", height: geo.size.height * 0.7)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        case .repeatAll:
                            PanelButton(imageName: "repeat", height: geo.size.height * 0.7)
                                .foregroundColor(.primary)
                        case .repeatOne:
                            PanelButton(imageName: "repeat.1", height: geo.size.height * 0.7)
                                .foregroundColor(.primary)
                        }
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer().frame(width:16)
            
        }
    }
}

//
//  AudioPlayer.swift
//  namaz
//
//  Created by Daniya on 11/01/2020.
//  Copyright © 2020 Nursultan Askarbekuly. All rights reserved.
//

import AVFoundation
import MediaPlayer

@available(iOS 15.0, *)
class PlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    @Published var activeItemId: String = ""
    @Published var progress: Float = 0
    
    @Published var speed: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(speed, forKey: "playSpeed")
            UserDefaults.standard.synchronize()
            
            if let player = player, player.isPlaying {
                
                player.stop()
                
                /// if volume is ON, limit playspeed to 1.75
//                let isVolumeOn = AVAudioSession.sharedInstance().outputVolume > 0
                player.rate = speed // isVolumeOn ? min(speed, 1.75) : speed
                
                player.prepareToPlay()
                player.play()
            }
        }
    }
    let step: Float = 0.25
    let range: ClosedRange<Float> = 1.00...2.00
        
    @Published var isPlayOn: Bool = false
    @Published var isClockOn: Bool = false
    @Published var repeatMode: RepeatMode = .repeatOff
        
    public var tracks: [String] = []
    private var visibleRows: [String:Bool] = [:]
    
    public func setVisibility(for item: String, isVisible: Bool) {
        visibleRows[item] = isVisible
    }
    
    public func getVisibility(for item: String) -> Bool {
        visibleRows[item] ?? false
    }
    
    public var progressMode: ProgressMode = .durationBased
    public var currentlyPlayingIndex: Int {
        if let index = tracks.firstIndex(of: activeItemId) {
            return index
        } else {
            return -1
        }
    }
    
    private var player: AVAudioPlayer?
    private var updater : CADisplayLink! = nil
    private var timer: Timer?
    private var runCount: Double = 0

    enum RepeatMode: Int {
        case repeatOff = 1
        case repeatAll = 2
        case repeatOne = 3
    }
    
    enum ProgressMode {
        case rowBased
        case durationBased
    }
    
    public func handlePlayButton() {
        guard let player = player else {
            
            self.playFromBundle(itemId: activeItemId)
            return
        }
        
        if player.isPlaying {
            /// pause the player
            pausePlayer()
        } else if timer != nil {
            
            if timer!.isValid {
                isPlayOn = false
                timer?.invalidate()
            } else {
                isPlayOn = true
                startTimer()
            }
            
        } else {
            isPlayOn = true
            updateNowPlaying()
            player.play()
        }
    }
    
    public func handleNextButton() {
        playNextItem()
    }
    
    public func handlePreviousButton() {
        playPreviousItem()
    }
    
    public func handleRepeatButton() {
        
        if repeatMode == .repeatAll {
            repeatMode = .repeatOff
        } else {
            repeatMode = .repeatAll
        }
        
//        let newValue = (repeatMode.rawValue % 3) + 1
//        repeatMode = RepeatMode(rawValue: newValue) ?? .repeatOff
        
        UserDefaults.standard.set(repeatMode.rawValue, forKey: "repeatMode")
        UserDefaults.standard.synchronize()
    }
    
    public func handleClockButton() {
        isClockOn.toggle()
        UserDefaults.standard.set(isClockOn, forKey: "isClockOn")
        UserDefaults.standard.synchronize()
    }
    
    public func handleRowTap(at rowId: String) {
        self.activeItemId = rowId
        playFromBundle(itemId: activeItemId)
    }
    
    override init() {
        super.init()
        setupPlayer()
        registerForInterruptions()
        setupRemoteTransportControls()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(goToBackground),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(returnToForeground),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
    }
    
    deinit {
        resetPlayer()
        repeatMode = .repeatOff
        progressMode = .durationBased
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        updater = nil
    }
    
    private func playFromBundle(itemId: String) {
        
        if itemId.isEmpty, let first = tracks.first  {
            activeItemId = first
        } else {
            activeItemId = itemId
        }
        
        guard let path = Bundle.main.path(forResource: activeItemId, ofType: "mp3") else {
            playDownloadedAyah(ayahNumber: itemId, bitRate: 192, editing: "ar.abdulbasitmurattal")
            return
        }
        
        self.playAudio(at: path)
    }
    
    func playDownloadedAyah(ayahNumber: String, bitRate: UInt, editing: String) {
        
        if ayahNumber.isEmpty, let first = tracks.first  {
            activeItemId = first
        } else {
            activeItemId = ayahNumber
        }
        
        Task {
            
            do {
                
                let url = try await ContentStorage.shared.loadAyahAudio(ayahNumber: activeItemId, bitRate: bitRate, editing: editing)
                DispatchQueue.main.async {
                    self.playAudio(at: url.path)
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func playAudio(at path: String) {
        
        let url = URL(fileURLWithPath: path)
        player = nil
        stopTimer()
        removeDurationTracking()
        /// Uncomment for progress by tracks played
        if progressMode == .rowBased {
            progress = max(0, Float(currentlyPlayingIndex)/Float(tracks.count-1))
            removeDurationTracking()
        } else if progressMode == .durationBased {
            setupDurationTracking()
        }
        
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
                self.setupNowPlaying()
                self.isPlayOn = true
            }
        } catch let error as NSError {
            print(#function, error.description)
        }
        
    }
    
    private func pausePlayer() {
        isPlayOn = false
        updateNowPlaying()
        self.player?.pause()
    }
    
    private func playNextItem(){
        
        if repeatMode == .repeatOne {
            playFromBundle(itemId: activeItemId)
        } else if currentlyPlayingIndex < tracks.count - 1 { /// moreItemsAhead
            self.playFromBundle(itemId: tracks[currentlyPlayingIndex+1])
        } else if repeatMode == .repeatAll {
            
            //            Analytics.shared.logEvent("Audio Completed", properties: [
            //                "onRepeat": true,
            //                "audio": audio.id
            //            ])
            
            self.playFromBundle(itemId: "")
        } else {
            
            //            Analytics.shared.logEvent("Audio Completed", properties: [
            //                "onRepeat": false,
            //                "audio": audio.id
            //            ])
            activeItemId = ""
            isPlayOn = false
            progress = 0
            updateNowPlaying()
            self.resetPlayer()
        }
    }
    
    private func playPreviousItem() {
        if currentlyPlayingIndex > 0 {
            let previousItemId = tracks[currentlyPlayingIndex-1]
            playFromBundle(itemId: previousItemId)
        } else {
            playFromBundle(itemId: "")
        }
    }
    
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        if isClockOn {
            self.removeDurationTracking()
            self.runCount = 0
            startTimer()
        } else {
            playNextItem()
        }
    }
    
    public func resetPlayer() {
        activeItemId = ""
        player?.stop()
        player = nil
    }
    
    private func setupDurationTracking() {
        updater = CADisplayLink(target: self, selector: #selector(self.trackAudio))
        updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    private func removeDurationTracking() {
        guard let _ = updater else { return }
        updater.invalidate()
        updater = nil
    }
    
    private func startTimer() {
        
        guard let player = player else {return}
        let duration = player.duration + 0.5
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            self.runCount += 0.01
//            print(self.runCount, player.duration)
            
            if player.duration > 0 {
                let newProgress = Float((duration - self.runCount) / duration)
                self.progress = newProgress >= 0 ? newProgress : 0
            }
            
            if self.runCount > duration {
                self.timer?.invalidate()
                self.playNextItem()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func trackAudio() {
        
        let current: Float = Float(player?.currentTime ?? 0.0)
        let duration: Float = Float(player?.duration ?? 1.0)
//        print(current, duration)
        
        if current < 0.15 {
            return
        }
        
        let newProgress = current / duration
        self.progress = newProgress
        
    }
    
    @objc private func goToBackground() {
        
        if timer != nil {
            stopTimer()
            playNextItem()
        }
        
        self.isClockOn = false
    }
    
    @objc private func returnToForeground() {
        
        self.isClockOn = UserDefaults.standard.bool(forKey: "isClockOn")

    }
    
}

@available(iOS 15.0, *)
extension PlayerViewModel {
    
    private func setupPlayer() {
        if let actualSpeedValue = UserDefaults.standard.object(forKey: "playSpeed") as? Float {
            self.speed = actualSpeedValue
        }
        
        self.isClockOn = UserDefaults.standard.bool(forKey: "isClockOn")
        
        let repeatValue = UserDefaults.standard.integer(forKey: "repeatMode")
        self.repeatMode = RepeatMode(rawValue: repeatValue) ?? .repeatOff
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
            print("Play command - is playing: \(self.isPlayOn)")
            if !self.isPlayOn {
                self.handlePlayButton()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            print("Pause command - is playing: \(self.isPlayOn)")
            if self.isPlayOn {
                self.handlePlayButton()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            print("Next command - is playing: \(self.isPlayOn)")
            self.handleNextButton()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            print("Previous command - is playing: \(self.isPlayOn)")
            self.handlePreviousButton()
            return .success
        }
    }
    
    private func setupNowPlaying() {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = activeItemId
        
        if let image = UIImage(named: "artist") {
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
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlayOn ? 1 : 0
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
}
