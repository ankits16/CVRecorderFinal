//
//  CameraEngine.swift
//  CVRecorder
//
//  Created by Ankit Sachan on 09/05/22.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import Vision


public class CameraEngine : NSObject{
    
    public static let shared = CameraEngine()
    
    
    private var _session : AVCaptureSession!
    private var _preview : AVCaptureVideoPreviewLayer!
    private var _captureQueue : DispatchQueue!
    private let serialQueue = DispatchQueue(label: "com.test.mySerialQueue")
    private let _detectorSerialQueue = DispatchQueue(label: "com.test.objectDetectorSerialQueue")
    private var _audioConnection : AVCaptureConnection!
    private var _videoConnection : AVCaptureConnection!
    private var _encoder : VideoEncoder!
    private var isCapturing = false
    private var isPaused = false
    private var _discont = false
    private var _currentFile : Int = 0
    private var _timeOffset : CMTime!
    private var _lastVideo : CMTime!
    private var _lastAudio : CMTime!
    
    private var _parentWidth: Int = 0
    private var _parentHeight : Int = 0
    
    var _channels :  Int!
    var _sampleRate : Float64!
    
    //    private weak var delegate : CVRecorderDelegate?
    //
    //    public init(delegate: CVRecorderDelegate){
    //        self.delegate = delegate
    //    }
    
    var objectDetection: ObjectDetection!
    var visionRequests : [VNRequest]? = []
    
    private func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    
    public func startup(_ parentView: UIView,  devicePosition: AVCaptureDevice.Position){
        if _session == nil{
            print("Starting up server")
            
            self.isCapturing = false
            isPaused = false
            _currentFile = 0
            _discont = false
            
            //create capture device with video
            _session = AVCaptureSession()
            _session.sessionPreset = AVCaptureSession.Preset.vga640x480
            let cameraDevice = cameraWithPosition(position: devicePosition)
            //Setup your microphone
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            
            do{
                _session.beginConfiguration()
                // Add camera to your session
                let deviceInput = try AVCaptureDeviceInput(device: cameraDevice!)
                if _session.canAddInput(deviceInput) {
                    _session.addInput(deviceInput)
                }
                // Add microphone to your session
                let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
                if _session.canAddInput(audioInput) {
                    _session.addInput(audioInput)
                }
                _captureQueue = DispatchQueue(label: "com.cvcamrecorder.record-video.data-output")
                let videoout = AVCaptureVideoDataOutput()
                videoout.setSampleBufferDelegate(self, queue: _captureQueue)
                let settings: [String : Any] = [
                  kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
                ]

                videoout.videoSettings = settings
                videoout.alwaysDiscardsLateVideoFrames = true
                _session.addOutput(videoout)
                videoout.connection(with: AVMediaType.video)?.videoOrientation = .portrait
                _videoConnection = videoout.connection(with: .video)
                if _videoConnection.isVideoStabilizationSupported{
                    _videoConnection.preferredVideoStabilizationMode = .auto
                }
                
                _parentHeight = Int(parentView.bounds.height)
                _parentWidth = Int(parentView.bounds.width)
                
                let audioout = AVCaptureAudioDataOutput()
                audioout.setSampleBufferDelegate(self, queue: _captureQueue)
                _session.addOutput(audioout)
                _audioConnection = audioout.connection(with: .audio)
                _session.commitConfiguration()
                
                _session.startRunning()
                _preview = AVCaptureVideoPreviewLayer(session: _session)
                _preview.videoGravity = .resizeAspectFill
                _preview.frame = parentView.frame
                _preview.bounds = parentView.bounds
                parentView.layer.addSublayer(_preview)
                
                
            }catch (let error){
                
                print("********** camera engine startup() \(error.localizedDescription)")
            }
        }
    }
    
    private var isObjectDetectionOn = false
    
    public func toggleObjectDetection(){
        _detectorSerialQueue.sync {
            isObjectDetectionOn =  !isObjectDetectionOn
            if isObjectDetectionOn{
                if self.objectDetection == nil{
                    self.objectDetection = ObjectDetection(
                        cameraLayer: getPreviewLayr(),
                        videoFrameSize: getPreviewLayr().bounds.size
                    )
                }
                if let unwrappedVisionRequest = self.objectDetection.createObjectDetectionVisionRequest(){
                    self.visionRequests = [unwrappedVisionRequest]
                }else{
                    self.visionRequests = []
                }
                objectDetection.startDetection()
                
            }else{
                objectDetection.stopDetection()
            }
        }
    }
    
   
    
    public func startCapture(){
        _captureQueue.sync {
            if(!self.isCapturing){
                print("<<<<<<<<< Start capturing")
                _encoder = nil
                self.isPaused = false
                _discont = false
                _timeOffset = CMTime(value: 0, timescale: 0)
                isCapturing = true
            }
        }
    }
    
    public func stopCapturing(){
        _captureQueue.sync {
            if(self.isCapturing){
                print("<<<<<<<<< stop capturing")
                let fileName = String(format: "captured_%d.mp4", _currentFile)
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                //                let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                _currentFile += 1
                
                //serialize with audio and video capture
                self.isCapturing = false
                _captureQueue.async {
                    self._encoder.finishwithCompletionHandler {
                        DispatchQueue.main.async {
                            self.isCapturing = false
                            self._encoder = nil
                        }
                    }
                }
            }
        }
    }
    
    public func pauseCapture(){
        _captureQueue.sync {
            if(self.isCapturing){
                print("<<<<<<<<< Initiating pause capture")
                self.isPaused = true
                _discont = true
            }
        }
    }
    
    public func resumeCapture(){
        _captureQueue.sync {
            if(self.isCapturing){
                print("<<<<<<<<< resuming capture")
                self.isPaused = false
            }
        }
    }
    
    public func shutdown(){
        print("Shutting down camera server")
        if _session != nil {
            _session.stopRunning()
            _session = nil
        }
        _encoder.finishwithCompletionHandler {
            print("Capture completed")
        }
    }
    
    public func getPreviewLayr() ->AVCaptureVideoPreviewLayer{
        return _preview
    }
}




extension CameraEngine : AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
        
    func adjustTime(sampleBuffer: CMSampleBuffer, by offset: CMTime) -> CMSampleBuffer?{
        var out:CMSampleBuffer?
        var count:CMItemCount = CMSampleBufferGetNumSamples(sampleBuffer)
        let pInfo = UnsafeMutablePointer<CMSampleTimingInfo>.allocate(capacity: count)
        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: pInfo, entriesNeededOut: &count)
        var i = 0
                while i<count {
                    pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset)
                    pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset)
                    i+=1
                }
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sampleBuffer, sampleTimingEntryCount: count, sampleTimingArray: pInfo, sampleBufferOut: &out)
        return out
    }
    
    func setAudioFormat(fmt: CMFormatDescription){
        //        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt) as! AudioStreamBasicDescription
        //        _sampleRate = asbd.mSampleRate
        //        _channels = Int(asbd.mChannelsPerFrame)
        
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt)
        
        _sampleRate = asbd!.pointee.mSampleRate // breakpoint
        _channels = Int(asbd!.pointee.mChannelsPerFrame)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var bVideo = true
        serialQueue.sync {
            //        _captureQueue.sync {
            
            var _sampleBuffer = sampleBuffer
            bVideo = connection == self._videoConnection
            if isObjectDetectionOn && bVideo{
                _detectorSerialQueue.sync {
                    self.performObjectDetection(sampleBuffer: sampleBuffer)
                }
            }
            if(!self.isCapturing || self.isPaused){
                return
            }
            
            if(self._encoder == nil && !bVideo){
                let fmt = CMSampleBufferGetFormatDescription(_sampleBuffer) as! CMFormatDescription
                self.setAudioFormat(fmt: fmt)
                let fileName = String(format: "captured%d.mp4", self._currentFile)
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                //                let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).absoluteString
                do{
                    
                    self._encoder = try VideoEncoder(
                        path: path,
                        height: self._parentHeight,
                        width: self._parentWidth,
                        channels: self._channels,
                        samples: self._sampleRate
                    )
                }catch (let error){
                    print("*************** \(error.localizedDescription)")
                    return
                }
            }
            
            if (self._discont){
                if (bVideo){
                    return
                }
                self._discont = false
                
                //calc adjustment
                var pts = CMSampleBufferGetPresentationTimeStamp(_sampleBuffer)
                let last = bVideo ? self._lastVideo : self._lastAudio
                if (last!.isValid){
                    if(self._timeOffset.isValid){
                        pts = CMTimeSubtract(pts, self._timeOffset)
                    }
                    
                    let offset = CMTimeSubtract(pts, last!)
                    print("Setting offset from \(bVideo ? "video": "audio")")
                    //                    print("Adding \(Int32(offset.value)/offset.timescale) to \(Int32(self._timeOffset.value)/self._timeOffset.timescale) (pts \(Int32(pts.value)/pts.timescale)")
                    
                    // this stops us having to set a scale for _timeOffset before we see the first video time
                    if self._timeOffset.value == 0{
                        self._timeOffset = offset
                    }else{
                        self._timeOffset = CMTimeAdd(self._timeOffset, offset)
                    }
                    self._lastAudio.flags = []
                    self._lastVideo.flags = []
                    return
                }
            }
            
            if (self._timeOffset.value > 0){
                if let unwrappedAdjustedBuffer = self.adjustTime(sampleBuffer: _sampleBuffer, by: self._timeOffset){
                    _sampleBuffer = unwrappedAdjustedBuffer
                }else{
                   print("<<<<<<<< unable to adjust the buffer")
                }
            }
            
            // record most recent time so we know the length of the pause
            var pts = CMSampleBufferGetPresentationTimeStamp(_sampleBuffer)
            let duration = CMSampleBufferGetDuration(_sampleBuffer)
            if duration.value > 0{
                pts = CMTimeAdd(pts, duration)
            }
            
            if(bVideo){
                self._lastVideo = pts
            }else{
                self._lastAudio = pts
            }
            //pass frame to encoder
            if self._encoder != nil{
                self._encoder.encodeFrame(sampleBuffer: _sampleBuffer, isVideo: bVideo)
            }
            
        }
    }
    
    private func performObjectDetection(sampleBuffer: CMSampleBuffer){
        
        guard let pixelBuffer = sampleBuffer.resize(CGSize(width: _parentWidth, height: _parentHeight)) /*CMSampleBufferGetImageBuffer(sampleBuffer)*/ else {
            return
        }
        if !isObjectDetectionOn{
            return
        }
        // We are using fixed "up" orientation here
        let frameOrientation: CGImagePropertyOrientation = .up
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: frameOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.visionRequests!)
        } catch {
            print(error)
        }
    }
}


extension CMSampleBuffer{
    func resize(_ destSize: CGSize)-> CVPixelBuffer? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        // Lock the image buffer
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        // Get information about the image
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CGFloat(CVPixelBufferGetBytesPerRow(imageBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        let width = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        var pixelBuffer: CVPixelBuffer?
        let options = [kCVPixelBufferCGImageCompatibilityKey:true,
               kCVPixelBufferCGBitmapContextCompatibilityKey:true]
        let topMargin = (height - destSize.height) / CGFloat(2)
        let leftMargin = (width - destSize.width) * CGFloat(2)
        let baseAddressStart = Int(bytesPerRow * topMargin + leftMargin)
        let addressPoint = baseAddress!.assumingMemoryBound(to: UInt8.self)
        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(destSize.width), Int(destSize.height), kCVPixelFormatType_32BGRA, &addressPoint[baseAddressStart], Int(bytesPerRow), nil, nil, options as CFDictionary, &pixelBuffer)
        if (status != 0) {
            print(status)
            return nil;
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer,CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer;
    }
}
