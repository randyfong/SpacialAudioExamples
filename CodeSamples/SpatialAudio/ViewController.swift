//
//  ViewController
//  SpatialAudio
//
//  Created by Dave Schmitz on 10/9/18.
//  Copyright © 2018 Bose. All rights reserved.
//

import UIKit
import AVFoundation
import BoseWearable

class ViewController: UIViewController, WearableDeviceSessionDelegate, SensorDispatchHandler {
  
  // MARK: - UI Outlets
  @IBOutlet weak var startStopButton: UIButton!
  @IBOutlet weak var statusLabel: UILabel!
  
   // MARK: - Audio session components
  private var audioEngine = AVAudioEngine()
  private var audioEnvironment = AVAudioEnvironmentNode()
  private var audioPlayer = AVAudioPlayerNode()
  
  // MARK: - BoseWearable components
  private var boseDeviceSession: WearableDeviceSession?
  private var listenerToken: ListenerToken?
  private var sensorDispatch: SensorDispatch = SensorDispatch(queue: .main)
  private var yawOffset: Double?
  
  // MARK: - Constants
  struct Constants {
    static let BOSE_SENSOR_RATE     = SamplePeriod._40ms  // Bose sensor report rate (Hz)
    //static let BOSE_DELAYED_SENSOR_RATE     = SamplePeriod._320ms
    static let AUDIO_FILE_NAME      = "fishermansWharf_L" // Audio file, located in resource directory, ** must be monoaural, NOT stereo **
    static let AUDIO_FILE_NAME_EXT  = "mp3"               // audio file extension, any format supported by the iOS AVFoundation framework
  }
    
    // FIXME: Enhancement
    private func playMapName() {
        // Play Neighborhood Name
        let mapUtterance = AVSpeechUtterance(string: "North Beach")
        mapUtterance.voice  = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(mapUtterance)
    }
    
    // FIXME: Enhancement
    private func playNarration() {

        let narration = """
        North Beach, rich in Italian heritage, compresses cabarets, jazz clubs, galleries, inns, family style restaurants and gelato parlors into less than a square mile.
        
        A perfect spot for cappuccino and espresso, North Beach is transformed into one of San Francisco's most electric playgrounds by night; live music and dancing keep the streets swinging.
        
        In the morning practice tai chi with the regulars in Washington Square and from here, catch the No. 39 bus to the top of Telegraph Hill. Coit Tower atop Telegraph Hill offers amazing views.
        
        Thirty local artists painted murals on its ground floor walls in 1933. This hill is also laced with stairways off Filbert and Greenwich streets as well as lush gardens.
        """

        let narrationUtterance = AVSpeechUtterance(string: narration)
        narrationUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(narrationUtterance)

    }
  
  // MARK: - View Event Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Configure the iOS AVcomponents
    setupAudioEnvironment()
    
    // Listen for various notifications concerning audio playback
    setupNotifications()
    
    // Configure the Bose BLE connection, ** see AppDelegate for initialization **
    setupBoseDevice()
    
    updateStatusUI("Please connect your Bose device")
  }
  
  // MARK: - Setup and Configuration
  func setupAudioEnvironment() {
    
    // Configure the audio session
    let avSession = AVAudioSession.sharedInstance()
    do {
        // FIXME: Enhancement
              try avSession.setCategory(.soloAmbient, mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.default)), options: [.mixWithOthers] )
//      try avSession.setCategory(.playback, mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.default)), options: [.mixWithOthers] )
    } catch let error as NSError {
      print("Error setting AVAudioSession category: \(error.localizedDescription)\n")
    }
    
    // Configure audio buffer sizes
    let bufferDuration: TimeInterval = 0.005; // 5ms buffer duration
    try? avSession.setPreferredIOBufferDuration(bufferDuration)
    
    let desiredNumChannels = 2
    if avSession.maximumOutputNumberOfChannels >= desiredNumChannels {
      do {
        try avSession.setPreferredOutputNumberOfChannels(desiredNumChannels)
      } catch let error as NSError {
        print("Error setting PreferredOuputNumberOfChannels: \(error.localizedDescription)")
      }
    }
    
    //
    do {
      try avSession.setActive(true)
    } catch let error as NSError {
      print("Error setting session active: \(error.localizedDescription)\n")
    }
    
    // Configure the audio environment, initialize the listener to start at 0, facing front.
    audioEnvironment.listenerPosition  = AVAudioMake3DPoint(0, 0, 0)
    audioEnvironment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0.0, 0.0, 0.0)
    
    audioEngine.attach(audioEnvironment)
    
    // Configure the audio engine
    let hardwareSampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
    guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: 2) else { return }
    audioEngine.connect(audioEnvironment, to: audioEngine.outputNode, format: audioFormat)
    audioEngine.attach(audioPlayer)
    
    // Configure the audio player
    audioPlayer.renderingAlgorithm = .HRTFHQ
    audioPlayer.position = AVAudio3DPoint(x: 0.0, y: 0.0, z: -5.0)
    if let audioFileURL = Bundle.main.url(forResource: Constants.AUDIO_FILE_NAME, withExtension: Constants.AUDIO_FILE_NAME_EXT) {
      do {
        // Open the audio file
        let audioFile = try AVAudioFile(forReading: audioFileURL, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: false)
        
        // Loop the audio playback upon completion - reschedule the same file
        func loopCompletionHandler() {
          audioPlayer.scheduleFile(audioFile, at: nil, completionHandler: loopCompletionHandler)
        }
        
        audioEngine.connect(audioPlayer, to: audioEnvironment, format: audioFile.processingFormat)
        
        // Schedule the file for playback, see 'scheduleBuffer' for sceduling indivdual AVAudioBuffer/AVAudioPCMBuffer
        audioPlayer.scheduleFile(audioFile, at: nil, completionHandler: loopCompletionHandler)
      }
      catch {
        print(error.localizedDescription)
      }
    }
  }
  
  // Setup notifications for AVAudioSession events
  func setupNotifications() {
    
    // Interruption handler
    NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    
    // Route change handler
    NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    
    // Media services reset handler
    NotificationCenter.default.addObserver(self, selector: #selector(handleMediaServicesReset), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
  }
  
  // Setup Bose Wearable device
  func setupBoseDevice() {
    
    // Listen for incoming sensor data - see SensorDispatchHandler below
    sensorDispatch.handler = self
    
    BoseWearable.shared.startDeviceSearch(mode: .alwaysShowUI) { result in
      switch result {
      case .success(let session):
        // Session is open. See below.
        self.boseDeviceSession = session
        
        // Lets catch if the frames disconnect.
        self.boseDeviceSession!.delegate = self
        
        self.listenerToken = session.device?.addEventListener(queue: .main) { [weak self] event in
          switch event {
          case .didUpdateSensorConfiguration, .didUpdateSensorInformation:
            break
            
          case .didFailToWriteSensorConfiguration(let error):
            print("didFailToWriteSensorConfiguration: \(error)")
          default:
            break
          }
        }
        
        // Open the session - results reported via WearableDeviceSessionDelegate methods below
        session.open()
        
        // We are ready. Let the user begin.
        self.startStopButton.isEnabled = true
        self.statusLabel.text = "Connected to Bose device"
        self.statusLabel.sizeToFit()
        
      case .failure(let error):
        // an error occurred
        self.updateStatusUI("Bose device session failed: \(String(describing:error))")
        
      case .cancelled:
        print("Device session cancelled.")
      }
    }
  }
  
  // MARK: - WearableDeviceSessionDelegate
  
  func sessionDidOpen(_ session: WearableDeviceSession) {
    
    // Start the rotation sensor
    session.device?.configureSensors { config in
      config.disableAll()
      config.enable(sensor: .gameRotation, at: Constants.BOSE_SENSOR_RATE)
      //To enable shaking and nodding gestures capture gyro sensor data
      //config.enable(sensor: .gyroscope, at: Constants.BOSE_DELAYED_SENSOR_RATE)
    }

    //To enable the gestures
    /*
    session.device?.configureGestures { config in
       config.disableAll()
       config.set(gesture: .doubleTap, enabled: true)
    }
    */
  }
  
    //toggle the music based on the gesture
    /*
    func receivedGesture(type: GestureType, timestamp: SensorTimestamp) {
        if((audioEngine.isRunning)) {
            stopPlaying()
        } else {
            startPlaying()
        }
    }

    var prevGyroVector : Vector = simd_double3(Double(0), Double(0), Double(0))
    var prevTimeStamp : SensorTimestamp = 0

    func resetGyro() {
        prevGyroVector = simd_double3(Double(0), Double(0), Double(0))
        prevTimeStamp = 0
    }

    func gyroStop() {
        print("shaking")
        if((audioEngine.isRunning)) {
            stopPlaying()
            resetGyro()
        }
    }

    func gyroStart() {
        print("Nodding")
        if(!(audioEngine.isRunning)) {
            startPlaying()
            resetGyro()
        }
    }

    func assignVals(currVector: Vector, currTimestamp: SensorTimestamp){
        prevGyroVector = currVector
        prevTimeStamp = currTimestamp
    }

    func receivedGyroscope(vector: Vector, accuracy: VectorAccuracy, timestamp: SensorTimestamp) {
        if (vector.z < -50.0 || vector.z > 100.0) {
            if (vector.z < -50.0 && prevGyroVector.z > 100.0  && timestamp-prevTimeStamp < 700) {
                gyroStop()
            } else if (vector.z > 100.0 && prevGyroVector.z < -50.0  && timestamp-prevTimeStamp < 700) {
                gyroStop()
            }
            assignVals(currVector: vector, currTimestamp: timestamp)
        }

        if (vector.x < -50.0 || vector.x > 100.0) {
            if (vector.x < -50.0 && prevGyroVector.x > 100.0 && timestamp-prevTimeStamp < 700) {
                gyroStart()
            } else if (vector.x > 100.0 && prevGyroVector.x < -50.0  && timestamp-prevTimeStamp < 700) {
                gyroStart()
            }
            assignVals(currVector: vector, currTimestamp: timestamp)
        }
    }
    */

  func session(_ session: WearableDeviceSession, didFailToOpenWithError error: Error?) {
    
    if let error = error {
      print(error.localizedDescription)
    }
  }
  
  func session(_ session: WearableDeviceSession, didCloseWithError error: Error?) {
    
    if let error = error {
      print(error.localizedDescription)
    }
    
    if boseDeviceSession != nil {
      DispatchQueue.main.async {
        self.startStopButton.isEnabled = false
        self.updateStatusUI("Lost connection to the Bose device")
        
        // Try to reconnect.
        self.setupBoseDevice()
      }
    }
  }
  
  // MARK: - Playback Controls
  
  // Toggle audio playing
  @IBAction func togglePlaying(_ sender: Any) {
    if((audioEngine.isRunning)) {
      stopPlaying()
    }
    else {
      startPlaying()
    }
  }
  
  // Start playing
  func startPlaying() {
    // FIXME: Enhancement
    playMapName()
    
    do {
      
      // Reset the current head direction
      yawOffset = nil
      
      try audioEngine.start()
      audioPlayer.play()
    } catch {
      statusLabel.text = (error as! String)
    }
    
    // FIXME: Enhancement
//    try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
//    try? AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.default)
    playNarration()
    
    // Update UI
    DispatchQueue.main.async {
      self.startStopButton.setTitle("Stop Playing", for: .normal)
    }
  }
  
  // Stop playing
  func stopPlaying() {
    if(audioEngine.isRunning || audioPlayer.isPlaying) {
      audioEngine.stop()
      audioPlayer.stop()
    }
    
    // Update UI
    DispatchQueue.main.async {
      self.startStopButton.setTitle("Start Playing", for: .normal)
      self.statusLabel.text = ""
    }
  }
  
  // Handle a audio route change
  @objc func handleRouteChange(notification: Notification) {
    updateStatusUI("Audio route changed")
  }
  
  // MARK: - SensorDispatchHandler
  
  // Orientation information received from the BoseWearable device
  func receivedGameRotation(quaternion: Quaternion, timestamp: SensorTimestamp) {
    // rad -> deg
    func degrees(fromRadians radians: Double) -> Double {
      return radians * 180.0 / .pi
    }
    
    // If needed, use the current yaw as the offset so the sound direction is directly in front
    if yawOffset == nil {
      yawOffset = degrees(fromRadians: quaternion.yaw)
    }
    var yaw = Float(degrees(fromRadians: quaternion.yaw) - yawOffset!)
    
    // Wrap around whatever the offset could have done, to bring the angle back in range.
    while yaw < -180.0 {
      yaw += 360.0
    }
    
    while yaw > 180 {
      yaw -= 360
    }
    
    let pitch = Float(degrees(fromRadians: quaternion.pitch))
    let roll = Float(degrees(fromRadians: quaternion.roll))
    
    // Update the listerner position in space
    audioEnvironment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(yaw, pitch, roll)
    
    // Update UI with the current degrees off listening center
    if(audioPlayer.isPlaying) {
      updateStatusUI(String(format: "%.1f˚", yaw))
    }
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
      stopPlaying()
      updateStatusUI("Audio playback interrupted")
    }
    else if type == .ended {
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          startPlaying()
          updateStatusUI("Audio playback resumed")
        } else {
          stopPlaying()
          updateStatusUI("Audio playback stopped")
        }
      }
    }
  }
  
  //
  func updateStatusUI(_ status: String) {
    // Update UI
    DispatchQueue.main.async {
      self.statusLabel.text = status
    }
  }
  
  //
  @objc private func handleMediaServicesReset(_ notification: NSNotification) {
    
    setupAudioEnvironment()
    stopPlaying()
    updateStatusUI("Media services have been reset")
  }
}

  // MARK: - Helper function inserted by Swift 4.2 migrator

fileprivate func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
