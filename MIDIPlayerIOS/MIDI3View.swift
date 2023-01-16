//
//  MIDI3View.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2022/12/23.
//

import Foundation
import UIKit
import CoreGraphics
import AVFoundation

class MIDIView: UIView {
    
    var rootView: MIDIRootView {
        self.superview as! MIDIRootView
    }
    
    var maxVerticalOffset:Double  {
        (rootView.numberOfPitch / rootView.visiblePitch - 1) * bounds.height
    }
    
    let minVerticalOffset:Double = 0
    
    var verticalOffset:Double {
//        let maxOffset = (rootView.numberOfPitch / rootView.visiblePitch - 1) * bounds.height
//        let minOffset:Double = 0
        var offset:Double = 0
        if rootView.verticalDrawOffset > minVerticalOffset && rootView.verticalDrawOffset < maxVerticalOffset {
            offset = rootView.verticalDrawOffset
        }
        else if rootView.verticalDrawOffset <= minVerticalOffset {
            offset = minVerticalOffset
        }
        else {
            offset = maxVerticalOffset
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
        self.fillHorizontalGrids(ctx,dirtyRect)
        self.drawVerticalGrids(ctx,dirtyRect)
        ctx.drawPath(using: .stroke)
        
        
        if let rects = rootView.noteRects {
            ctx.setFillColor(CGColor(_colorLiteralRed: 0.0, green: 1.0, blue: 0.9, alpha: 1.0))
            ctx.addRects(transRects(rects,dirtyRect))
            ctx.drawPath(using: .fill)
        }

        ctx.setLineWidth(0.5)
        ctx.setStrokeColor(UIColor.white.cgColor)
        let xposition = getCurrentPositionInView()
        ctx.move(to: CGPoint(x: xposition, y: self.bounds.minY))
        ctx.addLine(to: CGPoint(x: xposition, y: self.bounds.maxY))
        ctx.drawPath(using: .fillStroke)
    }
    func updateMidiNotes(_ noteRects:[CGRect],_ length:Double){
        rootView.trackLength = length
        rootView.noteRects = noteRects
        self.setNeedsDisplay()
    }
    
    func transRects (_ noteRects:[CGRect],_ dirtyRect:CGRect) -> [CGRect] {
        let horizontalRatio = self.frame.width  / Double(rootView.visibleDuration)
        let verticalRatio = self.frame.height / rootView.visiblePitch
        let result = noteRects.map{ CGRect(x: ($0.minX - rootView.visibleStartPoint) * horizontalRatio + rootView.horizontalDrawOffset, y: ($0.minY - rootView.lowestPitch) * verticalRatio - verticalOffset, width: $0.width * horizontalRatio, height: $0.height * verticalRatio) }
        let result2 = result.filter{ $0.minY <= dirtyRect.maxY && $0.maxY >= dirtyRect.minY && $0.minX <= dirtyRect.maxX && $0.maxX >= dirtyRect.minX}
        return result2
    }
    
    func getCurrentPositionInView() -> Double {
        let horizontalRatio = self.frame.width  / Double(rootView.visibleDuration)
        return (rootView.currentPositionInBeat  - rootView.visibleStartPoint ) * horizontalRatio + rootView.horizontalDrawOffset
    }
    
    func beatToPositionInView(_ beats:Double) -> Double {
        let horizontalRatio = self.frame.width  / Double(rootView.visibleDuration)
        return (beats  - rootView.visibleStartPoint ) * horizontalRatio + rootView.horizontalDrawOffset
    }
    
    func XToBeat(_ x:Double) -> Double {
        let horizontalRatio = self.frame.width  / Double(rootView.visibleDuration)
        return x / horizontalRatio
    }
    
//    func drawHorizontalGrids(_ ctx:CGContext) {
//        ctx.setLineWidth(0.4)
//        ctx.setStrokeColor(UIColor.red.cgColor)
//        for i in 0 ... Int(rootView.numberOfPitch) {
//            ctx.move(to: CGPoint(x: bounds.minX, y: bounds.height / rootView.visiblePitch * Double(i) - verticalOffset))
//            ctx.addLine(to: CGPoint(x: bounds.maxX, y: bounds.height / rootView.visiblePitch * Double(i) - verticalOffset))
//        }
//    }
    
    func fillHorizontalGrids(_ ctx:CGContext,_ dirtyRect:CGRect){
        ctx.setFillColor(UIColor.darkGray.cgColor)
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
    
    func drawVerticalGrids(_ ctx:CGContext,_ dirtyRect:CGRect){
        ctx.setLineWidth(0.4)
        ctx.setStrokeColor(UIColor.white.cgColor)
        let rightEdgeInBeat = Int(floor(XToBeat(-rootView.horizontalDrawOffset) + rootView.visibleStartPoint ))
        let leftEdgeInBeat = Int(ceil(XToBeat(self.bounds.width - rootView.horizontalDrawOffset) + rootView.visibleEndPoint))
        let yMax = bounds.height / rootView.visiblePitch * rootView.numberOfPitch - verticalOffset
        stride(from: rightEdgeInBeat, through: leftEdgeInBeat, by: 1).forEach{
            val in
            let x = beatToPositionInView(Double(val))
            if x >= dirtyRect.minX && x <= dirtyRect.maxX {
                ctx.move(to: CGPoint(x: x, y:  -verticalOffset))
                ctx.addLine(to: CGPoint(x: x , y:yMax))
            }
        }
    }
}


