//
//  LocalImageFileManager.swift
//  AdventureTube
//
//  Created by chris Lee on 16/3/22.
//

import Foundation
import SwiftUI

class LocalImageFileManager {
    
    static let instance = LocalImageFileManager()
    let folderName = FolderConstant.image.name
    private init() {
        // create folder
        //TODO
        createFolderIfNeeded()
    }
    
    func saveImage(image: UIImage, imageName: String) {
        
        // get path for image
        guard
            let data = image.pngData(),
            let url = getURLForImage(imageName: imageName)
            else { return }
        
        // save image to path
        do {
            try data.write(to: url)
        } catch let error {
            print("Error saving image. ImageName: \(imageName). \(error)")
        }
    }
    
    func getImage(imageName: String) -> UIImage? {
        guard
            let url = getURLForImage(imageName: imageName),
            FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    
    private func createFolderIfNeeded() {
        guard let url = getURLForFolder() else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Error creating directory. FolderName: \(folderName). \(error)")
            }
        }
    }
    
    private func getURLForFolder() -> URL? {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent(folderName)
    }
    
    private func getURLForImage(imageName: String) -> URL? {
        guard let folderURL = getURLForFolder() else {
            return nil
        }
        return folderURL.appendingPathComponent(imageName + ".png")
    }
    
}
