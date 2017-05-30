//
//  ViewController.swift
//  ichat
//
//  Created by guoxiaotian on 2017/5/15.
//  Copyright © 2017年 guoxiaotian. All rights reserved.
//

import UIKit
import SocketIO
import SwiftyJSON
import AVFoundation

class ChatViewController: UIViewController,RTCSessionDescriptionDelegate,RTCPeerConnectionDelegate,RTCEAGLVideoViewDelegate,AMapLocationManagerDelegate{
    
    let VIDEO_TRACK_ID = "ChatViewControllerVIDEO"
    let AUDIO_TRACK_ID = "ChatViewControllerAUDIO"
    let LOCAL_MEDIA_STREAM_ID = "ChatViewControllerSTREAM"
    
    var nowUser:User = LoginHelper.getLogUser();
    
    var locationManager:AMapLocationManager?
    
    var isLogin = false;
    var connectedUser:String?
    var mediaStream: RTCMediaStream!
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var renderer: RTCEAGLVideoView!
    var renderer_sub: RTCEAGLVideoView!
    var roomName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = AMapLocationManager()
        self.locationManager?.delegate = self;
        self.locationManager?.startUpdatingLocation()
        
        // Do any additional setup after loading the view, typically from a nib.
        initWebRTC();
        sigConnect(ApiConstant.SOCKET_IO_URL);
        
        renderer = RTCEAGLVideoView(frame: self.view.frame)
        renderer_sub = RTCEAGLVideoView(frame: CGRect(x: 20, y: 50, width: 90, height: 120))
        self.view.addSubview(renderer)
        self.view.addSubview(renderer_sub)
        renderer.delegate = self;
        self.initBtns()
        
        guard let device = AVCaptureDevice.defaultDevice(
            withDeviceType: .builtInWideAngleCamera,
            mediaType: AVMediaTypeVideo,
            position: .front)
            else {
                fatalError("no front camera. but don't all iOS 10 devices have them?")
        }
        
        let capturer = RTCVideoCapturer(deviceName: device.localizedName)
        
        
        let videoConstraints = RTCMediaConstraints()
        
        _ = RTCMediaConstraints()
        
        let videoSource = peerConnectionFactory.videoSource(with: capturer, constraints: videoConstraints)
        localVideoTrack = peerConnectionFactory.videoTrack(withID: VIDEO_TRACK_ID, source: videoSource)
        //            AudioSource audioSource = peerConnectionFactory.createAudioSource(audioConstraints)
        localAudioTrack = peerConnectionFactory.audioTrack(withID: AUDIO_TRACK_ID)
        
        mediaStream = peerConnectionFactory.mediaStream(withLabel: LOCAL_MEDIA_STREAM_ID)
        mediaStream.addVideoTrack(localVideoTrack)
        mediaStream.addAudioTrack(localAudioTrack)
        
        localVideoTrack.add(renderer_sub)
        
    }
    
    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!) {
        NSLog("location:{lat:\(location.coordinate.latitude); lon:\(location.coordinate.longitude); accuracy:\(location.horizontalAccuracy)};");
        
        let locationData:Dictionary = [
            "type":"loc",
            "lat":location.coordinate.latitude,
            "lon":location.coordinate.longitude
        ] as [String : Any]
        print("send location")
        self.sigSend(locationData as Dictionary<String, AnyObject>)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        RTCPeerConnectionFactory.deinitializeSSL()
    }
    func Log(_ value:String) {
        //print(TAG + " " + value)
    }
    func initBtns() -> Void {
        let leaveButton = UIButton(frame: CGRect(x: 20, y: 500, width: 44, height: 44))
        leaveButton.backgroundColor = UIColor.red
        leaveButton.addTarget(self, action: #selector(leave), for: .touchUpInside)
        leaveButton.setTitle("挂断", for: .normal)
        self.view.addSubview(leaveButton)
    }
    func leave() {
        let json:[String: AnyObject] = [
            "type" : "leave" as AnyObject
        ]
        sigSend(json as Dictionary);
        self.leaveAction()
    }
    
    func leaveAction() -> Void {
        self.locationManager?.stopUpdatingLocation()
        mediaStream.removeAudioTrack(localAudioTrack)
        mediaStream.removeVideoTrack(localVideoTrack)
        mediaStream = nil;
        self.remoteVideoTrack.remove(self.renderer)
        self.localVideoTrack.remove(self.renderer_sub)
        self.localVideoTrack = nil;
        self.renderer_sub.renderFrame(nil)
        self.remoteVideoTrack = nil
        self.renderer.renderFrame(nil)

        self.dismiss(animated: true) { 
            self.socket.disconnect()
        }
    }
    
    
    // webrtc
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var peerConnection: RTCPeerConnection! = nil
    var pcConstraints: RTCMediaConstraints! = nil
    var videoConstraints: RTCMediaConstraints! = nil
    var audioConstraints: RTCMediaConstraints! = nil
    var mediaConstraints: RTCMediaConstraints! = nil
    
    var socket: SocketIOClient! = nil
    var wsServerUrl: String! = nil
    var peerStarted: Bool = false
    
    
    func initWebRTC() {
        RTCPeerConnectionFactory.initializeSSL()
        peerConnectionFactory = RTCPeerConnectionFactory()
        
        pcConstraints = RTCMediaConstraints()
        videoConstraints = RTCMediaConstraints()
        audioConstraints = RTCMediaConstraints()
        mediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                RTCPair(key: "OfferToReceiveAudio", value: "true"),
                RTCPair(key: "OfferToReceiveVideo", value: "true")
            ],
            optionalConstraints: nil)
    }
    
    func connect() {
        if (!peerStarted) {
            sendOffer()
            peerStarted = true
        }
    }
    
    // websocket related operations
    func sigConnect(_ wsUrl:String) {
        wsServerUrl = wsUrl;
        
        Log("connecting to " + wsServerUrl)
        
        socket = SocketIOClient(socketURL: URL(string: wsUrl)!, config: [.log(false), .forcePolling(true)])
        socket.on("connect") { data in
            self.Log("WebSocket connection opened to: " + self.wsServerUrl);
            //            self.sigEnter();
            
            let loginData:Dictionary = [
                "type":"login",
                "name":self.nowUser.id
            ]
            self.sigSend(loginData as Dictionary<String, AnyObject>)
            
        }
        socket.on("disconnect") { data in
            self.Log("WebSocket connection closed.")
        }
        socket.on("webrtcMsg") { (data, emitter) in
            if (data.count == 0) {
                return
            }
            
            let jsonStr = data[0] as! String
            if let dataFromString = jsonStr.data(using: .utf8, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                print(json["type"]);
                
                let type = json["type"].string
                
                if( type == "login"){
                    
                    self.isLogin = true
//                    self.connectedUser = "590c398b25ac4f13707a0c9a";
                    self.connect()
                    
                }else if (type == "offer") {
                    let sdpStr = json["answer"]["sdp"].string
                    
                    self.Log("Received offer, set offer, sending answer....");
                    let sdp = RTCSessionDescription(type: type, sdp: sdpStr)
                    
                    //                    let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                    self.onOffer(sdp!);
                    
                    
                } else if (type == "answer" && self.peerStarted) {
                    let sdpStr = json["answer"]["sdp"].string
                    self.Log("Received answer, setting answer SDP");
                    let sdp = RTCSessionDescription(type: type, sdp: sdpStr)
                    //                    let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                    self.onAnswer(sdp!);
                    
                    
                } else if (type == "candidate" && self.peerStarted) {
                    let candidateInfo = json["candidate"]
                    self.Log("Received ICE candidate...");
                    //                    print(candidateInfo["candidate"].string)
                    let candidate = RTCICECandidate(
                        mid: candidateInfo["sdpMid"].string,
                        index: candidateInfo["sdpMLineIndex"].int!,
                        sdp: candidateInfo["candidate"].string)
                    self.onCandidate(candidate!);
                    
                } else if (type == "user disconnected" && self.peerStarted) {
                    
                    self.Log("disconnected");
                    self.stop();
                    
                }else if(type == "leave"){
                    self.showLeaveAlert()
                }else {
                    self.Log("Unexpected WebSocket message: " + (data[0] as AnyObject).description);
                }
            }
            
        }
        socket.connect();
    }
    func showLeaveAlert() {
        let alert = UIAlertController(title: "提示",
                                      message: "对方已离开",
                                      preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "确定",
                                          style: UIAlertActionStyle.default,
                                          handler:{ (action: UIAlertAction) -> Void in
                                            self.leaveAction()
        })
        
        //        let cancelAction = UIAlertAction(title: "cancel",
        //                                         style: UIAlertActionStyle.cancel,
        //                                         handler:{ (action: UIAlertAction) -> Void in
        //                                            print("UIAlertController action :", action.title ?? "cancel");
        //        })
//        let destructiveAction = UIAlertAction(title: "拒绝",
//                                              style: UIAlertActionStyle.destructive,
//                                              handler:{ (action: UIAlertAction) -> Void in
//                                                print("UIAlertController action :", action.title ?? "cancel");
//        })
        
        
        alert.addAction(defaultAction);
        //        alert.addAction(cancelAction);
//        alert.addAction(destructiveAction);
        present(alert, animated: true, completion: {
            print("UIAlertController present");
        })
    }

    
    func onOffer(_ sdp:RTCSessionDescription) {
        setOffer(sdp)
        sendAnswer()
        peerStarted = true;
    }
    
    func onAnswer(_ sdp:RTCSessionDescription) {
        setAnswer(sdp)
    }
    
    func onCandidate(_ candidate:RTCICECandidate) {
        peerConnection.add(candidate)
    }
    
    func sendSDP(_ sdp:RTCSessionDescription) {
        
        if(sdp.type == "offer"){
            self.sendOfferInfo(sdp)
        }
    }
    
    func sendOfferInfo(_ sdp:RTCSessionDescription) -> Void {
        let offerInfo:Dictionary<String,AnyObject> = [
            "type":"offer" as AnyObject,
            "sdp":sdp.description as AnyObject
        ]
        let json:Dictionary<String,AnyObject> = [
            "type":"offer" as AnyObject,
            "offer":offerInfo as AnyObject
        ]
        sigSend(json)
    }
    
    func sendOffer() {
        peerConnection = prepareNewConnection();
        peerConnection.createOffer(with: self, constraints: mediaConstraints)
    }
    
    func setOffer(_ sdp:RTCSessionDescription) {
        if (peerConnection != nil) {
            Log("peer connection already exists")
        }
        peerConnection = prepareNewConnection();
        peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdp)
    }
    
    func sendAnswer() {
        Log("sending Answer. Creating remote session description...")
        if (peerConnection == nil) {
            Log("peerConnection NOT exist!")
            return
        }
        peerConnection.createAnswer(with: self, constraints: mediaConstraints)
    }
    
    func setAnswer(_ sdp:RTCSessionDescription) {
        if (peerConnection == nil) {
            Log("peerConnection NOT exist!")
            return
        }
        peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdp)
    }
    func sendDisconnect() {
        let json:[String: AnyObject] = [
            "type" : "user disconnected" as AnyObject
        ]
        sigSend(json as Dictionary);
    }
    func stop() {
        if (peerConnection != nil) {
            peerConnection.close()
            peerConnection = nil
            peerStarted = false
        }
    }
    func prepareNewConnection() -> RTCPeerConnection {
        let icsServers: [RTCICEServer] = []
        let rtcConfig: RTCConfiguration = RTCConfiguration()
        rtcConfig.tcpCandidatePolicy = RTCTcpCandidatePolicy.disabled
        rtcConfig.bundlePolicy = RTCBundlePolicy.maxBundle
        rtcConfig.rtcpMuxPolicy = RTCRtcpMuxPolicy.require
        
        peerConnection = peerConnectionFactory.peerConnection(withICEServers: icsServers, constraints: pcConstraints, delegate: self)
        peerConnection.add(mediaStream);
        return peerConnection;
    }
    func sigSend(_ msg:Dictionary<String,AnyObject>) {
        var sendMsg = msg;
//        if(self.connectedUser != nil){
//            sendMsg["name"]  = self.connectedUser as AnyObject
//        }
        
        if (isLogin) {
            if let connectTo = self.connectedUser {
                sendMsg["name"]  = connectTo as AnyObject
            }
        }
        let str = JSON(sendMsg).rawString()
        socket.emit("webrtcMsg", str!)
        


    }
    
    func getRoomName() -> String {
        return (roomName == nil || roomName.isEmpty) ? "_defaultroom": roomName;
    }
    
    func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        if (peerConnection == nil) {
            return
        }
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            Log("Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.setEnabled(true)
            remoteVideoTrack.add(renderer);
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        if (candidate != nil) {
            Log("iceCandidate: " + candidate.description)
            //            let json:[String: AnyObject] = [
            //                "type" : "candidate" as AnyObject,
            //                "sdpMLineIndex" : candidate.sdpMLineIndex as AnyObject,
            //                "sdpMid" : candidate.sdpMid as AnyObject,
            //                "candidate" : candidate.sdp as AnyObject
            //            ]
            //            let candidateData = [
            //                "type":"candidate",
            //                "candidate":candidate
            //            ] as [String : Any]
            //
            let candidateInfo:Dictionary<String,AnyObject> = [
                "sdpMLineIndex" : candidate.sdpMLineIndex as AnyObject,
                "sdpMid" : candidate.sdpMid as AnyObject,
                "candidate" : candidate.sdp as AnyObject
            ]
            let candidateData:Dictionary<String,AnyObject> = [
                "type":"candidate" as AnyObject,
                "candidate":candidateInfo as AnyObject
            ]
            
            sigSend(candidateData)
        } else {
            Log("End of candidates. -------------------")
        }
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        remoteVideoTrack = nil
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
        
    }
    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        if (error == nil) {
            peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
            Log("Sending: SDP")
            Log(sdp.description)
            sendSDP(sdp)
        } else {
            Log("sdp creation error: ")
        }
        
    }
    func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        
    }
    
    
    
}

