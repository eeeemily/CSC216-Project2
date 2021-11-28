//
//  ViewController.swift
//  CoreML-in-ARKit
//
//  Created by Yehor Chernenko on 01.08.2020.
//  Copyright © 2020 Yehor Chernenko. All rights reserved.
//

import UIKit
import Vision
import ARKit
import AVKit
import UIKit


class ViewController: UIViewController {
    var player:AVPlayer!
    var obejctName:String!
    var playerLooper: AVPlayerLooper?
    
   var objectDectionItems = ["truck","cell phone","cup","bowl","person"]
    
    var objectDetectionService = ObjectDetectionService()
    let throttler = Throttler(minimumDelay: 1, queue: .global(qos: .userInteractive))
    var isLoopShouldContinue = true
    var lastLocation: SCNVector3?

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.scene = SCNScene()
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        // Debug
//        sceneView.showsStatistics = true
//        sceneView.debugOptions = [.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopSession()
    }
    
    
    @IBAction func refreshView(_ sender: Any) {
        self.viewDidLoad()
        self.view.setNeedsDisplay();
        
    }
    
    private func startSession(resetTracking: Bool = false) {
        guard ARWorldTrackingConfiguration.isSupported else {
            assertionFailure("ARKit is not supported")
            return
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        if resetTracking {
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            sceneView.session.run(configuration)
        }
    }
    
    func stopSession() {
        sceneView.session.pause()
    }
    
    func loopObjectDetection() {
        throttler.throttle { [weak self] in
            guard let self = self else { return }
            
            if self.isLoopShouldContinue {
                self.performDetection()
            }
            self.loopObjectDetection()
        }
    }
    
    func performDetection() {
        guard let pixelBuffer = sceneView.session.currentFrame?.capturedImage else { return }
        
        objectDetectionService.detect(on: .init(pixelBuffer: pixelBuffer)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                let rectOfInterest = VNImageRectForNormalizedRect(
                    response.boundingBox,
                    Int(self.sceneView.bounds.width),
                    Int(self.sceneView.bounds.height))
                self.obejctName=response.classification
                self.addAnnotation(rectOfInterest: rectOfInterest,
                                   text: response.classification)
            
            case .failure(let error):
                break
            }
        }
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        player.seek(to: CMTime.zero)
        player.play()
    }
    // Remove Observer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addARTV(z: Float, item:String){
        if (player != nil){
            player?.replaceCurrentItem(with: nil)
        }
        //let fileURL=URL(fileURLWithPath:Bundle.main.path(forResource:"truck1",ofType:"mp4")!)
        let fileURL=URL(fileURLWithPath:Bundle.main.path(forResource:item,ofType:"mp4")!)
        player=AVPlayer(url:fileURL)
        //player .actionAtItemEnd = .none

        
        let tvGao=SCNPlane(width:0.15,height:0.1)
        tvGao.firstMaterial?.diffuse.contents=player
        tvGao.firstMaterial?.isDoubleSided=true
        
        let tvNode=SCNNode(geometry:tvGao)
        tvNode.position.z = z //change this
        sceneView.scene.rootNode.addChildNode(tvNode)
        
        //player.play()
    
      
        //player.pause()
        
        let playerLayer = AVPlayerLayer(player: player)
                // Register for notification
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(playerItemDidReachEnd),
                                                                 name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                                 object: nil) // Add observer

                playerLayer.frame = self.view.bounds
//                self.view.layer.addSublayer(playerLayer)
                player.play()
        
    }
    
    
    func addAnnotation(rectOfInterest rect: CGRect, text: String) {
        let point = CGPoint(x: rect.midX, y: rect.midY)
        
        let scnHitTestResults = sceneView.hitTest(point,
                                                  options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
        guard !scnHitTestResults.contains(where: { $0.node.name == BubbleNode.name }) else { return }
        
        //print(BubbleNode.name)
        
        guard let raycastQuery = sceneView.raycastQuery(from: point,
                                                        allowing: .existingPlaneInfinite,
                                                        alignment: .horizontal),
              let raycastResult = sceneView.session.raycast(raycastQuery).first else { return }
        let position = SCNVector3(raycastResult.worldTransform.columns.3.x,
                                  raycastResult.worldTransform.columns.3.y,
                                  raycastResult.worldTransform.columns.3.z)

        guard let cameraPosition = sceneView.pointOfView?.position else { return }
        let distance = (position - cameraPosition).length()
        guard distance <= 0.5 else { return }
        
        let bubbleNode = BubbleNode(text: text)
        bubbleNode.worldPosition = position
        
        //let player=AVPlayer(url:URL(fileURLWithPath:Bundle.main.path(forResource:"truck",ofType:"m4v")!))
        //let vc=AVPlayerViewController()
        //vc.player=player
        
        sceneView.prepare([bubbleNode]) { [weak self] success in
            if success {
                self?.sceneView.scene.rootNode.addChildNode(bubbleNode)
                //self?.present(vc,animated:true)
                if(self!.objectDectionItems.contains(self!.obejctName)){
                    self?.addARTV(z: position.z, item: self!.obejctName)
                    //self?.addARTV(z: position.z, item: BubbleNode.name)
                }
            }
        }
    }

    private func onSessionUpdate(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        isLoopShouldContinue = false

        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal and vertical surfaces."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            isLoopShouldContinue = true
            loopObjectDetection()
        }
        
        sessionInfoLabel.text = message
        sessionInfoLabel.isHidden = message.isEmpty
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        onSessionUpdate(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform = SCNMatrix4(frame.camera.transform)
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        if let lastLocation = lastLocation {
            let speed = (lastLocation - currentPositionOfCamera).length()
            isLoopShouldContinue = speed < 0.0025
        }
        lastLocation = currentPositionOfCamera
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        startSession(resetTracking: true)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session error: \(error.localizedDescription)"
    }
}

extension ViewController: ARSCNViewDelegate { }
