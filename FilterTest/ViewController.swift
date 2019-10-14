/*
 
 ViewController.swift
 FilterTest
 
 Created by Jair-Rohm Wells on 9/17/19.
 Copyright © 2019 Jair-Rohm Wells. All rights reserved.
 
 
 Stop filter works. Resonance for the stop filter works. I've created labels that display the values for the stop and resonance sliders. I need to figure out how the start filter works on the original pedal and implement that and the rate. The octave will be next. After i get sufficient sliders working, i'll change the orientation of the sliders to vertical.
 
 Maybe i'm going about this all wrong. As it is right now, i'm creating a separate audio clips that each get processed by their own effect. There is a "dist file" that is a copy of the clean file that gets put through
 a dist process. There is a "filtered file" that gets processed through a filter process, etc, etc... This isn't
 very smart.
 
 What i need to do is have one audio file that gets processed by different processes. I also need two sections:
 the filter section and the voicing section. How do i do that? Or shall i create a "BassClip" class which is the loop and then create a bunch of process functions that take an instance of BassClip as arguments? So that's two classes: BassClip and Processors.
 
 The Processors class has methods for:
 1. Variable LPF
 2. Dist
 3. Octave
 
 The Swift/AudioKit way of doing things is to send instances of AKNode to AudioKit.output()
 
 In the FilterEffects example, all of the effects and everything are done in viewDidLoad() Is this so bad? The UI is done in a setUp() This is a good way to do this.
 
 */

import UIKit
import AudioKitUI
import AudioKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var filtStartField: UITextField!
    @IBOutlet weak var filtResField: UITextField!
    @IBOutlet weak var filtStopField: UITextField!
    @IBOutlet weak var callousLabel: UILabel!
    @IBOutlet weak var clipStartBtn: UIButton!
    @IBOutlet weak var clipStopBtn: UIButton!
    @IBOutlet weak var filterStopSlider: UISlider!
    @IBOutlet weak var filterStartSlider: UISlider!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var distortionSlider: UILabel!
    
    @IBOutlet weak var attackSlider: UISlider!
    @IBOutlet weak var filtStartLabel: UILabel!
    @IBOutlet weak var resLabel: UILabel!
    @IBOutlet weak var filtStopLabel: UILabel!
    
    //MARK: - Property declarations
       /***************************************************************/
    // There are a bunch of properties here that need to be deleted. 
   
    var clipPlayer: AKPlayer!
    var freqSlider: AKSlider!
    var lpFilter = AKMoogLadder()
    var currentValue: Double = 0.0
    var resonance: Double = 0.0
    var addDist: Double = 0.0
    var dist: AKDistortion = AKDistortion()
    var mixer: AKMixer!
    var boostedDist: AKBooster = AKBooster()
    var boostedFilter: AKBooster = AKBooster()
    var boostedCleanBass: AKBooster = AKBooster()
    var myADSR: AKAmplitudeEnvelope! = AKAmplitudeEnvelope()
    var wetDry: AKDryWetMixer! = AKDryWetMixer()
    var lpfMixer: AKDryWetMixer!
    var distMixer: AKDryWetMixer!
    var octMixer: AKDryWetMixer!
    var booster: AKBooster!
    
    
    // Here is an implementation of an envelope follower: https://audiokit.io/playgrounds/Synthesis/Filter%20Envelope/
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - Signals
           /***************************************************************/
        if let mixloop = try? AKAudioFile(readFileName: "lovebotBassClip.wav") {
            clipPlayer = AKPlayer(audioFile: mixloop)
            clipPlayer.completionHandler = { Swift.print("completion callback has been triggered!") }
            clipPlayer.isLooping = true
            clipPlayer.buffering = .always
            lpFilter = AKMoogLadder(clipPlayer, cutoffFrequency: 60, resonance: 0.6)
            
            lpfMixer = AKDryWetMixer(clipPlayer, lpFilter)
            
            
            
            // This code is only for testing the distortion.
            let dist = AKDistortion(clipPlayer, delay: 0.5, decay: 0.5, delayMix: 0.5, decimation: 0.0, rounding: 0.222, decimationMix: 0.0, linearTerm: 1.0, squaredTerm: 0.960, cubicTerm: 1.9, polynomialMix: 0.5, ringModFreq1: 1700.0, ringModFreq2: 220.0, ringModBalance: 1.0, ringModMix: 0.0, softClipGain: 0.8, finalMix: 1)
            
            distMixer = AKDryWetMixer(lpfMixer, dist)
            //var distVolume = AKBooster(dist, gain: -12.0)
            
            let oct = AKPitchShifter(clipPlayer, shift: -12.00, windowSize: 0.5, crossfade: 0.5)
            octMixer = AKDryWetMixer(distMixer,oct)
            
            boostedFilter = AKBooster(lpFilter) // Put the filte through an AKBooster
            boostedFilter.gain = 5.0 //Raise the volume of the AKBooster for the filtered bass
            
            boostedDist = AKBooster(dist)
            boostedDist.gain = 0
            
            boostedCleanBass = AKBooster(clipPlayer)
            boostedCleanBass.gain = 17.25
            
            
            let daMix = AKMixer(boostedCleanBass, boostedDist, boostedFilter)
            daMix.volume = 2.25
            //this adsr isn't working. It dosen't output sound
            var myADSR = AKAmplitudeEnvelope(boostedCleanBass, attackDuration: 100.0, decayDuration: 1.1, sustainLevel: 1.0, releaseDuration: 0.1)
            // myADSR.start()
            
            //MARK: - Outputs
               /***************************************************************/
            AudioKit.output = AKBooster(myADSR, gain: 5)
            
            //Testing outputs
            //AudioKit.output = boostedDist
            // AudioKit.output = myADSR
            //AudioKit.output = boostedFilter
            //AudioKit.output = boostedCleanBass
            do {
                try AudioKit.start()
                print("AudioKit Started!")
            } catch {
                print(error)
            }
            myADSR.start()
        }
    }
    
    //MARK: - Methods for sliders and buttons
       /***************************************************************/
    //Double formatted to 2 decimal places.
    @IBAction func resonanceSlider(_ sender: UISlider) {
        resonance = Double(sender.value)
        lpFilter.resonance = resonance
        filtResField.text = (String (format:  "%.2f", resonance))
    }
    @IBAction func startFrequency(_ sender: UISlider) {
        
    }
    
    
    @IBAction func stopFrequency(_ sender: UISlider)  {
        currentValue = Double(sender.value)
        lpFilter.cutoffFrequency = currentValue
        filtStopField.text = (String (format:  "%.2f", currentValue))
    }
    
    @IBAction func stopClip(_ sender: Any) {
        clipPlayer.stop()
    }
    @IBAction func playClip(_ sender: Any) {
        clipPlayer.play()
    }
    
    func updateCurrentValue(value: Double) -> Double {
        currentValue = value
        
        return currentValue
    }
    
    @IBAction func callousnessSlider(_ sender: UISlider) {
        addDist = Double(sender.value)
        boostedDist.gain = addDist * 1.25
        boostedCleanBass.gain = addDist / 2.4
        print(addDist)
        callousLabel.text = String (format:  "%.2f", Double(sender.value))
        
    }
    //i'm not using this function
    //    func boostDist(level: Float) -> Double {
    //        boostedDist.gain = Double(level)
    //        print(boostedDist.gain)
    //        return boostedDist.gain
    
    //  }
    
    
    
    @IBAction func attackEnv(_ sender: UISlider) {
        myADSR.attackDuration = Double(sender.value * 100)
        print(myADSR.attackDuration)
    }
    
    
    func setupUI() {
        
    }
}

