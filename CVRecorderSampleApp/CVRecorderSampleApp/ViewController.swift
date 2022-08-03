//
//  ViewController.swift
//  CVRecorderSampleApp
//
//  Created by Ankit Sachan on 04/05/22.
//

import UIKit
import CVRecorder
import AVFoundation
import KUIPopOver

class ViewController: UIViewController {
    
    //IBOutlets
    @IBOutlet private weak var togglePauseResumeButton : UIButton?
    @IBOutlet private weak var toggleRecordingButton : UIButton?
    @IBOutlet private weak var changeCamera : UIButton?
    @IBOutlet private weak var cameraPreviewContainer : UIView?
    @IBOutlet private weak var cvToggleButton : UIButton?
    @IBOutlet private weak var menuButton : UIButton?
    
    // private ivars
    private lazy var captureStack : CVRecorder = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false
//    private lazy var cameraEngine: CameraEngine = CameraEngine(delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
}

extension ViewController{
    
    private func updateChangeCameraControl(_ currentRecorderState: RecorderState){
        
        switch currentRecorderState {
        case .Stopped:
            changeCamera?.isUserInteractionEnabled = true
            changeCamera?.backgroundColor = .green
            changeCamera?.setTitle("Change Camera", for: .normal)
        case .Paused:
            fallthrough
        case .Recording:
            fallthrough
        case .NotReady:
            changeCamera?.isUserInteractionEnabled = false
            changeCamera?.backgroundColor = .gray
            changeCamera?.setTitle("Change Camera Disabled", for: .normal)
        }
    }
    
    private func updatePauseResumeControl(_ currentRecorderState: RecorderState){
        
        switch currentRecorderState {
        case .Paused:
            togglePauseResumeButton?.isUserInteractionEnabled = true
            togglePauseResumeButton?.backgroundColor = .green
            togglePauseResumeButton?.setTitle("Resume", for: .normal)
        case .Recording:
            togglePauseResumeButton?.isUserInteractionEnabled = true
            togglePauseResumeButton?.backgroundColor = .green
            togglePauseResumeButton?.setTitle("Pause", for: .normal)
        case .Stopped:
            fallthrough
        case .NotReady:
            togglePauseResumeButton?.isUserInteractionEnabled = false
            togglePauseResumeButton?.backgroundColor = .gray
            togglePauseResumeButton?.setTitle("Pause", for: .normal)
        }
    }
    
    private func updateToggleRecordingControl(_ currentRecorderState: RecorderState){
        
        switch currentRecorderState {
        case .Paused:
            fallthrough
        case .Recording:
            toggleRecordingButton?.isUserInteractionEnabled = true
            toggleRecordingButton?.backgroundColor = .green
            toggleRecordingButton?.setTitle("Stop", for: .normal)
        case .Stopped:
            toggleRecordingButton?.isUserInteractionEnabled = true
            toggleRecordingButton?.backgroundColor = .green
            toggleRecordingButton?.setTitle("Start", for: .normal)
        case .NotReady:
            toggleRecordingButton?.isUserInteractionEnabled = false
            toggleRecordingButton?.backgroundColor = .gray
            toggleRecordingButton?.setTitle("Not Ready", for: .normal)
        }
    }
    
    
    private func disableChangeCameraControl(){
        changeCamera?.isUserInteractionEnabled = false
        changeCamera?.backgroundColor = .gray
    }
    
    private func enableChangeCameraControl(){
        changeCamera?.isUserInteractionEnabled = true
        changeCamera?.backgroundColor = .green
    }
    
    private func changeControlStates(_ currentRecorderState: RecorderState){
        updatePauseResumeControl(currentRecorderState)
        updateToggleRecordingControl(currentRecorderState)
        updateChangeCameraControl(currentRecorderState)
    }
    
    
    private func setup(){
        setupCaptureStack()
    }
    
    private func startPreview(){
        captureStack.loadCaptureStack(parentViewForPreview: cameraPreviewContainer!)
//        cameraEngine.startup(cameraPreviewContainer!, devicePosition: .back)
    }
    
    private func setupCaptureStack(){
        captureStack.loadCaptureStack(parentViewForPreview: cameraPreviewContainer!)
    }
}

extension ViewController{
    @IBAction func pausePressed(){
        captureStack.togglePauseResumeRecording()
        
    }
    
    @IBAction func toggleRecording(){
        captureStack.toggleRecording()
    }
    
    @IBAction func changeCameraPresed(){
        captureStack.changeCamera()
    }
    
    @IBAction func toggleDetection(_ toggleButton: UIButton){
        isObjectDetectionEnabled = !isObjectDetectionEnabled
        if isObjectDetectionEnabled{
            toggleButton.setImage(UIImage(named: "open"), for: .normal)
        }else{
            toggleButton.setImage(UIImage(named: "close"), for: .normal)
        }
        captureStack.toggleDetection(isObjectDetectionEnabled)
    }
}


extension ViewController: CVRecorderDelegate{
    func didChangedCamera(_ currentCameraPosition: AVCaptureDevice.Position) {
        switch currentCameraPosition {
        case .unspecified:
            print("------- Changed to back unspecified")
        case .back:
            print("------- Changed to back camera")
        case .front:
            print("------- Changed to front camera")
        @unknown default:
            print("------- Changed to unknown default")
        }
    }
    
    
    
    func didChangedRecorderState(_ currentRecorderState:  RecorderState){
        print("<<<<<< changed state -- \(currentRecorderState)")
        changeControlStates(currentRecorderState)
    }
}

extension ViewController{
    @IBAction private func menuButtonTapped(){
       let menuVC = ExperimentsMenuViewController(nibName: "ExperimentsMenuViewController", bundle: nil)
        menuVC.showPopover(sourceView: menuButton!)
        menuVC.menuItemSelectedCompletion = {[weak self] selectedExperiment in
            self?.handleSelectedExperiment(selectedExperiment)
        }
    }
    
    private func handleSelectedExperiment(_ selectedExperiment: Experiment){
        switch selectedExperiment {
        case .videoPlayer:
            showPlayer()
        case .audioTranscript:
            showAudioTranscript()
        }
    }
    
    private func showPlayer(){
        let playerVc = VideoPlayerViewController(nibName: "VideoPlayerViewController", bundle: nil)
        self.navigationController?.pushViewController(playerVc, animated: true)
    }
    
    private func showAudioTranscript(){
        let speecToTextVc = SppecToTextViewController(nibName: "SppecToTextViewController", bundle: nil)
        self.navigationController?.pushViewController(speecToTextVc, animated: true)
    }
}
