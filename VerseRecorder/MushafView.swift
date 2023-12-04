
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
        98: ("البينة", "Al-Bayyinah"),
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
        Text(String(mushafVM.pages[mushafVM.currentPage]))
        
        TabView(selection: $mushafVM.currentPage) {
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
                                    .opacity(!mushafVM.isPlaying && mushafVM.isHidden ? 1 : 0.2) // Change opacity as needed
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
        HStack(alignment: .bottom) {
            Button {
                mushafVM.handleRecordButton()
            } label: {
                Image(systemName: mushafVM.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: .systemGreen))
                    .font(.system(size: 20, weight: .ultraLight))
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()

            VStack(alignment: .center) {
                
                Text(mushafVM.infoMessage)
                
                HStack{
//                    if !mushafVM.isRecording,
//                       let activeRecording = mushafVM.activeRecording,
//                       mushafVM.recordingExists(activeRecording.uid.uuidString) {
//                        Button {
//                            mushafVM.handlePlayRecordingButton()
//                        } label: {
//                            Image(systemName: mushafVM.isPlaying ? "stop.circle" : "play.circle")
//                                .resizable()
//                                .scaledToFit()
//                                .font(.system(size: 16, weight: .light))
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
                    } else {
                        
                        Button {
                            mushafVM.isRangeHighlighted.toggle()
                            print("highlight tapped:", mushafVM.isRangeHighlighted)
                        } label: {
                            Image(systemName: mushafVM.isRangeHighlighted ? "line.3.horizontal.circle.fill" : "line.3.horizontal.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .light))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            print("Previous range")
                            
                        } label: {
                            Image(systemName: "chevron.left.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .light))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            print("Next range")
                        } label: {
                            Image(systemName: "chevron.right.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .light))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            mushafVM.isHidden.toggle()
                            print("hide tapped:", mushafVM.isHidden)
                        } label: {
                            Image(systemName: mushafVM.isHidden ? "eye.slash.circle.fill" : "eye.slash.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .light))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                }
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
            
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}
