//
//  ObjectDetection.swift
//  ObjectDetectionDemo
//
//  Created by Ankit Sachan on 03/05/22.
//  Copyright © 2022 Jarek. All rights reserved.
//

import UIKit
import Vision
import QuartzCore


public class ObjectDetection{
    let cameraLayer: CALayer
    let videoFrameSize: CGSize
    var objectDetectionLayer: CALayer!
    
    private var stopDrawing = false
    
    public init (cameraLayer: CALayer, videoFrameSize: CGSize){
        self.cameraLayer = cameraLayer
        self.videoFrameSize = videoFrameSize
        setupObjectDetectionLayer(cameraLayer, videoFrameSize)
    }
    
    
    public func createObjectDetectionVisionRequest() -> VNRequest? {
        do {
            let model = yolov2_pipeline().model
            let visionModel = try VNCoreMLModel(for: model)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    if let results = request.results {
                        self.processVisionRequestResults(results)
                    }
                })
            })

            objectRecognition.imageCropAndScaleOption = .scaleFit
            return objectRecognition
        } catch let error as NSError {
            print("Model loading error: \(error)")
            return nil
        }
    }
    
    public func startDetection(){
        stopDrawing = false
    }
    
    public func stopDetection(){
        
        self.objectDetectionLayer.sublayers = nil
        print("-------------- stopDetection()")
        stopDrawing = true
       
    }
    
    private func processVisionRequestResults(_ results: [Any]) {
        if !stopDrawing{
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                
            self.objectDetectionLayer.sublayers = nil
            for observation in results where observation is VNRecognizedObjectObservation {
                guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                    continue
                }

                let topLabelObservation = objectObservation.labels[0]
                let objectBounds = VNImageRectForNormalizedRect(
                    objectObservation.boundingBox,
                    Int(self.objectDetectionLayer.bounds.width), Int(self.objectDetectionLayer.bounds.height))
                    
                let bbLayer = self.createBoundingBoxLayer(objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
                self.objectDetectionLayer.addSublayer(bbLayer)
            }
            print("***************** startDetection()")
            CATransaction.commit()
        }
    }
    
    private func setupObjectDetectionLayer(_ viewLayer: CALayer, _ videoFrameSize: CGSize) {
        self.objectDetectionLayer = CALayer()
        self.objectDetectionLayer.name = "ObjectDetectionLayer"
        self.objectDetectionLayer.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: videoFrameSize.width,
                                         height: videoFrameSize.height)
        self.objectDetectionLayer.position = CGPoint(x: viewLayer.bounds.midX, y: viewLayer.bounds.midY)
            
        viewLayer.addSublayer(self.objectDetectionLayer)

        let bounds = viewLayer.bounds
           
        let scale = fmax(bounds.size.width  / videoFrameSize.width, bounds.size.height / videoFrameSize.height)

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        self.objectDetectionLayer.setAffineTransform(CGAffineTransform(scaleX: scale, y: -scale))
        self.objectDetectionLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
    
    private func createBoundingBoxLayer(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CALayer {
        let path = UIBezierPath(rect: bounds)
            
        let boxLayer = CAShapeLayer()
        boxLayer.path = path.cgPath
        boxLayer.strokeColor = UIColor.red.cgColor
        boxLayer.lineWidth = 2
        boxLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 0.0])
            
        boxLayer.bounds = bounds
        boxLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        boxLayer.name = "Detected Object Box"
        boxLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.5, 0.5, 0.2, 0.3])
        boxLayer.cornerRadius = 6

        let textLayer = CATextLayer()
        textLayer.name = "Detected Object Label"
            
        textLayer.string = String(format: "\(identifier)\n(%.2f)", confidence)
        textLayer.fontSize = CGFloat(16.0)
            
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.width - 10, height: bounds.size.height - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.alignmentMode = .center
        textLayer.foregroundColor =  UIColor.red.cgColor
        textLayer.contentsScale = 2.0
            
        textLayer.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: -1.0))
            
        boxLayer.addSublayer(textLayer)
        return boxLayer
    }
}
