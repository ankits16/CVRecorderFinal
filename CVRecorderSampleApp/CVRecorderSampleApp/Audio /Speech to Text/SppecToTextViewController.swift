//
//  SppecToTextViewController.swift
//  CVRecorderSampleApp
//
//  Created by Ankit Sachan on 01/08/22.
//

import UIKit
import Speech
import AVKit


class SppecToTextViewController: UIViewController {
    @IBOutlet private weak var btnStart : UIButton!
    @IBOutlet weak var lblText              : UILabel!
    
    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
    }
    
    @IBAction func toggleRecording(){
        if audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.btnStart.isEnabled = false
            self.btnStart.setTitle("Start Recording", for: .normal)
        } else {
            self.startRecording()
            self.btnStart.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func setupSpeech() {
        
        self.btnStart.isEnabled = false
        self.speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.btnStart.isEnabled = isButtonEnabled
            }
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

                    self.btnStart.isEnabled = true
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

extension SppecToTextViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.btnStart.isEnabled = true
        } else {
            self.btnStart.isEnabled = false
        }
    }
}
