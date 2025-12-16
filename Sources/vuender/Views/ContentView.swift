import SwiftUI

struct ContentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(count)")
                .font(.system(size: 48, weight: .bold))
                .padding()
            
            HStack(spacing: 20) {
                Button(action: {
                    count -= 1
                }) {
                    Text("-")
                        .font(.system(size: 32, weight: .bold))
                        .frame(width: 60, height: 60)
                }
                
                Button(action: {
                    count += 1
                }) {
                    Text("+")
                        .font(.system(size: 32, weight: .bold))
                        .frame(width: 60, height: 60)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

