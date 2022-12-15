//
//  Name.swift
//  ChatApp
//
//  Created by Aryan Garg on 13/12/22.
//

import SwiftUI


class UserName: ObservableObject{
    
    @Published var name = "Anonymous"
    @AppStorage("STRING_KEY") var savedText = ""
}

struct Name: View {
    
    @ObservedObject var user : UserName
    @Binding var showModal: Bool
    
    var body: some View {
            VStack{
                Button("❌") {
                    showModal.toggle()
                }.position(x:370,y:20)
                
                TextField("Type Your Name", text: $user.name)
                    .textFieldStyle(.roundedBorder)
                    .font (.title)
                    .disableAutocorrection(true)
                    .position(x:200)
                
                Button("Save"){
                        self.user.savedText = user.name
                        showModal.toggle()
                }
                .frame(width: 200, height: 50)
                    .cornerRadius(20)
                .font(.system(size: 30))
                .buttonStyle(.bordered)
                .position(x:200,y:-100)
            }

            }
    }

struct Name_Previews: PreviewProvider {
    static var previews: some View {
        Name(user: UserName(), showModal: .constant(false))
    }
}
