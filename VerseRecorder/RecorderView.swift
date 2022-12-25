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
    let audio: ContentMolecule
    
    @StateObject private var recorderVM = RecorderViewModel()
    
    enum PlayerMode {
        case player
        case recorder
    }
    
    public init(audio: ContentMolecule) {
        self.audio = audio
    }

    @State private var didLoad = false
    
    public var body: some View {
        
        
        
        if #available(iOS 16.0, *) {
            
            NavigationStack {
                RecorderListView(audio: audio, recorderVM: recorderVM)
            }
            .toolbar {
                Button {
                    recorderVM.isShowingTransliteration.toggle()
                    print("Show text tapped")
                } label: {
                    Image(systemName:"text.redaction")
                        .foregroundColor(recorderVM.isShowingTransliteration ? Color(uiColor: UIColor.lightGray.withAlphaComponent(0.5)) : Color.primary)
                }
            }
        } else {
            RecorderListView(audio: audio, recorderVM: recorderVM)
        }
        
        ProgressView(value: (recorderVM.progress), total: 1)
            .tint(Color.primary)
        
        RecorderControlPanel(recorderVM: recorderVM)
            .frame(height: 50)
            .onAppear {
                if didLoad == false {
                    didLoad = true
                    recorderVM.tracks = audio.atoms.map { $0.id }
                    recorderVM.activeItemId = recorderVM.tracks.first ?? ""
                }
                
            }
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
    
    let audio: ContentMolecule
    
    @StateObject private var fontVM = FontViewModel()
    @StateObject var recorderVM: RecorderViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                if audio.id != "1" {
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
                    
                ForEach(audio.atoms, id: \.id ) { atom in
                    HStack{
                        Spacer().frame(width:1)
                        if recorderVM.activeItemId == atom.id {
                            Color.blue.frame(width:3)
                        } else {
                            Color.clear.frame(width:3)
                        }
                        Spacer().frame(width:12)
                        
                        VStack{
                            
                            Spacer().frame(height:2)
                            
                            HStack {

                                VStack {
                                    if recorderVM.recordingExists(atom.id) {
                                        Image(systemName: "recordingtape.circle")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.red, .primary)
                                            .frame(width:16,height:16)
                                    }
                                    Spacer()
                                        .frame(height:4)
                                    if recorderVM.recordingUploaded(atom.id) {
                                        Image(systemName: "checkmark.icloud")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.blue, .primary)
                                            .frame(width:16,height:16)
                                    } else {
                                        Spacer()
                                            .frame(width:16,height:16)
                                    }
                                }

                                Text(audio.id != "1" ? atom.text.deletingPrefix("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ").deletingPrefix("بِّسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ") : atom.text)
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
                                        recorderVM.setVisibility(for: atom.id, isVisible: false)
                                    }
                            }
                            
                            Spacer().frame(height:4)

                            if !atom.commentary.isEmpty {
                                Text(atom.commentary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(Font.system(size: CGFloat(fontVM.fontSize*0.75)))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .background(recorderVM.isShowingTransliteration ? Color.clear : Color(uiColor: UIColor.lightGray.withAlphaComponent(0.5)))
                                    .foregroundColor(recorderVM.isShowingTransliteration ? Color.primary : Color.clear)

                            }

                            Spacer().frame(height:8)
                            
                            Text(atom.meaning)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font.system(size: CGFloat(fontVM.fontSize*0.6)))
                                .fixedSize(horizontal: false, vertical: true)
                                
                            Spacer().frame(height:8)
                                .onAppear {
                                    //                            print("appearing:", atom.id)
                                    recorderVM.setVisibility(for: atom.id, isVisible: true)
                                }
                        }
                        Spacer().frame(width:16)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {
                        recorderVM.handleRowTap(at: atom.id)
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
                       recorderVM.recordingExists(recorderVM.activeItemId) {
                        
                        
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
                            Button("Delete Current".localized()) {
                                recorderVM.handleDeleteAction()
                            }
                            
                            Button("Delete All".localized(), role: .destructive) {
                                recorderVM.handleDeleteAction(shallDeleteAll: true)
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
                        ControlButton(imageName: "backward.fill", height: geo.size.height * 0.4)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    if !recorderVM.isRecording,
                       recorderVM.recordingExists(recorderVM.activeItemId) {
                        Button {
                            recorderVM.handlePlayButton()
                        } label: {
                            ControlButton(imageName: recorderVM.isPlaying ? "pause.circle" : "play.circle", height: geo.size.height * 0.8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        
                        Button {
                            recorderVM.handleRecordButton()
                        } label: {
                            if recorderVM.isRecording {
                                ControlButton(imageName: "stop.circle", height: geo.size.height * 0.8)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.primary, .red)
                            } else {
                                ControlButton(imageName: "record.circle", height: geo.size.height * 0.8)
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
                        ControlButton(imageName: "forward.fill", height: geo.size.height * 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    if !recorderVM.isRecording,
                       recorderVM.isWaitingForUpload {
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
                            Text("Upload Explanation".localized())
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


