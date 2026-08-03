import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.brandPurple.ignoresSafeArea()
            Text("GoHomeNow")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
