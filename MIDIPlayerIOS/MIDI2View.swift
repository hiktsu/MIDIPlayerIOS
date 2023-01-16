//
//  MIDI2View.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2022/12/21.
//

import Foundation
import UIKit
import CoreGraphics
import AVFoundation

class MIDI2View: UIView {
    let defaultVisibleDuration:Double = 60 // default visible duration in beat 60beats = 30sec for 120BPM
    let defaultVisiblePitch:Double = 128
    let numberOfPitch:Double = 128
    
    var trackLength:Double?
    var noteRects:[CGRect]?
    var gridPoint:GridPoint?
    var scrollView:UIScrollView? {
        self.superview as? UIScrollView
    }
    var horizontalScale:Float = 1.0
    var verticalScale:Float = 1.0
    var origFrame:CGRect?
    
    override init(frame frameRect: CGRect) {
        origFrame = frameRect
        super.init(frame: frameRect)
//        print("init bounds",bounds)
//        print("scrollView in init bounds",self.scrollView?.bounds)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        origFrame = self.frame
//        print("init bounds",bounds)
//        print("scrollView in init bounds",self.scrollView?.bounds)
    }
    override func draw(_ dirtyRect: CGRect) {
//        print("midiview draw called",bounds,"frame",frame)
//        print("scrollView in draw bounds",self.scrollView?.bounds)
        super.draw(dirtyRect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        // scale to fit the current view size vertically and convert upper left origin to lower left
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0 , y: -1.0)
        if let rects = self.noteRects {
            ctx.beginPath()
            ctx.setFillColor(CGColor(_colorLiteralRed: 0.0, green: 1.0, blue: 0.9, alpha: 1.0))
            ctx.setLineWidth(0.1)
            ctx.setStrokeColor(UIColor.red.cgColor)
            ctx.addRects(rects)
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
        }
    }
    func updateMidiNotes(_ noteRects:[CGRect],_ length:Double){
        guard let scrollView = self.scrollView  else {
            print("scrollView is nil")
            return
        }
        self.trackLength = length
        let horizontalRatio = scrollView.frame.width  / Double(self.defaultVisibleDuration) * Double(horizontalScale)
        let verticalRatio = scrollView.frame.height / self.defaultVisiblePitch * Double(verticalScale)
        
        self.noteRects = noteRects.map{ CGRect(x: $0.midX * horizontalRatio, y: $0.midY * verticalRatio, width: $0.width * horizontalRatio, height: $0.height * verticalRatio) }
        
        self.setNeedsDisplay()
        
    }
}


