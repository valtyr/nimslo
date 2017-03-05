//
//  ViewController.swift
//  Valli
//
//  Created by Egill Sigurður on 4.3.2017.
//  Copyright © 2017 Egill. All rights reserved.
//

import UIKit
import AVFoundation
import SocketIO

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession: AVCaptureSession?
    var camera: AVCaptureDevice?
    var input: AVCaptureInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraOutput: AVCapturePhotoOutput?
    
    var socket: SocketIOClient?
    
    var sfx: AVAudioPlayer?
    
    var id: String?
    var num: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        setupSockets()
        
        do{
            sfx = try AVAudioPlayer(contentsOf: URL(string: Bundle.main.path(forResource: "shutter", ofType: "wav")!)!)
        } catch {
            //ehv
        }
        
        
        let snert = UITapGestureRecognizer(target: self, action: #selector(emitPic))
        view.addGestureRecognizer(snert)
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //SOCKET METHODS
    
    func setupSockets(){
        socket = SocketIOClient(socketURL: URL(string: RequestMaster.socketURL)!, config: [.log(false), .forcePolling(true)])
        socket?.on("connect") {data, ack in
            print("socket connected")
            
            self.socket?.emit("ég er mættur!")
        }
        socket?.connect()
        
        socket?.on("nýi gæjinn er númer") { data, ack in
            let dataObj = data.first as? NSObject
            self.num = String((dataObj?.value(forKey: "numUsers") as! Int))
        }
        
        socket?.on("TAKIÐI MYND!") { data, ack in
            let dataObj = data.first as? NSObject
            self.id = String((dataObj?.value(forKey: "id") as! Int))
            self.takePic()
            self.sfx?.play()
        }
    }
    
    func emitPic(){
        socket?.emit("sís")
    }
    
    
    
    //CAMERA METHODS
    
    func setupCaptureSession(){
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPresetPhoto
        do{
            camera = getCamera()
            input = try AVCaptureDeviceInput.init(device: camera)
        } catch {
            //SKOÐA
        }
        cameraOutput = AVCapturePhotoOutput()
        captureSession?.addInput(input)
        captureSession?.addOutput(cameraOutput)
        
        captureSession?.startRunning()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = view.frame
        view.layer.addSublayer(previewLayer!)
    }
    
    func getCamera() -> AVCaptureDevice{
        return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
    }
    
    func takePic(){
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func picReady(image: UIImage){
        print(id!, num!)
        RequestMaster.sendPic(image: image, id: id!, num: num!)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print(UIImage(data: dataImage)?.size as Any)
            let image = UIImage(data: dataImage)
            picReady(image: image!)
        } else {
            print("some error here")
        }
        
    }
    
}
