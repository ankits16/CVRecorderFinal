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
import Speech

class ViewController: UIViewController {
    
    //IBOutlets
    @IBOutlet private weak var togglePauseResumeButton : UIButton?
    @IBOutlet private weak var toggleRecordingButton : UIButton?
    @IBOutlet private weak var changeCamera : UIButton?
    @IBOutlet private weak var cameraPreviewContainer : UIView?
    @IBOutlet private weak var cvToggleButton : UIButton?
    @IBOutlet private weak var menuButton : UIButton?
    @IBOutlet private weak var sttButton : UIButton?
    @IBOutlet private weak var lblText : UILabel!
    
    // private ivars
    private lazy var captureStack : CVRecorder = CVRecorder(delegate: self)
    private var isObjectDetectionEnabled = false
    private let audioEngine             = AVAudioEngine()
    private var isSTTEnabled = false
    
    private let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    private var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask         : SFSpeechRecognitionTask?
    
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
            sttButton?.isEnabled = true
            toggleRecordingButton?.isUserInteractionEnabled = true
            toggleRecordingButton?.backgroundColor = .green
            toggleRecordingButton?.setTitle("Stop", for: .normal)
        case .Stopped:
            sttButton?.isEnabled = false
            toggleRecordingButton?.isUserInteractionEnabled = true
            toggleRecordingButton?.backgroundColor = .green
            toggleRecordingButton?.setTitle("Start", for: .normal)
        case .NotReady:
            sttButton?.isEnabled = false
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
        setupSpeech()
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


extension ViewController{
    private func setupSpeech() {
        
        self.sttButton?.isEnabled = false
        self.speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
//            var isButtonEnabled = false
//
//            switch authStatus {
//            case .authorized:
//                isButtonEnabled = true
//
//            case .denied:
//                isButtonEnabled = false
//                print("User denied access to speech recognition")
//
//            case .restricted:
//                isButtonEnabled = false
//                print("Speech recognition restricted on this device")
//
//            case .notDetermined:
//                isButtonEnabled = false
//                print("Speech recognition not yet authorized")
//            }
            
//            OperationQueue.main.addOperation() {
//                self.sttButton?.isEnabled = isButtonEnabled
//            }
        }
    }
    
    @IBAction private func toggleSTT(){
        if isSTTEnabled{
            isSTTEnabled = false
            self.recognitionRequest?.endAudio()
            self.sttButton?.isEnabled = false
            sttButton?.setImage(UIImage(named: "enableSTT"), for: .normal)
        }else{
            isSTTEnabled = true
            startRecording()
            sttButton?.setImage(UIImage(named: "disableSTT"), for: .normal)
        }
    }
    
    func startRecording() {

            // Clear all previous session data and cancel task
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }

            // Create instance of audio session to record voice
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(
                    AVAudioSession.Category.record,
                    mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker
                )
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }

            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            let inputNode = audioEngine.inputNode

            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            }

            recognitionRequest.shouldReportPartialResults = true

            self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

                var isFinal = false

                if result != nil {
                    self.lblText.text = result?.bestTranscription.formattedString
                    isFinal = (result?.isFinal)!
                }

                if error != nil || isFinal {

                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self.recognitionRequest = nil
                    self.recognitionTask = nil

                    self.sttButton?.isEnabled = true
                }
            })

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }

            self.audioEngine.prepare()

            do {
                try self.audioEngine.start()
            } catch {
                print("audioEngine couldn't start because of an error.")
            }

            self.lblText.text = "Say something, I'm listening!"
        }
}

extension ViewController : SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.sttButton?.isEnabled = true
        } else {
            self.sttButton?.isEnabled = false
        }
    }
}

