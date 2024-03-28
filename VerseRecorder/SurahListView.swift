//
//  SurahListView.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 08.01.2024.
//

import SwiftUI

@available(iOS 15.0, *)
public class QuranMetaViewModel: ObservableObject {
    
    @Published var surahReferences: [SurahsReference] = []
    @Published var surahs: [Surah] = []
    @Published var rangeRecordings: [RangeRecording] = []
    @Published var selectedSegment: Segment = .surahs
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSurah: Surah? = nil
    
    enum Segment {
        case surahs, recordings
    }
    
    init() {
        self.rangeRecordings = RecordingStorage.shared.getRecordingRanges()
        Task {
            DispatchQueue.main.async {
                self.isLoading = true
            }
            await loadMeta()
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
    }
    
    
    func loadMeta() async {
        do {
            let meta = try await ContentStorage.shared.fetchMeta()
            let surahs = meta.data.surahs.references.filter({$0.number == 1 || $0.number >= 78}).compactMap({ ContentStorage.shared.surahs[$0.id] })
            DispatchQueue.main.async {
                self.surahs = surahs
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

@available(iOS 15.0.0, *)
public struct SurahListView: View {
    
    private let title: String
    public var clientStorage: ClientStorage
    @StateObject private var viewModel = QuranMetaViewModel()
    
    
    public init(title: String, clientStorage: ClientStorage) {
        self.title = title
        self.clientStorage = clientStorage
    }
    
    public var body: some View {
        
        NavigationView {
            
            VStack {
                Picker("Segment", selection: $viewModel.selectedSegment) {
                    Text("Surahs".localized()).tag(QuranMetaViewModel.Segment.surahs)
                    Text("My recordings".localized()).tag(QuranMetaViewModel.Segment.recordings)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch viewModel.selectedSegment {
                case .surahs:
                    Text("Pick a surah to record".localized())
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    } else {
                        List(viewModel.surahs, id: \.id) { surah in
                            
                            NavigationLink(
                                destination: surah == viewModel.selectedSurah ? RecorderView(range: surah, clientStorage: clientStorage) : nil,
                                tag: surah,
                                selection: $viewModel.selectedSurah
                            ) {
                                VStack(alignment: .leading) {
                                    Text(surah.name)
                                        .font(.headline)
                                    Text("\(surah.number). " + surah.englishName)
                                        .font(.subheadline)
                                }
                            }
                            
                        }
                    }
                case .recordings:
                    List {
                        ForEach(viewModel.rangeRecordings, id: \.id) { recording in
                            
                            if let surah = ContentStorage.shared.surahs[recording.audioId] {
                            NavigationLink {
                                
                                    RecorderView(range: surah, clientStorage: clientStorage, recording: recording)
                                
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(surah.title)
                                        .font(.headline)
                                    Text(String(describing: recording.date))
                                        .font(.subheadline)
                                }
                            }
                            }

                        }

                    }
                }
            }
            .navigationTitle(title)
        }
    }
}
