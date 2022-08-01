//
//  VideoPlayerViewController.swift
//  CVRecorderSampleApp
//
//  Created by Ankit Sachan on 08/06/22.
//

import UIKit
import Photos
import AVKit
import MediaPlayer
import Vision
import CVRecorder

/**
 References :
 
 https://stackoverflow.com/questions/39551459/ios-avplayer-getting-a-snapshot-of-the-current-frame-of-a-video/39553034#39553034
 https://stackoverflow.com/a/67917995/195504
 */

class VideoPlayerViewController: UIViewController {
    
    @IBOutlet private weak var videoList : UITableView?
    @IBOutlet private weak var videoPlayerContainer : UIView!
    @IBOutlet private weak var detetctionLayerContainer : UIView!
    @IBOutlet private weak var toggleObjectDetectionButton : UIButton!
    
    
    private var videos: [PHAsset] = []
    private let tableViewCellIdentifier = "cell"
    private var playerViewController: AVPlayerViewController?
    private var playerOutput : AVPlayerItemVideoOutput!
    private var isObjectDetectionOn = false
    
    private let _detectorSerialQueue = DispatchQueue(label: "com.test.objectDetectorSerialQueue")
    
    private var objectDetection: ObjectDetection!
    private var visionRequests : [VNRequest]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPlayer()
        videoList?.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
        PHPhotoLibrary.requestAuthorization(for: .readWrite) {[weak self] (status) in
            if status == .authorized{
                self?.fetchVideosFromGallery()
            }
        }
        
    }
    
}
extension VideoPlayerViewController{
    
    private func addPlayer(){
        if playerViewController == nil{
            playerViewController = AVPlayerViewController()
            playerViewController!.allowsPictureInPicturePlayback = true
            playerViewController!.view.frame = videoPlayerContainer.bounds
            let airplayView = MPVolumeView()
            airplayView.showsVolumeSlider = false
            airplayView.sizeToFit()
            var airplayframe = airplayView.frame
            airplayframe.origin.x = self.view.bounds.size.width - 52
            airplayframe.origin.y = 6
            airplayView.frame = airplayframe
            airplayView.sizeToFit()
            playerViewController!.view.addSubview(airplayView)
            playerViewController!.view.backgroundColor = UIColor.clear
            self.addChild(playerViewController!)
            videoPlayerContainer.addSubview(playerViewController!.view)
            playerViewController!.didMove(toParent: self)
        }
        toggleObjectDetectionButton.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
    }
}

extension VideoPlayerViewController{
    private func fetchVideosFromGallery(){
        let fetchResults = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
        
        // Loop through all fetched results
        fetchResults.enumerateObjects({ [weak self] (object, count, stop) in
            
            // Add video object to our video array
            self?.videos.append(object)
           
        })
        DispatchQueue.main.async {
            self.videoList?.reloadData()
        }
    }
}

extension VideoPlayerViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        print("<<<<<<<<< \(videos.count)")
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier)!
        
        // Get video asset at current index
        let videoAsset = videos[indexPath.row]
        
        // Display video creation date
        cell.textLabel?.text = "Video from \(videoAsset.creationDate ?? Date())"
        
        // Load video thumbnail
        PHCachingImageManager.default().requestImage(for: videoAsset,
                                                     targetSize: CGSize(width: 100, height: 100),
                                                     contentMode: .aspectFill,
                                                     options: nil) { (photo, _) in
            
            cell.imageView?.image = photo
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Get video asset at current index
        let videoAsset = videos[indexPath.row]
        
        // Fetch the video asset
        PHCachingImageManager.default().requestAVAsset(forVideo: videoAsset, options: nil) { [weak self] (video, _, _) in
            if let video = video
            {
                // Launch video player in the main thread
                DispatchQueue.main.async {
                    self?.playVideo(video)
                }
            }
        }
    }
    
    private func playVideo(_ video: AVAsset)
    {
        let settings: [String : Any] = [
          kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        let playerOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
        
        let playerItem = AVPlayerItem(asset: video)
        playerItem.add(playerOutput)
        let player = AVPlayer(playerItem: playerItem)
        
        playerViewController!.player = player
        

        guard let asset =  playerViewController?.player?.currentItem?.asset  else {
            return
        }
//        let asset = self.player?.currentItem?.asset
        let tracks = asset.tracks(withMediaType: .video)
        let fps = tracks.first?.nominalFrameRate
        
        let videoFPS = lround(Double(fps!))
        
        playerViewController?.player?.addPeriodicTimeObserver(
            forInterval: CMTimeMake(value: 1,timescale: Int32(videoFPS)),
            queue: _detectorSerialQueue, using: { [weak self] (progressTime) in
                print("<<<<<<<<<< current time is \(progressTime)")
                
                guard let buffer = playerOutput.copyPixelBuffer(forItemTime: playerItem.currentTime(), itemTimeForDisplay: nil) else{
                    return
                }
                self?.performObjectDetectionOnFrameIfrequired(buffer)
                print("here")
            })
        
        playerViewController!.player!.play()
    
    }
}


extension VideoPlayerViewController{
    @IBAction private func toggleObjectDetection(_ sender: UIButton?){
        _detectorSerialQueue.sync {
            isObjectDetectionOn = !isObjectDetectionOn
            DispatchQueue.main.async {
                sender?.setImage(UIImage(named: self.isObjectDetectionOn ? "open-eye" : "closed-eye"), for: .normal)
            }
            if isObjectDetectionOn{
                if self.objectDetection == nil{
                    self.objectDetection = ObjectDetection(
                        cameraLayer: detetctionLayerContainer.layer,
                        videoFrameSize: detetctionLayerContainer.bounds.size
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
    
    private func performObjectDetectionOnFrameIfrequired(_ pixelBuffer: CVPixelBuffer){
        if isObjectDetectionOn{
            print("perform object detetcion")
            let frameOrientation: CGImagePropertyOrientation = .up
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: frameOrientation, options: [:])
            do {
                try imageRequestHandler.perform(self.visionRequests!)
            } catch {
                print(error)
            }
        }
    }
}



