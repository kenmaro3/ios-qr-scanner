//
//  Permission.swift
//  QrScanner
//
//  Created by Kentaro Mihara on 2023/07/07.
//

import Foundation

///  Camera permission enum

enum Permission: String{
    case idle = "Not Determined"
    case approved = "Access Granted"
    case denied = "Access Denied"
}
