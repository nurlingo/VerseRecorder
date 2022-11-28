//
//  ControlButton.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct ControlButton: View {
    
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
