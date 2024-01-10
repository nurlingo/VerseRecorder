//
//  RecorderView.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//
import SwiftUI
import AVFoundation

@available(iOS 15.0, *)
public struct RecorderView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject private var recorderVM: RecorderViewModel
    
    enum PlayerMode {
        case player
        case recorder
    }
    
    public init(range: Range, clientStorage: ClientStorage, recording: RangeRecording? = nil) {
        self.recorderVM = RecorderViewModel(range: range, clientStorage: clientStorage, recording: recording)
    }

    @State private var didLoad = false
    
    public var body: some View {
        
        RecorderListView(recorderVM: recorderVM)
            .navigationTitle(recorderVM.title + " (" + "recording".localized() + ")")
        
        ProgressView(value: (recorderVM.progress), total: 1)
            .tint(Color.primary)
        
        RecorderControlPanel(recorderVM: recorderVM)
            .frame(height: 50)
            .onDisappear {
                recorderVM.resetPlayer()
                recorderVM.resetRecorder()
            }
        
        
    }
    
    private func handleModeButton() {
        
        AVAudioSession.sharedInstance().requestRecordPermission() { allowed in
            DispatchQueue.main.async {
                if allowed {
                    /// all good
                } else {
                    print("recording is not allowed!")
                    /// FIXME: what else should be done?
                }
            }
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
struct RecorderListView: View {
    
    @StateObject private var fontVM = FontViewModel()
    @StateObject var recorderVM: RecorderViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                if recorderVM.range.id != "001" {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .frame(maxWidth: .infinity, alignment: Alignment.topLeading)
                        .font(.uthmanicTahaScript(size: CGFloat(fontVM.fontSize)))
                        .minimumScaleFactor(0.01)
                        .multilineTextAlignment(.leading)
                        .allowsTightening(true)
                        .lineSpacing(CGFloat(fontVM.fontSize/6))
                        .environment(\.layoutDirection, .rightToLeft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                    
                ForEach(recorderVM.tracks, id: \.id ) { track in
                    HStack{
                        Spacer().frame(width:1)
                        if recorderVM.activeItemId == track.id {
                            Color.blue.frame(width:3)
                        } else {
                            Color.clear.frame(width:3)
                        }
                        Spacer().frame(width:12)
                        
                        VStack{
                            
                            Spacer().frame(height:2)
                            
                            HStack {
                                
                                VStack {
                                    if recorderVM.recordingExists(track.id) {
                                        Image(systemName: "recordingtape.circle")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.red, .primary)
                                            .frame(width:16,height:16)
                                    }
                                    Spacer()
                                        .frame(height:4)
                                    if recorderVM.recordingUploaded(track.id) {
                                        Image(systemName: "checkmark.icloud")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.blue, .primary)
                                            .frame(width:16,height:16)
                                    } else {
                                        Spacer()
                                            .frame(width:16,height:16)
                                    }
                                }
                                
                                Text(recorderVM.rangeRecording.audioId != "001" ? track.text.deletingPrefix("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ").deletingPrefix("بِّسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ") : track.text)
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
                                        recorderVM.setVisibility(for: track.id, isVisible: false)
                                    }
                            }

                            Spacer().frame(height:8)
                            
                            Text(track.meaning)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font.system(size: CGFloat(fontVM.fontSize*0.6)))
                                .fixedSize(horizontal: false, vertical: true)
                                
                            Spacer().frame(height:8)
                                .onAppear {
                                    //                            print("appearing:", atom.id)
                                    recorderVM.setVisibility(for: track.id, isVisible: true)
                                }
                        }
                        Spacer().frame(width:16)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {
                        recorderVM.handleRowTap(at: track.id)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: recorderVM.activeItemId, perform: { newId in
                
                if recorderVM.getVisibility(for: newId) {return}
                withAnimation {
                    proxy.scrollTo(newId, anchor: .topLeading)
                }
            })
            
        }
        
    }
    
}

import SwiftUI

@available(iOS 13.0.0, *)
struct PanelButton: View {
    
    let imageName: String
    let height: CGFloat
    
    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .scaledToFit()
            .font(.system(size: 16, weight: .light))
            .frame(width: 40, height: height)
    }
}

@available(iOS 15.0, *)
struct RecorderControlPanel: View {
    
    @StateObject var recorderVM: RecorderViewModel
    
    @State var isConfirmingDelete: Bool = false
    @State var isConfirmingUpload: Bool = false
    
    var body: some View {
        HStack {
            Spacer().frame(width:16)
            GeometryReader { geo in
                HStack{
                    
                    if !recorderVM.isRecording,
                       recorderVM.recordingExists(recorderVM.activeItemId),
                       !recorderVM.isAnOldRecording {
                        
                        Button {
                            print("delete")
                            isConfirmingDelete = true
                        } label: {
                            
                            VStack {
                                Image(systemName: "delete.backward")
                                    .resizable()
                                    .scaledToFit()
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.red, .primary)
                                    .font(.system(size: 16, weight: .light))
                                    .frame(width: 40, height: geo.size.height * 0.4)
                            }
                            .frame(width: geo.size.height * 0.8, height: geo.size.height * 0.8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .confirmationDialog("Delete Audio".localized(),
                                            isPresented: $isConfirmingDelete) {
                            
                            Button("Delete All".localized(), role: .destructive) {
                                recorderVM.handleDeleteAction(shallDeleteAll: true)
                            }
                            
                            Button("Delete Current".localized()) {
                                recorderVM.handleDeleteAction()
                            }
                        } message: {
                            Text("Delete Explanation".localized())
                        }
                        
                       
                        
                    } else {
                        Spacer().frame(width: geo.size.height * 0.8)
                    }
                    
                    Spacer()
                    
                    Button {
                        recorderVM.handlePreviousButton()
                        print("backward tapped!")
                    } label: {
                        PanelButton(imageName: "backward.fill", height: geo.size.height * 0.4)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    if !recorderVM.isRecording,
                       recorderVM.recordingExists(recorderVM.activeItemId) {
                        Button {
                            recorderVM.handlePlayButton()
                        } label: {
                            PanelButton(imageName: recorderVM.isPlaying ? "pause.circle" : "play.circle", height: geo.size.height * 0.8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        
                        Button {
                            recorderVM.handleRecordButton()
                        } label: {
                            if recorderVM.isRecording {
                                PanelButton(imageName: "stop.circle", height: geo.size.height * 0.8)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.primary, .red)
                            } else {
                                PanelButton(imageName: "record.circle", height: geo.size.height * 0.8)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.red, .primary)
                            }
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    
                    Spacer()
                    
                    Button {
                        recorderVM.handleNextButton()
                        print("forward tapped!")
                    } label: {
                        PanelButton(imageName: "forward.fill", height: geo.size.height * 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    if !recorderVM.isRecording,
                       !recorderVM.isUploading,
                       recorderVM.hasTrackRecordingsToUpload {
                        Button {
                            print("upload")
                            isConfirmingUpload = true
                        } label: {
                            
                            VStack {
                                Image(systemName: "icloud.and.arrow.up")
                                    .resizable()
                                    .scaledToFit()
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.blue, .primary)
                                    .font(.system(size: 16, weight: .light))
                                    .frame(width: 40, height: geo.size.height * 0.4)
                            }
                            .frame(width: geo.size.height * 0.8, height: geo.size.height * 0.8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .confirmationDialog("Upload Audios".localized(),
                                            isPresented: $isConfirmingUpload) {
                            Button("Upload".localized()) {
                                recorderVM.handleUploadButton()
                            }
                        } message: {
                            Text("Upload Audios".localized() + "\n" + "Upload Explanation".localized())
                        }
                    } else {
                        Spacer().frame(width: geo.size.height * 0.8)
                    }
                    
                    
                    
                }
            }
            
            Spacer().frame(width:16)
            
        }
    }
}


