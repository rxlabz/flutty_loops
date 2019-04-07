import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    //let tone = ToneOutputUnit()
    let tones = [ToneOutputUnit(), ToneOutputUnit(), ToneOutputUnit(), ToneOutputUnit(), ToneOutputUnit(), ToneOutputUnit()];
    override init(){
        tones.forEach{tone in tone.enableSpeaker()};
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
        ) -> Bool {
        
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let toneChannel = FlutterMethodChannel(name: "bz.rxla/tone",
                                               binaryMessenger: controller)
        toneChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            guard call.method == "play" else {
                result(FlutterMethodNotImplemented)
                return
            }
            (call.arguments as! [Int]).forEach{id in self!.playTone(id: id)};
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func playTone(id:Int){
        tones[id-1].setFrequency(freq: Double(id) * 110.0)
        tones[id-1].setToneTime(t: 0.2)
    }
}
