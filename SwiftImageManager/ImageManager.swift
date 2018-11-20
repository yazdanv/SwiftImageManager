//
//  SwiftImageManager.swift
//  SwiftImageManager
//
//  Created by Yazdan Vakili on 11/15/18.
//  Copyright © 2018 Mandaa. All rights reserved.
//

import UIKit

public let ImageManager = SwiftImageManager.instance

public class SwiftImageManager: NSObject {
    
    static let instance: SwiftImageManager = SwiftImageManager()
    
    
    // image memory cache, so we do not load images every time from storage
    var imageCache: [String: UIImage] = [:]
    
    override init() {
        super.init()
        try? FileManager.default.createDirectory(at: documentUrl.appendingPathComponent("ImageManager/", isDirectory: true), withIntermediateDirectories: true)
    }
    
    
    public var defaultImage: UIImage!
    
    public func load(with url: URL, _ loaded: @escaping ((UIImage) -> Void)) {
        if imageCache.keys.contains(url.absoluteString) {
            DispatchQueue.main.async {loaded(self.imageCache[url.absoluteString]!)}
        } else {
            URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let data = data, let image = UIImage(data: data) {
                    self.imageCache[url.absoluteString] = image
                    DispatchQueue.main.async {loaded(image)}
                }
                }.resume()
        }
    }
    
    public func load(_ string: String, _ loaded: @escaping ((UIImage) -> Void)) {
        if string.isImagePath {
            if imageCache.keys.contains(string) {
                DispatchQueue.main.async {loaded(self.imageCache[string]!)}
            } else {
                DispatchQueue.init(label: "imageLoad", qos: .background).async {
                    if let url = URL(string: string) {
                        if let img = UIImage(contentsOfFile: self.pathFor(filename: string).path) {
                            var size: Int64 = 0
                            do {
                                size = (try FileManager.default.attributesOfItem(atPath: self.pathFor(filename: string).path))[FileAttributeKey.size] as! Int64
                            } catch {}
                            var request = URLRequest(url: url)
                            request.httpMethod = "HEAD"
                            URLSession.shared.dataTask(with: request, completionHandler: {data, response, err in
                                if let nSize = response?.expectedContentLength {
                                    if nSize != size {
                                        self.load(with: url, loaded)
                                    } else {
                                        DispatchQueue.main.async {
                                            self.imageCache[string] = img
                                            loaded(img)
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.imageCache[string] = img
                                        loaded(img)
                                    }
                                }
                            })
                        } else {
                            self.load(with: url, loaded)
                        }
                    }
                }
            }
        }
    }
    
    public func load(url string: String, _ loaded: @escaping ((UIImage) -> Void)) -> UIImage? {
        load(string, loaded)
        if let img = load(string) {
            return img
        }
        return nil
    }
    
    public func load(_ name: String) -> UIImage? {
        if imageCache.keys.contains(name) {
            return imageCache[name]!
        } else {
            let extensions = ["png", "jpg", "jpeg"]
            for ext in extensions {
                if let img = UIImage(contentsOfFile: pathFor(filename: "\(name).\(ext)").path) {
                    imageCache[name] = img
                    return img
                } else if let img = UIImage(named: name) {
                    imageCache[name] = img
                    return img
                } else if let pt = Bundle.main.path(forResource: name, ofType: ext), let img = UIImage(contentsOfFile: pt) {
                    imageCache[name] = img
                    return img
                }
            }
            if let img = UIImage.gifImageWithName(name) {
                imageCache[name] = img
                return img
            } else if let data = try? Data(contentsOf: pathFor(filename: "\(name).gif")), let img = UIImage.gifImageWithData(data) {
                imageCache[name] = img
                return img
            }
        }
        return nil
    }
    
    public func load(named name: String) -> UIImage {
        if let img = load(name) {
            return img
        }
        return defaultImage
    }
    
    public func save(name: String, image: UIImage) {
        save(name, image.pngData()!)
    }
    
    func save(_ name: String, _ data: Data) {
        do {
            let path = pathFor(filename: name)
            try data.write(to: path, options: .atomic)
        } catch {
            print("error")
        }
    }
    
    
    // convert string image to UIImage
    public func convertByteToImage(_ image: String) -> UIImage? {
        let dataDecoded: NSData = NSData(base64Encoded: image, options: NSData.Base64DecodingOptions(rawValue: 0))!
        return UIImage(data: dataDecoded as Data)
    }
    
    func convertByteToData(_ image: String) -> Data {
        let dataDecoded: NSData = NSData(base64Encoded: image, options: NSData.Base64DecodingOptions(rawValue: 0))!
        return dataDecoded as Data
    }
    
    
    //////// getting filepath for desired filename
    var documentUrl: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
    }
    
    func pathFor(filename: String) -> URL {
        let file = documentUrl.appendingPathComponent("ImageManager/\(filename)", isDirectory: false)
        return file
        
    }
    
}
