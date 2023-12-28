//
//  ControlPanel.swift
//  VerseRecorder
//
//  Created by Nursultan Askarbekuly on 08.12.2023.
//

import SwiftUI

@available(iOS 15.0, *)
struct PlayerPanel: View {
    
    @StateObject var mushafVM: MushafViewModel
    @StateObject var recorderVM: RecorderViewModel
    
    var body: some View {
        HStack(alignment: .bottom) {
            Button {
                
                if let firstAyahInRange = mushafVM.currentRange.first,
                   let lastAyahInRange = mushafVM.currentRange.last {
                    recorderVM.handleRecordButton(start: firstAyahInRange.id, end: lastAyahInRange.id)
                    mushafVM.setRectanglesForCurrentRange()
                }
                
            } label: {
                Image(systemName: recorderVM.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: .systemGreen))
                    .font(.system(size: 20, weight: .ultraLight))
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
            
            VStack(alignment: .center) {
                
                HStack {
                    if !recorderVM.infoMessage.isEmpty && mushafVM.infoMessage == mushafVM.standardMessage {
                        Text(recorderVM.infoMessage)
                            .font(.footnote)
                    } else {
                        if mushafVM.infoMessage == mushafVM.standardMessage {
                            Image(systemName: "waveform")
                                .font(.footnote)
                        }
                        
                        Text(mushafVM.infoMessage)
                            .font(.footnote)
                    }
                }
                
                HStack(spacing: 6) {
                    
                    Button {
                        /// show modal view
                        mushafVM.showNavigation = true
                    } label: {
                        Image(systemName: "list.bullet.circle")
                            .resizable()
                            .scaledToFit()
                            .font(.system(size: 16, weight: .ultraLight))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $mushafVM.showNavigation) {
                        ListView(mushafVM: mushafVM, recorderVM: recorderVM)
                    }
                    
                    if mushafVM.isPlaying {
                    
                        Button {
                            mushafVM.handleRepeatButton()
                            print("repeat tapped")
                        } label: {
                            Image(systemName: mushafVM.isRepeatOn ? "repeat.circle.fill" : "repeat.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 32, height: 32)
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
                                .frame(width: 32, height: 32)
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
                                .frame(width: 32, height: 32)
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
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    } else {
                        
                        Spacer().frame(width: 32)
                        
                        Button {
                            print("Next range")
                            mushafVM.handleNextRangeButton()
                        } label: {
                            Image(systemName: "chevron.left.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 32, height: 32)
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
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer().frame(width: 32)
                                                
                    }
                    
                    if recorderVM.isRecording {
                        Button {
                            mushafVM.isHidden.toggle()
                            print("hide tapped:", mushafVM.isHidden)
                        } label: {
                            Image(systemName: mushafVM.isHidden ? "eye.slash.circle.fill" : "eye.slash.circle")
                                .resizable()
                                .scaledToFit()
                                .font(.system(size: 16, weight: .ultraLight))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Spacer().frame(width: 32)
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
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}
