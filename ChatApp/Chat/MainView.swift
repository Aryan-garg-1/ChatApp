import SwiftUI
import MultipeerConnectivity

var lastSender: String = ""

struct ChatMessage: View {
    let chat: [MessageElementType]?
    let message: MessageElementType
    @EnvironmentObject var userName: UserName
    
    var body: some View {
        VStack(spacing: 3.0) {
            
            Bubble(direction: !message.isSelf ? .left:.right) {
                Text(message.msg)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(message.isSelf == false ? Color(red: 0.416, green: 0.416, blue: 0.416):.blue)
            }
            
            if let ndx = chat?.firstIndex(where: {$0.id == message.id}) {
                if ndx + 1 < chat!.count {
                    let nextMessage = chat?[ndx + 1]
                    if !message.isSelf && nextMessage!.senderUUID != message.senderUUID {
                        HStack {
                            Spacer().frame(maxWidth: 6.0)
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text(message.senderName)
                                .padding(.leading, -6)
                            Spacer()
                        }.frame(maxHeight: 10.0)
                    }
                } else {
                    if !message.isSelf {
                        HStack {
                            Spacer().frame(maxWidth: 6.0)
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text(message.senderName)
                                .padding(.leading, -6)
                            Spacer()
                        }.frame(maxHeight: 10.0)
                    }
                }
            }
        }
    }
}


struct MainView: View {
    @StateObject var chatSession = ChatMultipeerSession()
    @EnvironmentObject var userName: UserName
    
    @State var showModal: Bool = false

    @State var settingsShown: Bool = false
    @State var infoShown: Bool = false
    
    @State var currentMsg: String = ""
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                VStack(alignment: .leading) {
                    Divider()
                    
                    ScrollView {
                        ForEach(chatSession.chatMessages ?? [], id:\.self) { message in
                            ChatMessage(chat: chatSession.chatMessages, message: message)
                        }
                    }
                    .frame(width: proxy.size.width - 20)
                    
                    Spacer()
                    Divider()
                    Spacer().frame(height: 13.0)
                    
                    BottomField(proxy: proxy, currentMsg: $currentMsg, sendProcedure: {
                        if currentMsg == "" {
                            return
                        }
                        
                        chatSession.send(msg: currentMsg)
                        currentMsg = ""
                    })
                    
                }
                .padding()
                .navigationTitle("Nearby Broadcast")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            Image(systemName: "iphone.gen2.radiowaves.left.and.right.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.accentColor)
                                .frame(width: 28.0)
                            
                            Text("\(chatSession.connectedPeers.count)")
                                .font(.system(size: 20))
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing){
                        VStack{
                            Button("𑗊") {
                                showModal.toggle()
                            }.sheet(isPresented: $showModal) {
                                    Name(user: userName, showModal: $showModal)
                                }

                        }
                    }

                }
                
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
