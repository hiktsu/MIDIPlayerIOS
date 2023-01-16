//
//  ViewController.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2022/12/15.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import Combine

class ViewController: UIViewController,UIDocumentPickerDelegate {

    var midiViewModel:MIDIPlayerViewModel?
    let defaultVisibleDuration:Double = 20 // default visible duration in beat 60beats = 30sec for 120BPM
    let defaultVisiblePitch:Double = 47
    var maxLength:Double?
    var panStartPoint:Double = 0
    
    @Published private var horizontalScaleFactor:Double = 1.0
    @Published private var verticalScaleFactor:Double = 1.0
    
    private var cancellables = Set<AnyCancellable>()
    private var savedDrawOffset = CGPoint(x: 0.0, y: 0.0)
    
    @IBOutlet weak var speedRateSlider: UISlider!
    @IBOutlet weak var horizontalScaleSlider: UISlider!
    @IBOutlet weak var verticalScaleSlider: UISlider!
    
    @IBOutlet weak var midiRootView: MIDIRootView!
    @IBOutlet weak var currentPositionSlider: UISlider!
    
    @IBAction func velocityAction(_ sender: UIButton) {
        midiViewModel?.updateVolume(0, 38)
    }
    
    @objc func panGeatureAction(_ sender: UIPanGestureRecognizer) {
        let x = sender.translation(in: midiRootView.midiView).x + self.savedDrawOffset.x
        let y = sender.translation(in: midiRootView.midiView).y + self.savedDrawOffset.y
        midiRootView.horizontalDrawOffset = x
        midiRootView.verticalDrawOffset = y
        
        if sender.state == .ended {
            // to avoid over scrolling vertically, savedDrawOffset.y limitted between min and max allowed offset
            let limittedY = max( min(y, midiRootView.maxVerticalOffset),midiRootView.minVerticalOffset)
            self.savedDrawOffset = CGPoint(x: x, y: limittedY)
        }
    }
    
    @objc func midiRootViewPinchGestureAction(_ sender:UIPinchGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            self.horizontalScaleFactor = max(1.0,self.horizontalScaleFactor * sender.scale)
            
            self.verticalScaleFactor = max(1.0,self.verticalScaleFactor * sender.scale)
            sender.scale = 1.0
        }
        
    }
    
    @objc func midiPianoRollViewTapGestureAction(_ sender:UITapGestureRecognizer){
        if sender.state == .ended {
            print("tap gesture ended")
            let point = sender.location(in: midiRootView.midiPianoRollView)
            let pitch = midiRootView.midiPianoRollView.YToPitch(midiRootView.midiPianoRollView.bounds.height -  point.y)
            print("point",point,"pitch",pitch)
        }
    }
    @IBAction func currentPositionSlider(_ sender: Any) {
        print("slider action")
        if let length =  self.maxLength,let viewModel = self.midiViewModel {
            viewModel.skip(length * Double((sender as! UISlider).value))
        }
    }
    @IBAction func speedRateAction(_ sender: UISlider) {
        if let vm = self.midiViewModel {
            vm.playbackRate = sender.value
        }
    }
    @IBAction func horizontalScaleAction(_ sender: UISlider) {
//        midiRootView.visibleDuration = defaultVisibleDuration / Double(sender.value)
//        midiRootView.midiView.setNeedsDisplay()
        horizontalScaleFactor = Double(sender.value)
    }
    
    @IBAction func verticalScaleAction(_ sender: UISlider) {
//        midiRootView.visiblePitch = defaultVisiblePitch / Double(sender.value)
        verticalScaleFactor = Double(sender.value)
    }
    @IBAction func stopAction(_ sender: Any) {
        self.midiViewModel?.stop()
    }
    
    @IBAction func playAction(_ sender: Any) {
        
        do {
            try midiViewModel?.play()
            midiRootView.horizontalDrawOffset = 0
            self.savedDrawOffset.x = 0
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rewindAction(_ sender: Any) {
        self.midiViewModel?.rewind()
    }
    @IBAction func loadAction(_ sender: Any) {
        let docType = [UTType.midi]
        
        print("docType",docType)
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: docType)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker,animated: true,completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.midiRootView.visiblePitch = defaultVisiblePitch
        
        self.midiViewModel = MIDIPlayerViewModel()
        self.midiViewModel?.createPlayer()
        self.midiViewModel!.$midiRects.sink {
            midiRect in
            print("midi rect updated")
            if midiRect.count > 0, let length = self.getMaxLength(midiRect){
                self.maxLength = length
                self.midiRootView.midiView.updateMidiNotes(midiRect[0].rects,length )
            }
        }.store(in: &cancellables)
        
        self.midiViewModel!.$currentPositionInBeat.sink {
            position in
            self.midiRootView.currentPositionInBeat = position
        }.store(in: &cancellables)
        
        self.midiViewModel!.$currentPositionInBeat.map{Float($0 / (self.midiRootView.trackLength ?? 0.0))}.assign(to: \.value, on:self.currentPositionSlider ).store(in: &cancellables)
        
        let midiViewPanRecognizer = UIPanGestureRecognizer(target: self, action:#selector(panGeatureAction(_:)) )
        midiViewPanRecognizer.allowedScrollTypesMask = .all
        midiRootView.midiView.addGestureRecognizer(midiViewPanRecognizer)
        
        let midiRootViewPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(midiRootViewPinchGestureAction(_:)))
        midiRootView.midiView.addGestureRecognizer(midiRootViewPinchGestureRecognizer)
        
        let midiPianoRollViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(midiPianoRollViewTapGestureAction(_:)))
        midiRootView.midiPianoRollView.addGestureRecognizer(midiPianoRollViewTapGestureRecognizer)
        
        $horizontalScaleFactor.sink{ value in
            self.midiRootView.visibleDuration = self.defaultVisibleDuration / value
        }.store(in: &cancellables)
        $horizontalScaleFactor.map{Float($0)}.assign(to: \.value, on: self.horizontalScaleSlider).store(in: &cancellables)
        
        $verticalScaleFactor.sink{ value in
            self.midiRootView.visiblePitch = self.defaultVisiblePitch / value
        }.store(in: &cancellables)
        $verticalScaleFactor.map{Float($0)}.assign(to: \.value, on: self.verticalScaleSlider).store(in: &cancellables)
        
        self.midiViewModel!.$playbackRate.assign(to: \.value, on: self.speedRateSlider).store(in: &cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("midi view frame in viewDidAppear",midiRootView.midiView.frame)

    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if  let sourceURL = urls.first,let viewModel = self.midiViewModel {
            do {
                viewModel.createPlayer()
//                try viewModel.removeAllTracks()
                try viewModel.addMIDIFile(sourceURL)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getMaxLength(_ rects:[MIDIRects]) -> Double? {
        return rects.map{$0.length}.max()
    }
    
}

extension CGPoint {
    static func +(_ input1:CGPoint,_ input2:CGPoint) -> CGPoint {
        return CGPoint(x: input1.x + input2.x, y: input1.y + input2.y)
    }
    
    static func +=( left:inout CGPoint,right:CGPoint) {
        left = left + right
    }
}
