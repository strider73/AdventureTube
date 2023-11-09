//
//  ViewUtility.swift
//  Momentale
//
//  Created by chris Lee on 27/10/21.
//https://www.avanderlee.com/swiftui/conditional-view-modifier/
//

import Foundation
import SwiftUI
/**
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


extension View {
    func Print(_ vars: Any...) -> some View {
        for v in vars { print(v) }
        return EmptyView()
    }
}
*/

//Button Modifier
struct LoginButton : ViewModifier {
    
    func body(content: Content) -> some View {
        content.padding(EdgeInsets(top: 10, leading:10, bottom: 10, trailing: 10))
    }
}

struct ConfirmedLocationButton : ViewModifier  {
    func body(content: Content) -> some View {
        content
            .frame(width:35 , height: 35)
            .foregroundColor(Color.red)
            .withPressableStyle(scaledAmount: 0.3)

    }
}

struct  CustomNavButton : ViewModifier {
    
    @State var color : Color
    func body(content: Content) -> some View {
        content
            .frame(width:30 , height: 30)
            .foregroundColor(color)
        
    }
}

struct  UploadNavButton : ViewModifier {
    
    @State var color : Color
    func body(content: Content) -> some View {
        content
            .frame(width:30 , height: 30)
            .foregroundColor(color)
        
    }
}

struct CategoryButtonModifier : ViewModifier{
    func body(content: Content) -> some View {
        content
            .cornerRadius(10)
            .withPressableStyle(scaledAmount: 0.3)
             
    }
}
//Its not using
struct  CustomRectangleTextButton : ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .frame(width:100 , height: 30)
            .foregroundColor(Color.black)
            .background(.gray)
        
    }
}


struct DefaultButtonViewModifier: ViewModifier {
    
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(ColorConstant.foreground.color)
            .cornerRadius(10)
            .shadow(radius: 10)
    }
}




extension View {
    //Busttons
    
    
    func confirmedLocationButton() -> some View {
        modifier(ConfirmedLocationButton())
    }
    func categorybutton() -> some View {
        modifier(CategoryButtonModifier())
    }
    
    func loginButton() -> some View{
        modifier(LoginButton())
    }
   
    func customNavButton(color: Color = Color.black) -> some View {
        modifier(CustomNavButton(color: color))
    }
    

    func uploadNavButton(color: Color = Color.black) -> some View {
        modifier(UploadNavButton(color: color))
    }
    
    
    func customRetangleTextButton() -> some View {
        modifier(CustomRectangleTextButton())
    }

    
    func withPressableStyle(scaledAmount: CGFloat = 0.9) -> some View {
        buttonStyle(PressableButtonStyle(scaledAmount: scaledAmount))
    }
    
    func withDefaultButtonFormatting(backgroundColor: Color = .blue) -> some View {
        modifier(DefaultButtonViewModifier(backgroundColor: backgroundColor))
    }
}


struct PressableButtonStyle: ButtonStyle {
    
    let scaledAmount: CGFloat
    
    init(scaledAmount: CGFloat) {
        self.scaledAmount = scaledAmount
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaledAmount : 1.0)
            //.brightness(configuration.isPressed ? 0.05 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
    
}
