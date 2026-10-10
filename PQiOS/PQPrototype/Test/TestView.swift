
import SwiftUI

struct TestView: View {
    
    var body: some View{
        VStack{
            Rectangle().foregroundColor(.red)
            NavigationView{
                NavigationLink {
                    Rectangle().foregroundColor(.yellow)
                } label: {
                    Rectangle().foregroundColor(.blue)
                }
            }.navigationBarHidden(true)
                .navigationBarBackButtonHidden()
            Rectangle().foregroundColor(.green)
        }
    }
}

#Preview {
    TestView()
}
