//
//  ViewController.swift
//  HandsFreeBluetooth
//
//  Created by Dave Schmitz on 10/9/18.
//  Copyright © 2018 Bose. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
  
  // UI components
  @IBOutlet weak var startStopButton: UIButton!
  @IBOutlet weak var statusLabel: UILabel!
  
  // Audio session components
  var audioEngine = AVAudioEngine()
  let audioPlayer = AVAudioPlayerNode()
  let audioSession = AVAudioSession.sharedInstance()

  //
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup notifucations for route changes and interruptions
    setupNotifications()
    
    // Create the audio session used to receive and send voice over the HFP bluetooth connection
    do {
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
      try audioSession.setActive(true)
    } catch {
        print(error)
    }
    
    // Check the current audio session route for a hands free connection type
    isCurrentRouteHFP()
    
    // Construct the audio engine, attach an audio audioPlayer
    audioEngine.attach(audioPlayer)

    let bus = 0
    let input = audioEngine.inputNode
    let inputFormat = input.inputFormat(forBus: bus)
    audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: inputFormat)

    // Forward received audio buffers back to the audioPlayer
    input.installTap(onBus: bus, bufferSize: 512, format: inputFormat) { (buffer, time) -> Void in
        self.audioPlayer.scheduleBuffer(buffer)
    }
  }
  
  // Setup notifications for AVAudioSession events
  func setupNotifications() {
      let notificationCenter = NotificationCenter.default
      notificationCenter.addObserver(self,
                                     selector: #selector(handleRouteChange),
                                     name: AVAudioSession.routeChangeNotification,
                                     object: nil)
      notificationCenter.addObserver(self,
                                     selector: #selector(handleInterruption),
                                     name: AVAudioSession.interruptionNotification,
                                     object: nil)
  }
  
  // Check to see if the current audio route is connected to a hands free device then update UI
  func isCurrentRouteHFP() {
  
    var inputRouteHFP = false
    var outputRouteHFP = false
    
    // Check inputs for handsfree
    let inputs = audioSession.currentRoute.inputs
    if inputs.count != 0 {
        for input in inputs {
          if input.portType == AVAudioSession.Port.bluetoothHFP {
            inputRouteHFP = true
          }
        }
    }
    
    // Check output for handsfree
    let outputs = audioSession.currentRoute.outputs
    if outputs.count != 0 {
        for output in outputs {
          if output.portType == AVAudioSession.Port.bluetoothHFP {
            outputRouteHFP = true
          }
        }
    }

    // Update UI
    DispatchQueue.main.async {
      if(inputRouteHFP && outputRouteHFP) {
        self.startStopButton.isEnabled = true
        self.statusLabel.text = "Hands free device connected"
      }
      else {
        self.startStopButton.isEnabled = false
        self.statusLabel.text = "Please connect your hands free device"
        self.stopStream()
      }
      self.statusLabel.sizeToFit()
    }
  }
  
  // Toggle the listening/playing of handfree audio stream
  @IBAction func toggleStream(_ sender: Any) {
    
    if((audioEngine.isRunning || audioPlayer.isPlaying)) {
      stopStream()
    }
    else {
      startStream()
    }
  }
  
  // Start listening/playing
  func startStream() {
    do {
      try audioEngine.start()
      audioPlayer.play()
    } catch {
      statusLabel.text = (error as! String)
    }
    
    // Update UI
    DispatchQueue.main.async {
      self.startStopButton.setTitle("Stop Stream", for: .normal)
    }
  }
  
  // Stop listening/playing
  func stopStream() {
    if( audioEngine.isRunning || audioPlayer.isPlaying) {
      audioEngine.stop()
      audioPlayer.stop()
    }
    
    // Update UI
    DispatchQueue.main.async {
      self.startStopButton.setTitle("Start Stream", for: .normal)
    }
  }
  
  // Handle a audio route change
  @objc func handleRouteChange(notification: Notification) {
    isCurrentRouteHFP()
  }
  
  // Handle an audio device interruption (i.e. phone call, music playing, etc...)
  @objc func handleInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
        let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
    }
    if type == .began {
        // Interruption began, take appropriate actions
        stopStream()
      
        // Update UI
        DispatchQueue.main.async {
          self.statusLabel.text = "Hands free audio stream interrupted"
          self.statusLabel.sizeToFit()
        }
    }
    else if type == .ended {
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          startStream()
          
          // Update UI
          DispatchQueue.main.async {
            self.statusLabel.text = "Hands free audio stream resumed"
            self.statusLabel.sizeToFit()
          }
        } else {
          stopStream()
          // Update UI
          DispatchQueue.main.async {
            self.statusLabel.text = "Hands free audio stream stopped"
            self.statusLabel.sizeToFit()
          }
        }
      }
    }
  }
}

