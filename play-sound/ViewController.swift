//
//  ViewController.swift
//  play-sound
//
//  Created by うえだこじろう on 2019/05/21.
//  Copyright © 2019 うえだこじろう. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class ViewController: UIViewController {
    var wrapper: AudioUnitWrapper?
    override func viewDidLoad() {
        super.viewDidLoad()
        wrapper = AudioUnitWrapper()
    }

    @IBAction
    func recordToggle() {
        wrapper!.recordToggle()
        recordLabel?.text = "Recording: \(String(describing: wrapper?.recording))"
        playButton?.isEnabled = !(wrapper?.recording ?? true)
    }
    
    @IBAction
    func playToggle() {
        wrapper!.playToggle()
        playLabel?.text = "Playing: \(String(describing: wrapper?.playing))"
        recordButton?.isEnabled = !(wrapper?.playing ?? true)
    }
    
    @IBOutlet
    var recordLabel: UILabel?
    
    @IBOutlet
    var playLabel: UILabel?
    
    @IBOutlet
    var recordButton: UIButton?
    
    @IBOutlet
    var playButton: UIButton?
}

class AudioUnitWrapper {
    let au: AUAudioUnit
    var buffers: [UnsafeMutablePointer<AudioBufferList>] = []
    var recording = false
    var playing = false
    var playIndex = 0
    init() {
        au = try! AUAudioUnit(
            componentDescription: AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_RemoteIO,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
        );
        try! au.inputBusses[0].setFormat(AVAudioFormat(standardFormatWithSampleRate: Double( 44100 ), channels: 1)!)
        try! au.outputBusses[1].setFormat(au.inputBusses[0].format)
        au.isInputEnabled = true
        au.inputHandler = {( actionFlags, timestamp, numberFrames, busNumber ) in
            if !self.playing || self.buffers.count == 0 { return }
            let _ = self.au.renderBlock(
                actionFlags,
                timestamp,
                numberFrames,
                busNumber,
                self.buffers[self.playIndex],
                nil
            )
            self.playIndex = (self.playIndex + 1) % self.buffers.count
            print(self.playIndex)
        }
        
        au.outputProvider = {( actionFlags, timestamp, numberFrames, busNumber, data ) -> AUAudioUnitStatus in
            if !self.recording { return 0 }
            var elements = AudioBufferList()
            self.buffers.append(data)
            return 0;
        }
        
        try! au.allocateRenderResources()
        start()
    }
    
    func playToggle() {
        playing = !playing
        print(buffers.count)
    }
    
    func recordToggle() {
        recording = !recording
        print(buffers.count)
    }
    
    func start() {
        try! au.startHardware()
    }
    
    func stop() {
        au.stopHardware()
    }
}

