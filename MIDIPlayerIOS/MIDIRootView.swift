//
//  MIDIRootView.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2023/01/04.
//

import Foundation
import UIKit

class MIDIRootView:UIView {
    let midiView:MIDIView
    var midiViewWidthRatio = 0.9
    var midiViewHeightRatio = 0.9
    var midiViewBackgroundColor = UIColor.gray
    
    let midiRulerView:MIDIRulerView
    var midiRulerViewBackgroundColor = UIColor.darkGray
    var midiRulerViewWidthRatio:Double {
        midiViewWidthRatio
    }
    var midiRulerViewHeightRatio:Double {
        1.0 - midiViewHeightRatio
    }
    
    let midiPianoRollView:MIDIPianoRollView
    var midiPianoRollViewBackgroundColor = UIColor.gray
    var midiPianoRollViewWidthRatio:Double {
        1.0 - midiViewWidthRatio
    }
    var midiPianoRollViewHeightRatio:Double {
        midiViewHeightRatio
    }
    var maxVerticalOffset:Double {
        midiView.maxVerticalOffset
    }
    var minVerticalOffset:Double {
        midiView.minVerticalOffset
    }
    // default visible duration in beat 60beats = 30sec for 120BPM
    var visibleDuration:Double = 60 {
        didSet{
            midiView.setNeedsDisplay()
            midiRulerView.setNeedsDisplay()
        }
    }
   
    var visiblePitch:Double = 47 {
        didSet {
            midiView.setNeedsDisplay()
            midiPianoRollView.setNeedsDisplay()
        }
    }
    // number of piches the view supports to display
    let numberOfPitch:Double = 47
    var lowestPitch:Double = 35 // define lowest pitch number displayed on the view
    var currentPositionInBeat:Double = 0 { // indicate the position crrently playing. it is updated by viewmodel
        didSet {
            midiView.setNeedsDisplay()
            midiRulerView.setNeedsDisplay()
            //            midiPianoRollView.setNeedsDisplay()
        }
    }
//    var panStartFlag = false
    var horizontalDrawOffset:Double = 0 { // offset value in view cordinate to use drawing position on the view. user can cahnge it by the operation such as dragging on the window
        didSet{
//            self.setNeedsDisplay()
            midiView.setNeedsDisplay()
            midiRulerView.setNeedsDisplay()
            midiPianoRollView.setNeedsDisplay()
        }
    }
    
    var verticalDrawOffset:Double = 0  {
        didSet {
            midiView.setNeedsDisplay()
            midiRulerView.setNeedsDisplay()
            midiPianoRollView.setNeedsDisplay()
        }
    }
    
    var visibleStartPoint:Double { // always indicate the starting time position in beat drawn on the window (left edge)
        var start = currentPositionInBeat - visibleDuration / 2.0
        if start < 0 {
            start = 0
        }
        return start
        
    }
    
    var visibleEndPoint :Double {
        visibleStartPoint + visibleDuration
    }
    
    var trackLength:Double?
    var noteRects:[CGRect]?
    
    
    override init(frame: CGRect) {
        midiView = MIDIView(frame: frame)
        midiRulerView = MIDIRulerView(frame: frame)
        midiPianoRollView = MIDIPianoRollView(frame: frame)
        super.init(frame: frame)
        midiView.backgroundColor = midiViewBackgroundColor
        addSubview(midiView)
        midiRulerView.backgroundColor = self.midiRulerViewBackgroundColor
        addSubview(midiRulerView)
    }
    
    required init?(coder: NSCoder) {
        midiView = MIDIView(coder: coder)!
        midiRulerView = MIDIRulerView(coder: coder)!
        midiPianoRollView = MIDIPianoRollView(coder: coder)!
        super.init(coder: coder)
        midiView.backgroundColor = self.midiViewBackgroundColor
        addSubview(midiView)
        midiRulerView.backgroundColor = self.midiRulerViewBackgroundColor
        addSubview(midiRulerView)
        midiPianoRollView.backgroundColor = self.midiPianoRollViewBackgroundColor
        addSubview(midiPianoRollView)
        
    }
    override func layoutSubviews() {
        print("root frame",frame)
        print("midiview frame",midiView.frame)
        midiView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: midiViewWidthRatio).isActive = true
        midiView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: midiViewHeightRatio).isActive = true
        midiView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        midiView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        midiRulerView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: midiRulerViewWidthRatio).isActive = true
        midiRulerView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: midiRulerViewHeightRatio).isActive = true
        midiRulerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0).isActive = true
        midiRulerView.trailingAnchor.constraint(equalTo:self.trailingAnchor, constant: 0.0).isActive = true
        
        midiPianoRollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        midiPianoRollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        midiPianoRollView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: midiPianoRollViewWidthRatio).isActive = true
        midiPianoRollView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: midiPianoRollViewHeightRatio).isActive = true
    }
}
