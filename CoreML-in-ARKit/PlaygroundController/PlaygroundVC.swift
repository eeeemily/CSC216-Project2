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
    @IBOutlet weak var EvalLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var evalYesBtn: UIButton!
    @IBOutlet weak var evalNoBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        EvalLabel.isHidden = true
        scoreLabel.isHidden = true
        evalYesBtn.isHidden = true
        evalNoBtn.isHidden = true
        instructorAnchor = try! Instructor.loadPerson()
        arView.scene.anchors.append(instructorAnchor!)
        instructorAnchor?.actions.clickJacketToShowASL.onAction = handleTapOnJacket(_:)
    }
    
    func handleTapOnJacket(_ entity: Entity?) {
            guard let entity = entity else { return }
            // Do something with entity...
        EvalLabel.isHidden = false
        EvalLabel.text = "Did you do the Jacket ASL sign correctly?"
        scoreLabel.isHidden = false
        evalYesBtn.isHidden = false
        evalNoBtn.isHidden = false
//        print("jacket is clicked")
    }
    
}
