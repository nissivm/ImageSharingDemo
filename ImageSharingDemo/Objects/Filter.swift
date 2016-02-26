//
//  Filter.swift
//  ImageSharingDemo
//
//  Created by Nissi Vieira Miranda on 2/19/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

class Filter
{
    private var originalImage: UIImage?
    private var coreImage: CIImage!
    private var context: CIContext!
    private var canFilter = false
    
    init(original: UIImage?)
    {
        if let cgImage = original!.CGImage
        {
            originalImage = original
            coreImage = CIImage(CGImage: cgImage)
            
            let openGLContext = EAGLContext(API: .OpenGLES2)
            context = CIContext(EAGLContext: openGLContext)
            canFilter = true
        }
    }
    
    func applyFilterWithIndex(index: Int) -> UIImage?
    {
        guard canFilter else
        {
            return nil
        }
        
        switch index
        {
            case 0:
                return applySepiaFilter()
            case 1:
                return applyCIPhotoEffectInstant()
            case 2:
                return applyCIPhotoEffectNoir()
            case 3:
                return applyCIPhotoEffectProcess()
            case 4:
                return applyCIPhotoEffectTransfer()
            case 5:
                return applyCICMYKHalftone()
            case 6:
                return applyCIGloom()
            case 7:
                return originalImage
            default:
                print("Unknown filter")
                return nil
        }
    }
    
    private func applySepiaFilter() -> UIImage?
    {
        guard let filter = CIFilter(name: "CISepiaTone") else
        {
            print("Failed creating Sepia Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        
        return outputFilteredImage(filter)
    }
    
    private func applyCIPhotoEffectInstant() -> UIImage?
    {
        guard let filter = CIFilter(name: "CIPhotoEffectInstant") else
        {
            print("Failed creating CIPhotoEffectInstant Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        
        return outputFilteredImage(filter)
    }
    
    private func applyCIPhotoEffectNoir() -> UIImage?
    {
        guard let filter = CIFilter(name: "CIPhotoEffectNoir") else
        {
            print("Failed creating CIPhotoEffectNoir Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        
        return outputFilteredImage(filter)
    }
    
    private func applyCIPhotoEffectProcess() -> UIImage?
    {
        guard let filter = CIFilter(name: "CIPhotoEffectProcess") else
        {
            print("Failed creating CIPhotoEffectProcess Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        
        return outputFilteredImage(filter)
    }
    
    private func applyCIPhotoEffectTransfer() -> UIImage?
    {
        guard let filter = CIFilter(name: "CIPhotoEffectTransfer") else
        {
            print("Failed creating CIPhotoEffectTransfer Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        
        return outputFilteredImage(filter)
    }
    
    private func applyCICMYKHalftone() -> UIImage?
    {
        guard let filter = CIFilter(name: "CICMYKHalftone") else
        {
            print("Failed creating CICMYKHalftone Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 150, y: 150), forKey: "inputCenter")
        filter.setValue(6, forKey: "inputWidth")
        filter.setValue(0, forKey: "inputAngle")
        filter.setValue(0.7, forKey: "inputSharpness")
        filter.setValue(1, forKey: "inputGCR")
        filter.setValue(0.5, forKey: "inputUCR")
        
        return outputFilteredImage(filter)
    }
    
    private func applyCIGloom() -> UIImage?
    {
        guard let filter = CIFilter(name: "CIGloom") else
        {
            print("Failed creating CIGloom Filter")
            return nil
        }
        
        filter.setValue(coreImage, forKey: kCIInputImageKey)
        filter.setValue(10, forKey: "inputRadius")
        filter.setValue(1, forKey: "inputIntensity")
        
        return outputFilteredImage(filter)
    }
    
    private func outputFilteredImage(filter: CIFilter) -> UIImage?
    {
        guard let output = filter.valueForKey(kCIOutputImageKey) as? CIImage else
        {
            print("Failed generating output image for Sepia Filter")
            return nil
        }
        
        let cgImgResult = context.createCGImage(output, fromRect: output.extent)
        return UIImage(CGImage: cgImgResult)
    }
}