import SwiftUI

struct SplashScreenView : View {
    var body: some View {
        ZStack {
            
            AnimatedMenuBackground()
            
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }
}
