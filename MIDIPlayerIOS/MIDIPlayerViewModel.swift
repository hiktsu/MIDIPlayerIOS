//
//  MIDIPlayerViewModel.swift
//  MIDIPlayerIOS
//
//  Created by 露峰光 on 2022/12/18.
//

import Foundation
import Combine
import AVFoundation

class MIDIPlayerViewModel : ObservableObject {

    var player:MIDIPlayer?
    var tracks: [AVMusicTrack]? {
        player?.mainSequencer.tracks
    }
    @Published var midiRects = [MIDIRects]()
    @Published var currentPositionInBeat:Double = 0.0
    @Published var playbackRate:Float = 1.0 {
        didSet {
            player?.mainSequencer.rate = playbackRate
        }
    }
    private var cachedCurrentPositionInBeat:Double = 0.0
    var maxLength:Double? {
        midiRects.map{$0.length}.max()
    }
    
    private let timerInterval:TimeInterval = 0.04
    private var timer:Timer?
    
    init(_ player:MIDIPlayer){
        self.player = player
        self.timer = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true, block: updateCurrentPosition(_:))
        NotificationCenter.default.addObserver(forName: .midiDataUpdated, object: nil, queue: nil, using: midiDataUpdated(_:))
    }
    
    init(){
        self.timer = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true, block: updateCurrentPosition(_:))
        NotificationCenter.default.addObserver(forName: .midiDataUpdated, object: nil, queue: nil, using: midiDataUpdated(_:))
    }
    
    deinit {
        self.timer?.invalidate()
    }
    
    func createPlayer(){
        if let player = MIDIPlayer()  {
            self.player = player
        }
    }
    
    func midiDataUpdated(_ notification:Notification) {
        updateAllMIDIRects()
    }
    
    func updateCurrentPosition(_ timer:Timer) {
        if let newPosition = player?.currentPositionInBeat, newPosition != self.cachedCurrentPositionInBeat {
            self.currentPositionInBeat = newPosition
            self.cachedCurrentPositionInBeat = newPosition
        }
//        self.currentPositionInBeat = player?.currentPositionInBeat ?? 0.0
    }
    
    func updateAllMIDIRects() {
        var midiRects = [MIDIRects]()
        guard let tracks = self.tracks else {
            return
        }
        for track in tracks {
            var rects = [CGRect]()
            
            var noteCount = 0
            var drumCount = 0
            let range = AVMakeBeatRange(0, AVMusicTimeStampEndOfTrack)
            print("lengthInBeats",track.lengthInBeats)
            track.enumerateEvents(in:range){
                event,timeStamp,removeEvent in
                if event.self is AVMIDINoteEvent {
                    let noteEvent = event as! AVMIDINoteEvent
//                    print("key",noteEvent.key,"duration",noteEvent.duration,"timeStamp",timeStamp.pointee)
                    if noteEvent.channel == 9 {
                        drumCount += 1
                    }
                    noteCount += 1
//                    rects.append(CGRect(x: timeStamp.pointee, y: Double(noteEvent.key), width: noteEvent.duration  , height: 1.0))
                    rects.append(CGRect(origin: CGPoint(x: timeStamp.pointee, y: Double(noteEvent.key)), size: CGSize(width: noteEvent.duration, height: 1.0)))
                }
            }
            let isDrum = Float(drumCount) / Float(noteCount) > 0.5 ? true : false
            midiRects.append(MIDIRects(rects: rects, selectedRects: [], length: track.lengthInBeats, isDrums: isDrum))
        }
        self.midiRects = midiRects
//        print("midirects in viewmodel",midiRects)
    }
    
    func play() throws {
        try self.player?.play()
    }
    
    func stop() {
        self.player?.stop()
    }
    
    func rewind() {
        self.player?.rewind()
    }
    
    func addMIDIFile(_ midiFile:URL) throws {
        try self.player?.addMIDIFile(midiFile)
    }
    
    func removeAllTracks() throws {
        try self.player?.removeAllTracks()
    }
    
    func skip(_ position:TimeInterval) {
        self.player?.skip(position)
    }
    func updateVolume(_ velocity:UInt32,_ noteNum:Int){
        if let tracks = self.tracks {
            let trackNumber = tracks.endIndex - 1
            self.player?.updateVolume(velocity, noteNum, trackNumber)
        }
    }
}

struct MIDIRects {
    var rects:[CGRect]
    var selectedRects:[CGRect]
    let length:Double
    let isDrums:Bool
    
    mutating func selectRect(_ index:Int){
        let selected = rects.remove(at: index)
        selectedRects.append(selected)
    }
    
    mutating func unselectRect(_ index:Int){
        let unselected = selectedRects.remove(at: index)
        rects.append(unselected)
    }
}

