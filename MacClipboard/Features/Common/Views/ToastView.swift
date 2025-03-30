import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.75))
            .foregroundColor(.white)
            .cornerRadius(10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 20)
    }
} 