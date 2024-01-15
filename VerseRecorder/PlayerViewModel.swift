//
//  PlayerViewModel.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 08.12.2023.
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
public class PrayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    private let speedDict: [Float:Float] = [
        1.0:1.25,
        1.25:1.5,
        1.5:1.75,
        1.75:2.0,
        2.0:1.0
    ]
    
    public let ayahs: [AyahPart]
    
    var standardMessage = "Husary (Qaloon)" {
        didSet {
            self.setInfoMessage(standardMessage)
        }
    }
    
    @Published var infoMessage = "" {
        didSet {
            let currentMessage = infoMessage
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.infoMessage != self.standardMessage,
                   self.infoMessage == currentMessage {
                    self.infoMessage = self.standardMessage
                }
            }
        }
    }
    
    @Published var speed: Float = UserDefaults.standard.float(forKey: "playSpeed") {
        didSet {
            UserDefaults.standard.set(speed, forKey: "playSpeed")
            UserDefaults.standard.synchronize()
            
            if let player = PrayerViewModel.player, player.isPlaying {
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
    
    static var player: AVAudioPlayer?
    var activeItemId: String = ""
    
    public init(ayahs: [AyahPart]) {
        self.ayahs = ayahs
        super.init()
        setupRemoteTransportControls()
        registerForInterruptions()
    }
    
    // MARK: - Overridable methods
    
    public func playActiveItem() {}
    
    public func goToNextItem() {}
    
    public func goToPreviousItem() {}
    
    public func handleRepeatButton() {
        isRepeatOn.toggle()
        setInfoMessage(isRepeatOn ? "Repeat enabled" : "Repeat disabled")
    }
    
    func setInfoMessage(_ text: String) {
        infoMessage = text
    }
    
    public func handlePlayButton() {
        if let player = PrayerViewModel.player,
           player.isPlaying {
            /// pause the player
            pausePlayer()
            return
        }
        
        self.playActiveItem()
    }
    
    public func handleNextButton() {
        goToNextItem()
    }
    
    public func handlePreviousButton() {
        goToPreviousItem()
    }
    
    public func handleSpeedButton() {
        speed = speedDict[speed] ?? 1.0
        setInfoMessage("Speed set to \(speed)x")
    }
    
    deinit {
        resetPlayer()
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    public func pausePlayer() {
        updateNowPlaying()
        PrayerViewModel.player?.pause()
        self.isPlaying = false
    }
    
    public func stopPlayer() {
        updateNowPlaying()
        PrayerViewModel.player?.stop()
        self.isPlaying = false
    }
    
    public func resetPlayer() {
        PrayerViewModel.player?.stop()
        PrayerViewModel.player = nil
        self.isPlaying = false
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlaying = false
        goToNextItem()
    }
    
    // MARK: - Service functions
    
    public func getDocumentsDirectory() -> URL {
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
            self.goToNextItem()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            print("Previous command - is playing: \(self.isPlaying)")
            self.goToPreviousItem()
            return .success
        }
    }
    
    public func setupNowPlaying() {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = activeItemId
        
        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        
        guard let player = PrayerViewModel.player else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        //        print("Now playing local: \(nowPlayingInfo)")
        //        print("Now playing lock screen: \(MPNowPlayingInfoCenter.default().nowPlayingInfo)")
    }
    
    public func updateNowPlaying() {
        // Define Now Playing Info
        
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo,
              let player = PrayerViewModel.player else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
}
