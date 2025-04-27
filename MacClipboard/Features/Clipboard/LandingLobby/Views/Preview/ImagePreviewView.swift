import SwiftUI

struct ImagePreviewView: View {
    let imageData: Data
    
    var body: some View {
        if let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .padding()
        }
    }
} 