//
//  DrawingImageView.swift
//  BrainTraining
//
//  Created by Thai Nguyen on 1/17/20.
//  Copyright © 2020 Thai Nguyen. All rights reserved.
//

import UIKit

class DrawingImageView: UIImageView {
    
    weak var delegate: ViewController?
    
    var currentTouchLocation: CGPoint?

    
//     Only override draw() if you perform custom drawing.
//     An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//
//
//    }
    
    func draw(from start: CGPoint, to end: CGPoint) {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        
        image = renderer.image { ctx in
            
            image?.draw(in: bounds)
            
            UIColor.black.setStroke()
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineWidth(15)
            
            ctx.cgContext.move(to: start)
            ctx.cgContext.addLine(to: end)
            ctx.cgContext.strokePath()
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        currentTouchLocation = touches.first?.location(in: self)
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let newTouchPoint = touches.first?.location(in: self) else { return }
        
        guard let previousTouchPoint = currentTouchLocation else { return }
        
        draw(from: previousTouchPoint, to: newTouchPoint)
        
        currentTouchLocation = newTouchPoint
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        currentTouchLocation = nil
        
        perform(#selector(numberDrawn), with: nil, afterDelay: 0.3)
    }
    
    
    @objc private func numberDrawn() {
        
        guard let image = image else { return }
        
        let drawRect = CGRect(x: 0, y: 0, width: 28, height: 28)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(bounds: drawRect, format: format)
        
        let imageWithBackground = renderer.image { ctx in
            
            UIColor.white.setFill()
            ctx.fill(bounds)
            image.draw(in: drawRect)
        }
        
        // convert our UIImage into a CIImage; the force unwrap is safe here because the CGImage is only nil if the UIImage was created from a CIImage
        let ciImage = CIImage(cgImage: imageWithBackground.cgImage!)
        
        // attempt to create a color inversion filter
        if let filter = CIFilter(name: "CIColorInvert") {
            // give it our input CIImage
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            // create a context so we can perform conversion
            let context = CIContext(options: nil)
            
            // attempt to read the output CIImage
            if let outputImage = filter.outputImage {
                // attempt to convert that to a CGImage
                if let imageRef = context.createCGImage(outputImage, from: ciImage.extent) {
                    
                    // attempt to convert *that* to a UIImage
                    let finalImage = UIImage(cgImage: imageRef)
                    
                    // and finally pass the finished image to our delegate
                    delegate?.numberDrawn(finalImage)
                }
            }
        }
    }

}
