//
//  RecorderViewModel.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 08.12.2023.
//

import SwiftUI
import AVFoundation

@available(iOS 15.0, *)
public class RecorderViewModel: PrayerViewModel {
    
    @Published var isRecording: Bool = false
    @Published var activeRecording: RangeRecording?

    private var audioRecorder: AVAudioRecorder?
    lazy var recordingStorage: RecordingStorage = RecordingStorage.shared
    lazy var uploader: UploaderService = UploaderService(credentials: credentials)

    
    public override func goToNextItem(){
        playActiveItem()
    }
    
    public func playRecording(_ recording: RangeRecording) {
        
        let url = recordingStorage.getPath(for: recording.id.uuidString)
        
        self.activeRecording = recording
        self.isPlaying = true
        
        PrayerViewModel.player = nil
        
        do {
            PrayerViewModel.player = try AVAudioPlayer(contentsOf: url)
            guard let player = PrayerViewModel.player else { return }
            player.delegate = self
            player.enableRate = true
            
            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(#file, #function, #line, #column, error.description)
        }
        
    }
    
    public func handleRecordButton(start: String, end: String) {
        if isRecording {
            resetRecorder()
            if let activeRecording = activeRecording {
                print(activeRecording.date)
//                uploader.upload(activeRecording)
            }
        } else {
            stopPlayer()
            startRecording(start: start, end: end)
        }
    }
    
    public func recordingExists(_ recordingId: String) -> Bool {
        recordingStorage.recordingExists(recordingId)
    }
    
    public func resetRecorder() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        isPlaying = false
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func startRecording(start: String, end: String) {
        
        stopPlayer()
        
        activeRecording = RangeRecording(start: start, end: end)
        recordingStorage.addRecording(activeRecording!)
        let audioFilename = recordingStorage.getPath(for: activeRecording!.id.uuidString)
        
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
            self.isRecording = true
            self.isPlaying = false
        } catch {
            print(#file, #function, #line, #column, "recording failed:", error.localizedDescription)
        }
    }
}
