//
//  PlaygroundVC.swift
//  CoreML-in-ARKit
//
//  Created by Zheng, Minghui on 11/28/21.
//  Copyright © 2021 Yehor Chernenko. All rights reserved.
//

import UIKit
import RealityKit
var instructorAnchor: Instructor.Person?
class PlaygroundVC: UIViewController {
    @IBOutlet weak var arView: ARView!
    override func viewDidLoad() {
        super.viewDidLoad()
        instructorAnchor = try! Instructor.loadPerson()
        arView.scene.anchors.append(instructorAnchor!)
        
    }
}
