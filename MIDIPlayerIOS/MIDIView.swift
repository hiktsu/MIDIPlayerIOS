//
//  MIDIView.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2022/12/18.
//

import Foundation
import UIKit
import CoreGraphics
import AVFoundation

class MIDIView: UIView {
    let margine:CGFloat = 20.0
    var trackLength:Double?
    var noteRects:[CGRect]?
    var gridPoint:GridPoint?
    var scrollView:UIScrollView? {
        self.superview as? UIScrollView
    }
    var horizontalScale:Float = 1.0 {
        didSet {
            if let origFrame = origFrame {
                self.frame = CGRect(x: origFrame.minX, y: origFrame.minY, width: origFrame.width * CGFloat(horizontalScale), height: origFrame.height * CGFloat(verticalScale))
                scrollView?.contentSize = CGSize(width: self.frame.width, height: self.frame.height)
                self.setNeedsDisplay()
                print("horizontalScale updated",bounds)
            }
        }
    }
    
    var verticalScale:Float = 1.0 {
        didSet {
            if let origFrame = origFrame {
                self.frame = CGRect(x: origFrame.minX, y: origFrame.minY, width: origFrame.width * CGFloat(horizontalScale), height: origFrame.height * CGFloat(verticalScale))
                scrollView?.contentSize = CGSize(width: self.frame.width, height: self.frame.height)
                self.setNeedsDisplay()
                print("verticalScale updated",bounds)
            }
        }
    }
    var origFrame:CGRect?
    
    override init(frame frameRect: CGRect) {
        origFrame = frameRect
        super.init(frame: frameRect)
        print("init bounds",bounds)
        print("scrollView in init bounds",self.scrollView?.bounds)
//        self.autoresizesSubviews = true
//        self.translatesAutoresizingMaskIntoConstraints = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        origFrame = self.frame
        print("init bounds",bounds)
        print("scrollView in init bounds",self.scrollView?.bounds)
//        self.autoresizesSubviews = true
//        self.translatesAutoresizingMaskIntoConstraints = true
    }
    override func draw(_ dirtyRect: CGRect) {
        print("midiview draw called",bounds,"frame",frame)
        print("scrollView in draw bounds",self.scrollView?.bounds)
        super.draw(dirtyRect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        
        
        // scale to fit the current view size vertically and convert upper left origin to lower left
        ctx.translateBy(x: 0, y: bounds.height)
        
        let verticalScaleRatio = bounds.height / 128.0
        let horizontalScaleRatio = bounds.width / 30.0
        ctx.scaleBy(x: horizontalScaleRatio, y: -verticalScaleRatio)
        
        
        
        if let rects = self.noteRects {
            ctx.beginPath()
            ctx.setFillColor(CGColor(_colorLiteralRed: 0.0, green: 1.0, blue: 0.9, alpha: 1.0))
            ctx.setLineWidth(0.1)
            ctx.setStrokeColor(UIColor.red.cgColor)
            ctx.addRects(rects)
            ctx.closePath()
            //ctx.drawPath(using: .fillStroke)
            ctx.fillPath()
        }
    }
    func updateMidiNotes(_ noteRects:[CGRect],_ length:Double){
        self.noteRects = noteRects
        self.trackLength = length
        self.setNeedsDisplay()
        
    }
    
    
}


