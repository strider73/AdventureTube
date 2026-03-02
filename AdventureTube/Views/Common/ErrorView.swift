import SwiftUI

struct ErrorView: View {
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("OK") {
                dismiss()
            }
            .withDefaultButtonFormatting()
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
