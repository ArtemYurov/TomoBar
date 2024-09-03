import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    public let soundFolder: URL
    private var windupSound: AVAudioPlayer = AVAudioPlayer()
    private var dingSound: AVAudioPlayer = AVAudioPlayer()
    private var tickingSound: AVAudioPlayer = AVAudioPlayer()
    private var windupTimer: Timer?
    private var dingTimer: Timer?
    private var isTicking: Bool = false
    private var supportedAudioExtensions: [String] = ["mp3", "mp4", "m4a"]

    @AppStorage("windupVolume") var windupVolume: Double = 1.0
    @AppStorage("dingVolume") var dingVolume: Double = 1.0
    @AppStorage("tickingVolume") var tickingVolume: Double = 1.0 {
        didSet {
            if isTicking {
                setVolume(tickingSound, tickingVolume)
                if tickingVolume == 0.0 {
                    tickingSound.stop()
                }
                else if !tickingSound.isPlaying {
                    DispatchQueue.main.async { [self] in
                        tickingSound.play()
                    }
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
        let documentFolder = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        soundFolder = documentFolder.appendingPathComponent("TomatoBar")

        do {
            try FileManager.default.createDirectory(at: soundFolder, withIntermediateDirectories: true)
        } catch {
            fatalError("Error initializing sound folder: \(error)")
        }
    }

    func playWindup() {
        if windupVolume > 0.0 {
            windupSound = loadSound(fileName: "windup")
            setVolume(windupSound, windupVolume)
            DispatchQueue.main.async { [self] in
                windupSound.play()
            }
            windupTimer?.invalidate()
            windupTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [self] (timer) in
                windupSound.stop()
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
            dingTimer?.invalidate()
            dingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [self] (timer) in
                dingSound.stop()
            }
        }
    }

    func startTicking() {
        tickingSound = loadSound(fileName: "ticking")
        tickingSound.numberOfLoops = -1
        setVolume(tickingSound, tickingVolume)
        tickingSound.prepareToPlay()
        if tickingVolume > 0.0 {
            DispatchQueue.main.async { [self] in
                tickingSound.play()
            }
        }
        isTicking = true
    }

    func stopTicking() {
        tickingSound.stop()
        isTicking = false
    }

    func stopPlayers() {
        dingSound.stop()
        windupSound.stop()
        windupTimer?.invalidate()
        dingTimer?.invalidate()
    }
}
