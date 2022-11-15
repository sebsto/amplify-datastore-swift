//
//  CircularProgressView.swift
//  SwiftAnimation
//
//  Created by Stormacq, Sebastien on 12/11/2022.
//

import SwiftUI

// inspired by https://sarunw.com/posts/swiftui-circular-progress-bar/
struct CircularProgressView: View {
    
    let strokeWidth : CGFloat
    let text: String
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .stroke( // 1
                        .tint.opacity(0.5),
                        lineWidth: strokeWidth
                    )
                Circle() // 2
                    .trim(from: 0, to: 0.25) // 1
                
                    .stroke(
                        .tint,
                        style: StrokeStyle(
                            lineWidth: 0.75 * strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isLoading)
            }
            .padding()
            
            Text(text)
                .font(.title)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .lineLimit(1)
        }
        .onAppear() {
            self.isLoading = true
        }
    }
    
//    func animate() -> some View {
//        self.isLoading = true
//        return self
//    }
}


struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressView(strokeWidth : 40, text: "Loading...")
//            .animate()
            .padding()
        
    }
}
