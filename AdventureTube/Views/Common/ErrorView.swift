import SwiftUI

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack {
            Text("Error")
                .font(.headline)
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
            Button("OK") {
                // Dismiss the error view
                // Use environment dismiss if needed
            }
        }
        .padding()
    }
}
