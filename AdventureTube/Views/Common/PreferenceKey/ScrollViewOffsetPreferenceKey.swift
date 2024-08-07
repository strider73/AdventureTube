import SwiftUI



struct OnReachBottomModifier: ViewModifier {
    let action: () -> Void
    @State private var viewHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).maxY)
                }
            )
//            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { maxY in
////                let screenHeight = UIScreen.main.bounds.height
////                if maxY < screenHeight * 1.1 { // Adjust the threshold as needed
////                    action()
////                }
//                
//                action()
//            }
    }
}
struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

extension View {
    func onReachBottom(perform action: @escaping () -> Void) -> some View {
        self.modifier(OnReachBottomModifier(action: action))
    }
}

