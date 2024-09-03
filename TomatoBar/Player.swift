import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    public let soundFolder: URL
    private var windupSound: AVAudioPlayer = AVAudioPlayer()
    private var dingSound: AVAudioPlayer = AVAudioPlayer()
    private var tickingSound: AVAudioPlayer = AVAudioPlayer()
    private var isTicking: Bool = false
    private var supportedAudioExtensions: [String] = ["mp3", "mp4", "m4a"]

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

    private func getFileURLIfExists(fileName: String) -> URL? {
        for ext in supportedAudioExtensions {
            let fileURL = soundFolder.appendingPathComponent("\(fileName).\(ext)")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }
        return nil
    }

    private func loadSound(fileName: String) -> AVAudioPlayer {
        if let fileURL = getFileURLIfExists(fileName: fileName) {
            do {
                return try AVAudioPlayer(contentsOf: fileURL)
            } catch {
                fatalError("Error loading sound from file URL: \(error)")
            }
        } else {
            let asset = NSDataAsset(name: fileName)
            let wav = AVFileType.wav.rawValue
            do {
                return try AVAudioPlayer(data: asset!.data, fileTypeHint: wav)
            } catch {
                fatalError("Error loading sound from NSDataAsset: \(error)")
            }
        }
    }

    init() {
        let applicationSupport = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        soundFolder = applicationSupport.appendingPathComponent("TomatoBar")

        do {
            try FileManager.default.createDirectory(at: soundFolder, withIntermediateDirectories: true)
        } catch {
            fatalError("Error initializing audio folder: \(error)")
        }
    }

    func playWindup() {
        if windupVolume > 0.0 {
            windupSound = loadSound(fileName: "windup")
            setVolume(windupSound, windupVolume)
            DispatchQueue.main.async { [self] in
                windupSound.play()
            }
        }
    }

    func playDing() {
        if dingVolume > 0.0 {
            dingSound = loadSound(fileName: "ding")
            setVolume(dingSound, dingVolume)
            DispatchQueue.main.async { [self] in
                dingSound.play()
            }
        }
    }

    func startTicking() {
        if tickingVolume > 0.0 {
            tickingSound = loadSound(fileName: "ticking")
            tickingSound.numberOfLoops = -1
            setVolume(tickingSound, tickingVolume)
            DispatchQueue.main.async { [self] in
                tickingSound.play()
            }
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
