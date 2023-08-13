//
//  ScannerView.swift
//  QrScanner
//
//  Created by Kentaro Mihara on 2023/07/07.
//

import SwiftUI
import AVKit

struct ScannerView: View {
    /// QR Code Scanner properties
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var cameraPermission: Permission = .idle
    
    /// QR scanner AV Output
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    /// Error properties
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.openURL) private var openURL
    
    /// Camera QR Output delegate
    @StateObject private var qrDelegate = QRScannerDelegate()
    
    
    /// Scanned code
    @State private var scannedCode: String = ""
    
    var body: some View {
        VStack(spacing: 8){
            Button{
                
            }label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Place the QR code inside the area")
                .font(.title3)
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 20)
            
            Text("Scanning will start automatically")
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer(minLength: 0)
            
            /// Scanner
            
            GeometryReader{
                let size = $0.size
                ZStack{
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                    /// Making it little smaller
                        .scaleEffect(0.97)
                    ForEach(0...4, id: \.self){ index in
                        let rotation = Double(index) * 90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                        /// Triming to get Scanner lik Edges
                            .trim(from: 0.61, to: 0.64)
                            .stroke(.black, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .rotationEffect(.init(degrees: rotation))
                    }
                }
                /// Square Shape
                .frame(width: size.width, height: size.width)
                /// Scanner Animation
                .overlay(alignment: .top, content: {
                    Rectangle()
                        .fill(.black)
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 : -15)
                        .offset(y: isScanning ? size.width: 0)
                })
                /// To Make it center
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 15)
            Button{
                if !session.isRunning && cameraPermission == .approved{
                    reactivateCamera()
                    activateScannerAnimation()
                }
            }label:{
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            
            Spacer(minLength: 45)
        }
        .padding(15)
        
        /// Checking camera permission, when the view is visible
        .onAppear(perform: checkCameraPermisssion)
        .alert(errorMessage, isPresented: $showError){
            /// Showing settings button, if permission is denined
            if cameraPermission == .denied{
                Button("Settings"){
                    let settingString = UIApplication.openSettingsURLString
                    if let settingURL = URL(string: settingString){
                        /// Opening Apps setting, using openURL SwiftUI API
                        openURL(settingURL)
                    }
                }
                
                /// Along with cancel button
                Button("Cancel", role: .cancel){
                }
            }
            
        }
        .onDisappear{
            session.stopRunning()
        }
        .onChange(of: qrDelegate.scannedCode){ newValue in
            if let code = newValue{
                scannedCode = code
                
                /// When the first code scan is available, immediately stop the camera.
                session.stopRunning()
                
                /// Stopping scanner animation
                deActivateScannerAnimation()
                /// Clearing the data on delegate
                qrDelegate.scannedCode = nil
            }
            
        }
    }
    
    func reactivateCamera(){
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    /// Activating Scanner Animation Method
    func activateScannerAnimation(){
        /// Adding Delay for each reversal
        withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)){
            isScanning = true
        }
    }
    
    /// DeActivating scanner animation method
    func deActivateScannerAnimation(){
        /// Adding Delay for each reversal
        withAnimation(.easeInOut(duration: 0.85)){
            isScanning = false
        }
    }
    
    
    /// Checking camera permission
    func checkCameraPermisssion(){
        Task{
            switch AVCaptureDevice.authorizationStatus(for: .video){
            case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty{
                    /// New setup
                    setupCamera()
                }else{
                    /// Already existing one
                    reactivateCamera()
                }
            case .notDetermined:
                /// Requesting camera access
                if await AVCaptureDevice.requestAccess(for: .video){
                    /// Permission Granted
                    cameraPermission = .approved
                    setupCamera()
                }else{
                    /// Permission Denied
                    cameraPermission = .denied
                    /// Presenting Erro message
                    presentError("Please provide access to camera for scanning codes")
                    
                }
            case .denied, .restricted:
                cameraPermission = .denied
            default: break
            }
        }
    }
    
    /// Setting up camera
    func setupCamera(){
        do{
            ///Finding back camera
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else{
                presentError("UNKNOWN DEVICE ERROR")
                return
            }
            
            /// Camera input
            let input = try AVCaptureDeviceInput(device: device)
            /// For Extra Safety
            /// Checking whether input & output can be added to the session
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else{
                presentError("UNKNOWN INPUT/OUTPUT ERROR")
                return
            }
            
            /// Adding input & output to camera session
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            /// Setting output config to read qr codes
            qrOutput.metadataObjectTypes = [.qr]
            /// Adding delegate to retreive the fetched qr code from camera
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            /// Note session must be started on background thread
            
            DispatchQueue.global(qos: .background).async{
                session.startRunning()
            }
            activateScannerAnimation()
        }catch{
            presentError(error.localizedDescription)
        }
    }
    
    /// Presenting Error
    func presentError(_ message: String){
        errorMessage = message
        showError.toggle()
    }
    
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
