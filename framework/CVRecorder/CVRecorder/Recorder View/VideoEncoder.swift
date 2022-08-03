//
//  VideoEncoder.swift
//  CVRecorder
//
//  Created by Ankit Sachan on 09/05/22.
//

import Foundation
import AVFoundation
import Photos

class VideoEncoder {
    let path : URL
    
    private let _writer: AVAssetWriter!
    private let _videoInput : AVAssetWriterInput!
    private let _audioInput : AVAssetWriterInput!
    
    
    init(path: URL, height: Int, width: Int, channels: Int, samples: Float64) throws{
        self.path = path
        do{
            if FileManager.default.fileExists(atPath: path.path){
                try FileManager.default.removeItem(at: path)
            }
            
//            let url = URL(fileURLWithPath: path)
            _writer = try AVAssetWriter(url: path, fileType: .mp4)
            
            //Add video input
            _videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: CGFloat(640),
                AVVideoHeightKey: CGFloat(480),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 2300000,
                ],
                AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill as AnyObject
            ])
        
            _videoInput.expectsMediaDataInRealTime = true
            if _writer.canAdd(_videoInput) {
                _writer.add(_videoInput)
            }
        
            // add audio
            _audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
            ])
            _audioInput.expectsMediaDataInRealTime = true
            if _writer.canAdd(_audioInput) {
                _writer.add(_audioInput)
            }
            
        }catch (let error){
            print("<<<<<<<<<< error obserevd \(error.localizedDescription)")
            throw error
        }
    }
    
    func finishwithCompletionHandler(_ completion: @escaping(()-> Void)){
        _writer.finishWriting {
            let url = self._writer.outputURL
            self.saveVideoToAlbum(videoUrl: url)
            completion()
        }
    }
    
    
    
    func encodeFrame(sampleBuffer: CMSampleBuffer, isVideo: Bool) -> Bool{
        
        if (_writer.status == .unknown){
            print("<<<<<<<<<<<<< encodeFrame startWriting \(isVideo)")
            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            _writer.startWriting()
            _writer.startSession(atSourceTime: startTime)
        }
        
        if (_writer.status == .failed){
            debugPrint("_writer error \(_writer.error?.localizedDescription)")
            return false
        }
        
        if isVideo{
            if (_videoInput.isReadyForMoreMediaData == true){
//                debugPrint("<<<<<<<<<<<<<<  _videoInput.append(sampleBuffer)")
                _videoInput.append(sampleBuffer)
                return true
            }
        }else{
            if(_audioInput.isReadyForMoreMediaData){
                _audioInput.append(sampleBuffer)
                return true
            }
        }
        return false
    }
    
    deinit{
        debugPrint("_encoder deinitialized")
    }
    
}

extension VideoEncoder{
    private func saveVideoToAlbum(videoUrl: URL) {
        var info = ""
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }) { (success, error) in
            if success {
                info = "hello"
            } else {
                info = "保存失败，err = \(error.debugDescription)"
            }
            
            print(info)
            
            
        }
    }
}
