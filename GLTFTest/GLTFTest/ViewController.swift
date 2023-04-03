//
//  ViewController.swift
//  GLTFTest
//
//  Created by MacBook on 30.03.2023.
//

import UIKit
import SceneKit
import ARKit
import GLTFKit2

class ViewController: UIViewController, ARSCNViewDelegate {

    private var animations = [GLTFSCNAnimation]()

    @IBOutlet var sceneView: ARSCNView!

    private let camera = SCNCamera()
    private let cameraNode = SCNNode()
    
    @IBOutlet var urlTextfield: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene

        addDoneButtonOnKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addLightNode()

        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.wantsHDREnvironmentTextures = true
        configuration.planeDetection = [.horizontal, .vertical]

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }

    func addLightNode() {
        let light = SCNLight()
        let node = SCNNode()
        light.type = .directional
        node.eulerAngles = SCNVector3(x: .pi, y: 0, z: 0)
        node.light = light
        light.castsShadow = true
        light.intensity = 0.1
        sceneView.scene.rootNode.addChildNode(node)
    }

    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))

        let items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)

        doneToolbar.items = items as? [UIBarButtonItem]
        doneToolbar.sizeToFit()

        urlTextfield.inputAccessoryView = doneToolbar
    }

    @objc
    func doneButtonAction() {
        urlTextfield.resignFirstResponder()

        Task {
            let urlString = urlTextfield.text ?? ""
            guard let url = URL(string: urlString) else { return }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return
            }

            do {
                try loadModel(with: data)
            } catch {
                print("error: \(String(describing: error))")
            }


            await MainActor.run {
                urlTextfield.isHidden = true
            }
        }
    }

    func loadModel(with data: Data) throws {
        let localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("model.glb")

        try data.write(to: localURL)

        GLTFAsset.load(with: localURL, options: [:]) { (progress, status, maybeAsset, maybeError, _) in
            Task {
                if status == .complete {
                    self.setAsset(maybeAsset)
                } else if let error = maybeError {
                    print("Failed to load glTF asset: \(error)")
                }
            }
        }
    }

    func setAsset(_ asset: GLTFAsset?) {
        let source = GLTFSCNSceneSource(asset: asset!)

        sceneView.scene.rootNode.addChildNode(source.defaultScene!.rootNode)
        animations = source.animations
        
        print(sceneView.scene.rootNode.childNodes.count)

        for animation in animations {
            for animationChanell in animation.channels {
                animationChanell.animation.repeatCount = CGFloat.infinity
            }
        }

        animations.first?.play()

        sceneView.scene.rootNode.addChildNode(cameraNode)
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
//
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // Place content only for anchors found by plane detection.
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // Create a custom object to visualize the plane geometry and extent.
//        let plane = Plane(anchor: planeAnchor, in: sceneView)
//
//        // Add the visualization to the ARKit-managed node so that it tracks
//        // changes in the plane anchor as plane estimation continues.
//        node.addChildNode(plane)
//    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
