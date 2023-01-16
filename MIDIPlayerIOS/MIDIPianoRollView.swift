//
//  MIDIPianoRollView.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2023/01/04.
//

import Foundation
import UIKit
import CoreGraphics
import AVFoundation

class MIDIPianoRollView: UIView {

    var rootView: MIDIRootView {
        self.superview as! MIDIRootView
    }
    
    var verticalOffset:Double {
        let maxOffset = (rootView.numberOfPitch / rootView.visiblePitch - 1) * bounds.height
        let minOffset:Double = 0
        var offset:Double = 0
        if rootView.verticalDrawOffset > minOffset && rootView.verticalDrawOffset < maxOffset {
            offset = rootView.verticalDrawOffset
        }
        else if rootView.verticalDrawOffset <= minOffset {
            offset = minOffset
        }
        else {
            offset = maxOffset
        }
        return offset
    }
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        print("init bounds",bounds)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        print("init bounds",bounds)
    }
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        // scale to fit the current view size vertically and convert upper left origin to lower left
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0 , y: -1.0)
//        self.drawHorizontalGrids(ctx)
//        ctx.drawPath(using: .fillStroke)
        self.fillHorizontalGrids(ctx,dirtyRect)
        self.drawLabels(ctx)
        ctx.drawPath(using: .fillStroke)
    }
    
    func drawLabels(_ ctx:CGContext){
        let verySmallFont = UIFont.preferredFont(forTextStyle: .body).withSize(4)
        let smallFont = UIFont.preferredFont(forTextStyle: .body).withSize(8)
        let largeFont = UIFont.preferredFont(forTextStyle: .body).withSize(12)
        let verySmallFontBoundingBoxHeight = CTFontGetBoundingBox(verySmallFont).size.height * 1.1
        let smallFontBoundingBoxHeight = CTFontGetBoundingBox(smallFont).size.height * 1.1
        let largeFontBoundingBoxHeight = CTFontGetBoundingBox(largeFont).size.height
        let rawHeight = bounds.height / rootView.visiblePitch
        var height:Double = 0
        var attr:[NSAttributedString.Key : NSObject] = [:]
        if rawHeight > largeFontBoundingBoxHeight {
            attr = [NSAttributedString.Key.font: largeFont,.foregroundColor:UIColor.white]
            height = largeFontBoundingBoxHeight
        }
        else if rawHeight > smallFontBoundingBoxHeight {
            attr = [NSAttributedString.Key.font: smallFont,.foregroundColor:UIColor.white]
            height = smallFontBoundingBoxHeight
        }
        else {
            attr = [NSAttributedString.Key.font: verySmallFont,.foregroundColor:UIColor.white]
            height = verySmallFontBoundingBoxHeight
        }
        
        if rawHeight > verySmallFontBoundingBoxHeight {
            for i in Int(rootView.lowestPitch) ... Int(rootView.numberOfPitch + rootView.lowestPitch) {
                if DrumsMIDI.drumsMIDIDict.keys.contains(i),let labelString = DrumsMIDI.drumsMIDIDict[i] {
                    let label = NSAttributedString(string:labelString,attributes: attr)
                    let frameSetter = CTFramesetterCreateWithAttributedString(label)
                    let y = rawHeight  * (Double(i) - rootView.lowestPitch) - verticalOffset
                    let x = bounds.minX
                    let path = CGPath(rect: CGRect(x: x, y: y, width:bounds.width, height: height), transform: nil)
                    let frame = CTFramesetterCreateFrame(frameSetter, CFRange(), path, nil)
                    CTFrameDraw(frame, ctx)
                    
                }
            }
        }
    }

    
    func drawHorizontalGrids(_ ctx:CGContext) {
        ctx.setLineWidth(0.4)
        ctx.setStrokeColor(UIColor.white.cgColor)
        for i in 0 ... Int(rootView.numberOfPitch) {
            ctx.move(to: CGPoint(x: bounds.minX, y: bounds.height / rootView.visiblePitch  * Double(i) - verticalOffset))
            ctx.addLine(to: CGPoint(x: bounds.maxX, y: bounds.height / rootView.visiblePitch * Double(i) - verticalOffset))
        }
    }
    
    func fillHorizontalGrids(_ ctx:CGContext,_ dirtyRect:CGRect){
        for val in 0 ... Int(rootView.numberOfPitch) {
            if val % 2 == 0 {
                let rect = CGRect(x: bounds.minX, y: bounds.height / rootView.visiblePitch * Double(val) - verticalOffset, width: bounds.width, height: bounds.height / rootView.visiblePitch)
                if rect.minY <= dirtyRect.maxY && rect.maxY >= dirtyRect.minY {
                    ctx.addRect(rect)
                }
            }
        }
        ctx.drawPath(using: .fill)
    }
    
    func YToPitch(_ y:Double) -> Double {
        let verticalRatio = self.frame.height / rootView.visiblePitch
        return (y + verticalOffset) / verticalRatio + rootView.lowestPitch
    }
}


