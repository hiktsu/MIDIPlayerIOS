//
//  DrawView.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2022/12/15.
//

import Foundation
import UIKit
import CoreGraphics
import AVFoundation

class DrawView: UIView {
    let margine:CGFloat = 20.0
    var pointData:[PointData]?
    var noteRects:[NoteRect]?
    var gridPoint:GridPoint?
    var horizontalScale:Float = 1.0 {
        didSet {
            if let origFrame = origFrame {
                self.frame = CGRect(x: origFrame.minX, y: origFrame.minY, width: origFrame.width * CGFloat(horizontalScale), height: origFrame.height * CGFloat(verticalScale))
            }
        }
    }
    
    var verticalScale:Float = 1.0 {
        didSet {
            if let origFrame = origFrame {
                self.frame = CGRect(x: origFrame.minX, y: origFrame.minY, width: origFrame.width * CGFloat(horizontalScale), height: origFrame.height * CGFloat(verticalScale))
            }
        }
    }
    var origFrame:CGRect?
    
    override init(frame frameRect: CGRect) {
        origFrame = frameRect
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        origFrame = self.frame
    }
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        if let gridPoint = self.gridPoint {
            ctx.beginPath()
            ctx.setStrokeColor(CGColor(_colorLiteralRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
            let numberOfNotes = gridPoint.maxNote - gridPoint.minNote + 1
            for index in 0...numberOfNotes {
                
                let startY = bounds.height / CGFloat(numberOfNotes) * CGFloat(index)
                if startY <=  dirtyRect.maxY && startY >= dirtyRect.minY  {
                    ctx.move(to: CGPoint(x: 0.0, y:startY))
                    ctx.addLine(to: CGPoint(x: bounds.maxX, y: startY))
                }
            }
            ctx.closePath()
            ctx.strokePath()
            
        }
        
        if let rects = self.noteRects {
            var count = 0
            
            for rect in rects {
                let minX = rect.x * bounds.width
                let minY = rect.y * bounds.height
                let height = rect.height * bounds.height
                let width = rect.width * bounds.width
                let maxX = minX + width
                let maxY = minY + height
                if ( dirtyRect.minX < maxX && dirtyRect.maxX > minX && dirtyRect.minY < maxY && dirtyRect.maxY > minY ) {
                    count += 1
                    if count == 1 {
                        ctx.beginPath()
                    }
                    let rectArea = CGRect(x: minX, y: minY, width: width, height: height)
                    ctx.addRect(rectArea)
                    
                }
            }
            ctx.setFillColor(CGColor(_colorLiteralRed: 0.0, green: 1.0, blue: 0.9, alpha: 1.0))
            
            /*  to avoid CGContecxtClosePath no point error, we need the following if block*/
            if count != 0 {
                ctx.closePath()
                ctx.fillPath()
            }
        }
         
    }
    
    
    
    func updateFreqChart(_ pointData:[PointData]){
        self.pointData = pointData
        self.setNeedsDisplay()
    }
    
    
    func updateMidiNotes(_ noteRects:[NoteRect]){
        self.noteRects = noteRects
        self.setNeedsDisplay()
        
    }
    
    func updateGrid(_ gridPoint:GridPoint){
        self.gridPoint = gridPoint
        self.setNeedsDisplay()
    }
        
}

struct NoteRect {
    var x:CGFloat
    var y:CGFloat
    var width:CGFloat
    var height:CGFloat
}

struct PointData {
    var x:CGFloat
    var y:CGFloat
    var move:Bool
}
struct GridPoint {
    var minNote:Int
    var maxNote:Int
}
