//
//  MIDIRulerView.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2023/01/04.
//

import Foundation
import UIKit
import CoreGraphics
import CoreText
import AVFoundation

class MIDIRulerView: UIView {

    var rootView: MIDIRootView {
        self.superview as! MIDIRootView
    }
    
    var labelPitch = 5
    
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
       
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0 , y: -1.0)

        ctx.setLineWidth(0.5)
        ctx.setStrokeColor(UIColor.white.cgColor)
        let xposition = getCurrentPositionInView()
        ctx.move(to: CGPoint(x: xposition, y: self.bounds.minY))
        ctx.addLine(to: CGPoint(x: xposition, y: self.bounds.maxY))
        ctx.drawPath(using: .fillStroke)
//        self.drawVerticalGrids(ctx)
        self.drawLabels(ctx)
        ctx.drawPath(using: .stroke)
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
    
    func YToPitch(_ y:Double) -> Double {
        let verticalRatio = self.frame.height / rootView.visiblePitch
        return y / verticalRatio
    }
    
    
    func drawVerticalGrids(_ ctx:CGContext){
        ctx.setLineWidth(0.4)
        ctx.setStrokeColor(UIColor.red.cgColor)
        let rightEdgeInBeat = Int(floor(XToBeat(-rootView.horizontalDrawOffset) + rootView.visibleStartPoint ))
        let leftEdgeInBeat = Int(ceil(XToBeat(self.bounds.width - rootView.horizontalDrawOffset) + rootView.visibleEndPoint))
        stride(from: rightEdgeInBeat, through: leftEdgeInBeat, by: 1).forEach{
            val in
            ctx.move(to: CGPoint(x: beatToPositionInView(Double(val)) , y: bounds.minY))
            ctx.addLine(to: CGPoint(x: beatToPositionInView(Double(val)) , y:bounds.maxY))
        }
    }
    
    func drawLabels(_ ctx:CGContext){
        let font = UIFont.preferredFont(forTextStyle: .body).withSize(10)
        let attr = [NSAttributedString.Key.font: font,.foregroundColor:UIColor.white]
        let fontBoundingBox = CTFontGetBoundingBox(font)
        let rightEdgeInBeat = Int(floor(XToBeat(-rootView.horizontalDrawOffset) + rootView.visibleStartPoint ))
        let leftEdgeInBeat = Int(ceil(XToBeat(self.bounds.width - rootView.horizontalDrawOffset) + rootView.visibleEndPoint))
        stride(from: rightEdgeInBeat, through: leftEdgeInBeat, by: 1).forEach{
            val in
            if val % labelPitch == 0 {
                let label = NSAttributedString(string: String(val),attributes: attr)
                let frameSetter = CTFramesetterCreateWithAttributedString(label)
                let path = CGPath(rect: CGRect(x: beatToPositionInView(Double(val)), y: 0, width: 30, height: fontBoundingBox.height * 1.1),transform: nil)
                let frame = CTFramesetterCreateFrame(frameSetter, CFRange(), path, nil)
                
//                label.draw(with: CGRect(x: beatToPositionInView(Double(val)), y: 12, width: 100, height: 100), context: nil)
//                ctx.draw(label, in: CGRect(x: beatToPositionInView(Double(val)), y: 12, width: 100, height: 100))
                CTFrameDraw(frame, ctx)
            }
        }
    }
}


