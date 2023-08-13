//
//  QRScannerDelegate.swift
//  QrScanner
//
//  Created by Kentaro Mihara on 2023/07/07.
//


import SwiftUI
import AVKit

class QRScannerDelegate: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate{
    @Published var scannedCode: String?
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        if let metaObject = metadataObjects.first{
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else {return}
            guard let scannedCode = readableObject.stringValue else {return}
            let encodeUrlString = scannedCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let encodedString = encodeUrlString{
                if let url = URL(string: encodedString) {
                    UIApplication.shared.open(url, options: [.universalLinksOnly: false], completionHandler: {completed in
                        print("here")
                    })
                }else{
                    print("else")
                    print(scannedCode)
                }
            }
        }
    }
}
