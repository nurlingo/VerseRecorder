//
//  ListView.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 08.12.2023.
//

import SwiftUI

@available(iOS 15.0, *)
struct ListView: View {
    
    @StateObject var mushafVM: MushafViewModel
    @StateObject var recorderVM: RecorderViewModel
    
    @State private var showShareSheet = false
    
    @State private var selectedList: ListType = {
        if let rawValue = Storage.shared.retrieve(forKey: "selectedList") as? String,
           let listType = ListType(rawValue: rawValue) {
            return listType
        } else {
            return .surah
        }
    }()
    
    enum ListType: String {
        case current, surah
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("List Type", selection: $selectedList) {
                    Text("Surahs").tag(ListType.surah)
                    Text("My recordings").tag(ListType.current)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List {
                    if selectedList == .surah {
                        let sortedSurahNumbers = SurahNames.juzAmma.keys.sorted()
                        ForEach(sortedSurahNumbers, id: \.self) { surahNumber in
                            Button(action: {
                                mushafVM.currentSurahIndex = sortedSurahNumbers.firstIndex(of: surahNumber) ?? 0
                                mushafVM.showNavigation = false
                            }) {
                                HStack {
                                    Text("\(surahNumber). \(SurahNames.juzAmma[surahNumber]!.1)")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onAppear {
                            Storage.shared.store(selectedList.rawValue, forKey: "selectedList")
                        }
                    } else {
                        ForEach(RecordingStorage.shared.getRecordings()) { recording in
                            
                            HStack(alignment: .center) {
                                Button(action: {
                                    print(recording.start)
                                    if recorderVM.isPlaying,
                                       let activeRecording = recorderVM.activeRecording,
                                       activeRecording.id == recording.id {
                                        recorderVM.pausePlayer()
                                    } else {
                                        recorderVM.playRecording(recording)
                                    }
                                    
                                }) {
                                    
                                    HStack(alignment: .center) {
                                        
                                        if recorderVM.isPlaying,
                                           let activeRecording = recorderVM.activeRecording,
                                           activeRecording.id == recording.id {
                                            Image(systemName: "pause")
                                        } else {
                                            Image(systemName: "waveform")
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(recording.title)
                                            Spacer().frame(height: 4)
                                            Text(String(describing: recording.description))
                                                .font(.caption)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                                
                                Button(action: {
                                    print(recording.start)
                                    showShareSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .buttonStyle(PlainButtonStyle())
                                .sheet(isPresented: $showShareSheet) {
                                    ShareSheet(itemsToShare: [recording.url])
                                }
                                
                            }
                        }
                        .onAppear {
                            Storage.shared.store(selectedList.rawValue, forKey: "selectedList")
                        }
                    }
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                mushafVM.showNavigation = false
            })
        }
    }
    
}

@available(iOS 13.0, *)
struct ShareSheet: UIViewControllerRepresentable {
    var itemsToShare: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
