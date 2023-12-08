
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
    @ObservedObject private var recorderVM: RecorderViewModel
    
    
    public init(mushafVM: MushafViewModel, recorderVM: RecorderViewModel) {
        self.mushafVM = mushafVM
        self.recorderVM = recorderVM
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
                                    .fill(!mushafVM.isPlaying && mushafVM.isHidden ? Color(uiColor: .systemBackground) : Color(uiColor: .systemYellow)) // Change color as needed
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
        
        PlayerPanel(mushafVM: mushafVM, recorderVM: recorderVM)
            .frame(height: 50)
            .onDisappear {
                mushafVM.resetPlayer()
                recorderVM.resetRecorder()
            }
        
    }
    
}
