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
public class RecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    public var clientStorage: ClientStorage
    @Published var rangeRecording: RangeRecording
    
    public let tracks: [Track]
    public let title: String
    let isAnOldRecording: Bool
    
    @Published var activeItemId: String = ""
    @Published var progress: Float = 0
    
    @Published var isPlaying: Bool = false
    @Published var isRecording: Bool = false
    @Published var isUploading: Bool = false
    @Published var isShowingTransliteration = false

    lazy var uploader = UploaderService(credentials: credentials, clientStorage: clientStorage)
    
    private var visibleRows: [String:Bool] = [:]
    
    var hasTrackRecordingsToUpload: Bool {
        rangeRecording.hasTrackRecordingsToUpload()
    }
    
    public init(range: Range, clientStorage: ClientStorage, recording: RangeRecording? = nil) {
        self.clientStorage = clientStorage
        
        if let recording = recording {
            self.rangeRecording = recording
            self.activeItemId = range.tracks.first?.id ?? ""
            self.isAnOldRecording = true
        } else {
            let rangeRecording = RangeRecording(audioId: range.id)
            self.rangeRecording = rangeRecording
            self.isAnOldRecording = false
        }
        
        
        self.tracks = range.tracks
        self.title = range.title
        super.init()
        setupPlayer()
        registerForInterruptions()
        
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
        progressMode = .durationBased
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        updater = nil
    }
    
    public func setVisibility(for item: String, isVisible: Bool) {
        visibleRows[item] = isVisible
    }
    
    public func getVisibility(for itemId: String) -> Bool {
        
        guard let index = tracks.firstIndex(where: {$0.id == itemId }),
              index > 0, /// cannot be first
              index < tracks.count - 1 /// cannot be last
        else {
            return false
        }
            
        /// FIXME: actually depends on direction
        return visibleRows[tracks[index+1].id] ?? false && visibleRows[tracks[index-1].id] ?? false
        
    }
    
    var progressMode: ProgressMode = .durationBased
    public var currentlyActiveIndex: Int {
        if let index = tracks.firstIndex(where: {$0.id == activeItemId}) {
            return index
        } else {
            return -1
        }
    }
    
    private var audioRecorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var updater : CADisplayLink! = nil
    private var runCount: Double = 0

    
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
        } else {
            isPlaying = true
            player.play()
        }
    }
    
    public func handleNextButton() {
        
        if isRecording {
            recordNextItem()
        } else if isPlaying {
            playNextItem()
        } else if currentlyActiveIndex < tracks.count - 1 { /// moreItemsAhead
            self.activeItemId = tracks[currentlyActiveIndex+1].id
        } else {
            self.activeItemId = tracks.first?.id ?? ""
        }
    }
    
    public func handlePreviousButton() {
        
        if isRecording {
            recordPreviousItem()
        } else if isPlaying {
            playPreviousItem()
        } else if currentlyActiveIndex > 0 {
            self.activeItemId = tracks[currentlyActiveIndex-1].id
        }
        
    }

    public func handleRecordButton() {
        if isRecording {
            resetRecorder()
            activeItemId = tracks.first?.id ?? ""
        } else {
            stopPlayer()
            startRecording()
        }
    }
    
    public func handleUploadButton() {
        if isRecording {
            resetRecorder()
        }
        
        if isPlaying {
            pausePlayer()
        }
        
        isUploading = true
        uploader.uploadRangeRecording(rangeRecording, actionAfterUploadingEachTrack: {
            self.activeItemId = self.activeItemId
        }, completion: {
            self.isUploading = false
        })
    }
    
    public func handleDeleteAction(shallDeleteAll: Bool = false) {
        if isRecording {
            resetRecorder()
        }
        
        if isPlaying {
            stopPlayer()
        }
        
        if shallDeleteAll {
            for track in rangeRecording.tracks.values {
                rangeRecording.deleteTrackRecording(track.id)
            }
        } else {
            rangeRecording.deleteTrackRecording(activeItemId)
        }
        
        self.activeItemId = self.activeItemId
    }
    
    public func handleRowTap(at rowId: String) {
        self.activeItemId = rowId
        if isPlaying && recordingExists(activeItemId) {
            playFromBundle(itemId: activeItemId)
        } else if isRecording && recordingExists(activeItemId) {
            resetRecorder()
            startRecording()
        } else {
            resetRecorder()
            stopPlayer()
        }
    }
    
    public func recordingExists(_ trackId: String) -> Bool {
        rangeRecording.trackRecordingExists(trackId)
    }
    
    public func recordingUploaded(_ trackId: String) -> Bool {
        rangeRecording.trackRecordingUploaded(trackId)
    }
    
    public func resetPlayer() {
        activeItemId = ""
        player?.stop()
        player = nil
    }
    
    public func resetRecorder() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
    }
    
    private func startRecording() {
        
        if activeItemId.isEmpty, let first = tracks.first  {
            activeItemId = first.id
        }
        
        stopPlayer()
        
        let audioFilename = rangeRecording.getPathForTrack(activeItemId)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            print("recorded audio:", audioFilename)
            isRecording = true
            rangeRecording.addTrack(activeItemId)
        } catch {
            print(#file, #function, #line, #column, "recording failed:", error.localizedDescription)
        }
    }
    
    private func playFromBundle(itemId: String) {
        
        if itemId.isEmpty, let first = tracks.first  {
            activeItemId = first.id
        } else {
            activeItemId = itemId
        }
        
        
        if recordingExists(activeItemId) {
            print("FILE AVAILABLE")
            self.playRecroding(activeItemId)
        } else {
            isPlaying = false
        }
        
        
    }
    
    private func playRecroding(_ trackId: String) {
        
        let url = rangeRecording.getPathForTrack(trackId)

        player = nil
        removeDurationTracking()
        /// Uncomment for progress by tracks played
        if progressMode == .rowBased {
            progress = max(0, Float(currentlyActiveIndex)/Float(tracks.count-1))
            removeDurationTracking()
        } else if progressMode == .durationBased {
            setupDurationTracking()
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.delegate = self
            player.prepareToPlay()
            player.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch let error as NSError {
            print(#file, #function, #line, #column, error.description)
        }
        
    }
    
    private func pausePlayer() {
        isPlaying = false
        self.player?.pause()
    }
    
    private func stopPlayer() {
        isPlaying = false
        self.player?.stop()
        progress = 0
    }
    
    private func recordNextItem(){
        resetRecorder()
        
        if currentlyActiveIndex < tracks.count - 1 {
            /// moreItemsAhead
            self.activeItemId = tracks[currentlyActiveIndex+1].id
            startRecording()
        } else {
            activeItemId = tracks.first?.id ?? ""
            progress = 0
        }
    }
    
    private func playNextItem(){
        
        if currentlyActiveIndex < tracks.count - 1 { /// moreItemsAhead
            self.playFromBundle(itemId: tracks[currentlyActiveIndex+1].id)
        } else {
            
            //            Analytics.shared.logEvent("Audio Completed", properties: [
            //                "onRepeat": false,
            //                "audio": audio.id
            //            ])
            activeItemId = tracks.first?.id ?? ""
            isPlaying = false
            progress = 0
            player?.stop()
            player = nil
        }
    }
    
    private func recordPreviousItem() {
        
        resetRecorder()
        
        if currentlyActiveIndex > 0 {
            activeItemId = tracks[currentlyActiveIndex-1].id
            startRecording()
        }
    }
    
    private func playPreviousItem() {
        if currentlyActiveIndex > 0 {
            let previousItemId = tracks[currentlyActiveIndex-1].id
            playFromBundle(itemId: previousItemId)
        } else {
            playFromBundle(itemId: "")
        }
    }
    
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        playNextItem()
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
        // do something?
    }
    
    @objc private func returnToForeground() {
        // do something?
    }
    
}

@available(iOS 15.0, *)
extension RecorderViewModel {
    
    private func setupPlayer() {
        do {
            // play sound even on silent
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
                try AVAudioSession.sharedInstance().setActive(true)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playAndRecord)
            }
            
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
