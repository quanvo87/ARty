//
//  ViewController.swift
//  ARty
//
//  Created by Quan Vo on 5/23/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!

    private let locationManager = CLLocationManager()

    private var startDate = Date()

    private var lastLocation = CLLocation()

    private var trueHeading = CLLocationDirection()

    private let uid = UUID().uuidString

    private var arties = [String: ARty]()

    private var arty: ARty? {
        return arties[uid]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.session.delegate = self

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            startDate = Date()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration)

        let arty = try! ARty(ownerId: uid, modelName: .elvira)
        arty.position = SCNVector3(0, arty.yPosition, -2)
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.ownerId] = arty
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: sceneView) else {
            return
        }
        let hitTest = sceneView.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: true])
        guard let uid = (hitTest.first?.node.parent as? ARty)?.ownerId,
            let arty = arties[uid] else {
                return
        }
        try? arty.playAnimation(arty.pokeAnimation)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            if newLocation.isValid(oldLocation: lastLocation, startDate: startDate) {
                try? arty?.playWalkAnimation(location: newLocation)
                arty?.turn(location: newLocation)
            }
            lastLocation = newLocation
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arty = arty,
            let currentPosition = sceneView.pointOfView?.position else {
                return
        }
        let adjustment = SCNVector3(0, arty.yPosition, -2)
        let newVector = currentPosition + adjustment
        let moveAction = SCNAction.move(to: newVector, duration: 1.0)
        arty.runAction(moveAction)
    }
}

extension ViewController: ARSCNViewDelegate {
}
