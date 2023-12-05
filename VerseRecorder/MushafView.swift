
//
//  MushafView.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 16.09.2023.
//

import SwiftUI

public enum MushafPublication {
    case hafsMadinan
    case qaloonMadinan
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
            Text(mushafVM.rangeString)
                .font(.headline)
            Spacer()
            Text("p. " + String(mushafVM.pages[mushafVM.currentPageIndex]))
        }
        .padding(16)
        
        TabView(selection: $mushafVM.currentPageIndex) {
            ForEach(0..<mushafVM.pages.count, id: \.self) { index in
                GeometryReader { geometry in
                    Image(String(mushafVM.pages[index])) // Replace with the name of your image asset
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            imageSize = CGSize(width: geometry.size.width, height: geometry.size.height)
                            //                            print("Image size: \(imageSize)")
                        }
                        .overlay(
                            ForEach(mushafVM.ayahRectangles) { rectangle in
                                Rectangle()
                                    .fill(!mushafVM.isPlaying && mushafVM.isHidden ? Color(uiColor: . systemBackground) : Color.yellow) // Change color as needed
                                    .opacity(!mushafVM.isPlaying && mushafVM.isHidden ? 1 : 0.1) // Change opacity as needed
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
        
        PlayerPanel(mushafVM: mushafVM)
            .frame(height: 50)
            .onDisappear {
                mushafVM.resetPlayer()
                mushafVM.resetRecorder()
            }
        
    }
    
}


@available(iOS 15.0, *)
struct PlayerPanel: View {
    
    @StateObject var mushafVM: MushafViewModel
    
    var body: some View {
        HStack(alignment: .center) {
            //            Button {
            //                mushafVM.handleRecordButton()
            //            } label: {
            //                Image(systemName: mushafVM.isRecording ? "stop.circle.fill" : "mic.circle.fill")
            //                    .resizable()
            //                    .scaledToFit()
            //                    .foregroundColor(Color(uiColor: .systemGreen))
            //                    .font(.system(size: 20, weight: .ultraLight))
            //                    .frame(width: 60, height: 60)
            //            }
            //            .buttonStyle(PlainButtonStyle())
            //            Spacer()
            
            VStack(alignment: .center) {
                
                HStack(spacing: 12) {
                    //                    if !mushafVM.isRecording,
                    //                       let activeRecording = mushafVM.activeRecording,
                    //                       mushafVM.recordingExists(activeRecording.uid.uuidString) {
                    //                        Button {
                    //                            mushafVM.handlePlayRecordingButton()
                    //                        } label: {
                    //                            Image(systemName: mushafVM.isPlaying ? "stop.circle" : "play.circle")
                    //                                .resizable()
                    //                                .scaledToFit()
                    //                                .font(.system(size: 16, weight: .ultraLight))

                    //                                .frame(width: 45, height: 45)
                    //                        }
                    //                        .buttonStyle(PlainButtonStyle())
                    //                    }
                    
                    if mushafVM.isPlaying {
                        Button {
                            mushafVM.handleRepeatButton()
                            print("repeat tapped")
                        } label: {
                            Image(systemName: mushafVM.isRepeatOn ? "repeat.circle.fill" : "repeat.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            mushafVM.handleNextButton()
                            print("forward tapped!")
                        } label: {
                            Image(systemName: "backward.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        
                        Button {
                            mushafVM.handlePreviousButton()
                            print("backward tapped!")
                        } label: {
                            Image(systemName: "forward.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            mushafVM.handleSpeedButton()
                            print("speed tapped:", mushafVM.speed)
                        } label: {
                            Image(systemName: "speedometer")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        
                        Button {
                            /// show modal view
                            mushafVM.showNavigation = true
                        } label: {
                            Image(systemName: "list.bullet.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $mushafVM.showNavigation) {
                                    NavigationListView(mushafVM: mushafVM)
                                }
                        
                        Button {
                            print("Next range")
                            mushafVM.handleNextRangeButton()
                        } label: {
                            Image(systemName: "chevron.left.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            print("Previous range")
                            mushafVM.handlePreviousRangeButton()
                        } label: {
                            Image(systemName: "chevron.right.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            mushafVM.isHidden.toggle()
                            print("hide tapped:", mushafVM.isHidden)
                        } label: {
                            Image(systemName: mushafVM.isHidden ? "eye.slash.circle.fill" : "eye.slash.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        
                    }
                }
                Text(mushafVM.infoMessage)
            }
            
            Spacer()
            
            Button {
                mushafVM.handlePlayButton()
            } label: {
                Image(systemName: mushafVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: .systemBlue))
                    .font(.system(size: 20, weight: .ultraLight))
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(x: -1, y: 1)
            
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}


@available(iOS 15.0, *)
struct NavigationListView: View {
    
    @StateObject var mushafVM: MushafViewModel
    
    var body: some View {
        NavigationView {
            List {
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
            }
            .navigationBarTitle("Surahs", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                // Code to dismiss the view
            })
        }
    }
}
