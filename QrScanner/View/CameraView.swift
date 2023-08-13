//
//  CameraView.swift
//  QrScanner
//
//  Created by Kentaro Mihara on 2023/07/07.
//

import SwiftUI
import AVKit


/// Camera View Using AVCaptureVideoPreviewLayer

struct CameraView: UIViewRepresentable{
    var frameSize: CGSize
    
    /// Camera Session
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView{
        /// Defining camera frame size
        let view = UIViewType(frame: CGRect(origin: .zero, size: frameSize))
        view.backgroundColor = .clear
        
        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.frame = .init(origin: .zero, size: frameSize)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.masksToBounds = true
        view.layer.addSublayer(cameraLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context){
        
    }
    
}

