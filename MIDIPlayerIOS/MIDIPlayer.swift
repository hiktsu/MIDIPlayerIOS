//
//  MIDIPlayer.swift
//  MIDIPlayer
//
//  Created by 露峰光 on 2022/12/14.
//

import Foundation
import AVFoundation

class MIDIPlayer {
    
    let engine:AVAudioEngine
    var mainSequencer:AVAudioSequencer
    var samplers:[AVAudioUnitSampler] = []
    var status:MIDIPlayerStatus
    let soundFontURL:URL
    var currentPositionInBeat: Double {
        mainSequencer.currentPositionInBeats
    }
    
    init(_ soundFontURL:URL) {
        self.engine = AVAudioEngine()
        // since AVAudioSequencer can't be created without sampler, we create a dummy one
        let dummySampler = AVAudioUnitSampler()
        self.engine.attach(dummySampler)
        self.engine.connect(dummySampler, to: engine.mainMixerNode, format: dummySampler.outputFormat(forBus: 0))
        self.mainSequencer = AVAudioSequencer(audioEngine: engine)
        status = .initilized
        self.soundFontURL = soundFontURL
    }
    
    init?() {
        self.engine = AVAudioEngine()
        // since AVAudioSequencer can't be created without sampler, we create a dummy one
        let dummySampler = AVAudioUnitSampler()
        self.engine.attach(dummySampler)
        self.engine.connect(dummySampler, to: engine.mainMixerNode, format: dummySampler.outputFormat(forBus: 0))
        self.engine.connect(self.engine.mainMixerNode, to: self.engine.outputNode, format: self.engine.outputNode.outputFormat(forBus: 0))
        self.mainSequencer = AVAudioSequencer(audioEngine: engine)
        status = .initilized
        guard let soundFontURL = Bundle.main.url(forResource: "GeneralUser", withExtension: "sf2") else {
            print("can't access soundFont")
            return nil
        }
        self.soundFontURL = soundFontURL
    }
    
    deinit {
        print("MIDIPlayer deinit")
    }
    
    func addMIDIFile(_ midiFile:URL) throws {
        if self.status == .playing {
            throw MIDIError.invalidState
        }
        let tmpSequencer = AVAudioSequencer()
        let _ = midiFile.startAccessingSecurityScopedResource()
        try tmpSequencer.load(from: midiFile,options: .smf_ChannelsToTracks)
        midiFile.stopAccessingSecurityScopedResource()
        let trackCount = tmpSequencer.tracks.count
        let range = AVBeatRange(start: 0, length: AVMusicTimeStampEndOfTrack)
        print("track count",trackCount)
        for track in 0 ..< trackCount {
            let sampler = AVAudioUnitSampler()
            self.samplers.append(sampler)
            let currentTrack = self.mainSequencer.createAndAppendTrack()
            self.engine.attach(sampler)
            self.engine.connect(sampler, to: self.engine.mainMixerNode, format: sampler.outputFormat(forBus: 0))
            currentTrack.destinationAudioUnit = sampler
            currentTrack.copyEvents(in: range, from: tmpSequencer.tracks[track], insertAt: 0)
            try loadSoundFont(sampler, track: currentTrack)
        }
        self.status = .readyToPlay
        NotificationCenter.default.post(name: .midiDataUpdated, object: nil)
    }
    
    
    // TODO: Need to fix crash on removeTrack() at this time, the func is not used. instead, recreate player upon loading a song
    func removeAllTracks() throws {
        if self.status == .playing {
            throw MIDIError.invalidState
        }
        for track in self.mainSequencer.tracks {
            if let sampler = track.destinationAudioUnit {
                self.engine.detach(sampler)
            }
            self.mainSequencer.removeTrack(track)
        }
        self.status = .initilized
        NotificationCenter.default.post(name: .midiDataUpdated, object: nil)
    }
    
    func replaceMIDIonTrack(_ midiFile:URL,_ sourceTrack:Int,_ targetTrack:Int) throws {
        if self.status == .playing {
            throw MIDIError.invalidState
        }
        if targetTrack >= self.mainSequencer.tracks.count {
            throw MIDIError.invalidParameter
        }
        
        let tmpSequencer = AVAudioSequencer()
        try tmpSequencer.load(from: midiFile,options: .smf_ChannelsToTracks)
        let trackCount = tmpSequencer.tracks.count
        if sourceTrack >= trackCount {
            throw MIDIError.invalidParameter
        }
        let range = AVBeatRange(start: 0, length: AVMusicTimeStampEndOfTrack)
        let currentTrack = self.mainSequencer.tracks[targetTrack]
        
        guard let sampler =  currentTrack.destinationAudioUnit else {
            throw MIDIError.invalidState
        }
        currentTrack.clearEvents(in: range)
        currentTrack.copyEvents(in: range, from: tmpSequencer.tracks[sourceTrack], insertAt: 0)
        try loadSoundFont(sampler as! AVAudioUnitSampler, track: currentTrack)
        self.status = .readyToPlay
        NotificationCenter.default.post(name: .midiDataUpdated, object: nil)
    }
    
    private func loadSoundFont(_ sampler:AVAudioUnitSampler,track:AVMusicTrack) throws {
        let drumChannel = 9
        let range = AVMakeBeatRange(0, AVMusicTimeStampEndOfTrack)
        var isDrum = false
        var program:UInt32 = 0
        track.enumerateEvents(in: range){
            event,timeStamp,removeEvent  in
            switch event.self {
            case is  AVMIDINoteEvent :
                if (event as! AVMIDINoteEvent).channel == drumChannel {
                    isDrum = true
                    break
                }
            case is AVMIDIProgramChangeEvent :
                program = (event as! AVMIDIProgramChangeEvent).programNumber
                print("program number",program)
                break
            default :
                break
            }
        }
        if isDrum {
            try sampler.loadSoundBankInstrument(at: self.soundFontURL, program: UInt8(0), bankMSB: 0x78, bankLSB: 0)
        }
        else {
            try sampler.loadSoundBankInstrument(at: self.soundFontURL, program: UInt8(program), bankMSB: 0x79, bankLSB: 0)
        }
    }
    
    func updateVolume(_ velocity:UInt32,_ noteNum:Int,_ trackNumber:Int){
//        let track = self.mainSequencer.tracks[trackNumber]
        let range = AVMakeBeatRange(0, AVMusicTimeStampEndOfTrack)
        for track in self.mainSequencer.tracks {
            track.enumerateEvents(in: range){
                event,timeStamp,removeEvent  in
                if event.self is AVMIDINoteEvent && (event as! AVMIDINoteEvent).key == noteNum {
//                    let origVelocity = (event as! AVMIDINoteEvent).velocity
                    (event as! AVMIDINoteEvent).velocity = velocity
                }
            }
        }
        
    }
    
    func play()  throws {
        print("samplers count",samplers.count)
        if self.status == .readyToPlay {
            if !self.engine.isRunning {
                do {
                    try self.engine.start()
                }
                catch {
                    self.status = .failed
                    throw error
                }
            }
            do {
                self.mainSequencer.prepareToPlay()
                try mainSequencer.start()
            }
            catch {
                self.status = .failed
                throw error
            }
            self.status = .playing
        }
    }
    
    func stop() {
        self.mainSequencer.stop()
//        self.engine.stop()
        self.status = .readyToPlay
    }
    
    func skip(_ beat:TimeInterval){
        self.mainSequencer.currentPositionInBeats = beat
    }
    
    func skipInSeconds(_ seconds:TimeInterval){
        self.mainSequencer.currentPositionInSeconds = seconds
    }
    
    func rewind(){
        self.mainSequencer.currentPositionInSeconds = 0
    }
    
    func updatePlaybackRate(_ rate:Float){
        self.mainSequencer.rate = rate
    }
    
}

enum MIDIPlayerStatus {
    case initilized
    case readyToPlay
    case playing
    case failed
}

enum MIDIError:Error {
    case invalidState
    case invalidParameter
}
