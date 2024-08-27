import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer
    private var dingSound: AVAudioPlayer
    private var tickingSound: AVAudioPlayer
    private var isTicking: Bool = false

    @AppStorage("windupVolume") var windupVolume: Double = 1.0 {
        didSet {
            setVolume(windupSound, windupVolume)
        }
    }
    @AppStorage("dingVolume") var dingVolume: Double = 1.0 {
        didSet {
            setVolume(dingSound, dingVolume)
        }
    }
    @AppStorage("tickingVolume") var tickingVolume: Double = 1.0 {
        didSet {
            setVolume(tickingSound, tickingVolume)
            if isTicking {
                if tickingVolume == 0.0, tickingSound.isPlaying {
                    tickingSound.stop()
                }
                else if tickingVolume > 0.0, !tickingSound.isPlaying {
                    tickingSound.play()
                }
            }
        }
    }

    private func setVolume(_ sound: AVAudioPlayer, _ volume: Double) {
        sound.setVolume(Float(volume), fadeDuration: 0)
    }

    init() {
        let windupSoundAsset = NSDataAsset(name: "windup")
        let dingSoundAsset = NSDataAsset(name: "ding")
        let tickingSoundAsset = NSDataAsset(name: "ticking")

        let wav = AVFileType.wav.rawValue
        do {
            windupSound = try AVAudioPlayer(data: windupSoundAsset!.data, fileTypeHint: wav)
            dingSound = try AVAudioPlayer(data: dingSoundAsset!.data, fileTypeHint: wav)
            tickingSound = try AVAudioPlayer(data: tickingSoundAsset!.data, fileTypeHint: wav)
        } catch {
            fatalError("Error initializing players: \(error)")
        }

        windupSound.prepareToPlay()
        dingSound.prepareToPlay()
        tickingSound.numberOfLoops = -1
        tickingSound.prepareToPlay()

        setVolume(windupSound, windupVolume)
        setVolume(dingSound, dingVolume)
        setVolume(tickingSound, tickingVolume)
    }

    func playWindup() {
        if windupVolume > 0.0 {
            windupSound.play()
        }
    }

    func playDing() {
        if dingVolume > 0.0 {
            dingSound.play()
        }
    }

    func startTicking() {
        if tickingVolume > 0.0 {
            tickingSound.play()
        }
        isTicking = true
    }

    func stopTicking() {
        if tickingSound.isPlaying {
            tickingSound.stop()
        }
        isTicking = false
    }
}
