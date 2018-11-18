//
//  String+Extension.swift
//  SwiftImageManager
//
//  Created by Yazdan Vakili on 11/18/18.
//  Copyright © 2018 Mandaa. All rights reserved.
//

public extension String {
    var isImagePath: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif"]
        let seperatedByDot = self.components(separatedBy: ".")
        let pathExtension = seperatedByDot.count > 1 ? seperatedByDot[seperatedByDot.count - 1]:""
        return imageExtensions.contains(pathExtension)
    }
}
