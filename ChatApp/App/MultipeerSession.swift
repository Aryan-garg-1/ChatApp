import MultipeerConnectivity
import os

struct MessageElementType: Identifiable, Hashable, Codable {
    
    var id = UUID()
    
    var senderName: String
    var senderUUID: String
    
    var isSelf: Bool = false
    var msg: String
}

class ChatMultipeerSession: NSObject, ObservableObject {

    var userName = UserName()
    private let serviceType = "nearby-chat"
    
    private let session: MCSession
    private let myPeerId = MCPeerID(displayName: UIDevice.current.localizedModel)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let log = Logger()
    
    @Published var chatMessages: [MessageElementType]? = []
    @Published var connectedPeers: [MCPeerID] = []
    
    override init() {
        precondition(Thread.isMainThread)
        self.session = MCSession(peer: myPeerId)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(msg: String) {
        precondition(Thread.isMainThread)
        log.info("sendMessage: \(String(describing: msg)) to \(self.session.connectedPeers.count) peers")
        
        let messageToSend = MessageElementType(senderName: userName.savedText, senderUUID: UIDevice.current.identifierForVendor!.uuidString, isSelf: false, msg: msg)
        let messageToStore = MessageElementType(senderName: userName.savedText, senderUUID: UIDevice.current.identifierForVendor!.uuidString, isSelf: true, msg: msg)
        
        self.chatMessages?.append(messageToStore)
        
        if !session.connectedPeers.isEmpty {
            do {
                let jsonData = try JSONEncoder().encode(messageToSend)
                let jsonString = String(data: jsonData, encoding: .utf8)!
                
                try session.send(jsonString.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                log.error("Error for sending: \(String(describing: error))")
            }
        }
    }
}

extension ChatMultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        precondition(Thread.isMainThread)
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        precondition(Thread.isMainThread)
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}

extension ChatMultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}

extension ChatMultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.debugDescription)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(MessageElementType.self, from: data)
            
            if let msg = String(data: data, encoding: .utf8) {
                log.info("didReceive chat msg \(msg)")
                
                
                DispatchQueue.main.async {
                    self.chatMessages?.append(message)
                }
            } else {
                log.info("didReceive invalid value \(data.count) bytes")
            }
        } catch { print(error) }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}

extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        @unknown default:
            return "\(rawValue)"
        }
    }
}
