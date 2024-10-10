import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    public let soundFolder: URL!
    private var windupSound: AVAudioPlayer!
    private var dingSound: AVAudioPlayer!
    private var tickingSound: AVAudioPlayer!
    private var windupTimer: Timer?
    private var dingTimer: Timer?
    private var isInitialized: Bool = false
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
                if tickingVolume == 0.0 {
                    tickingSound.pause()
                }
                else if !tickingSound.isPlaying {
                    DispatchQueue.main.async { [self] in
                        tickingSound.play()
                    }
                }
            }
        }
    }

    private func setVolume(_ sound: AVAudioPlayer?, _ volume: Double) {
        sound?.setVolume(Float(volume), fadeDuration: 0)
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

    func initPlayers() {
        windupTimer?.invalidate()
        dingTimer?.invalidate()
        windupSound = loadSound(fileName: "windup")
        dingSound = loadSound(fileName: "ding")
        tickingSound = loadSound(fileName: "ticking")
        windupSound.prepareToPlay()
        dingSound.prepareToPlay()
        tickingSound.numberOfLoops = -1
        tickingSound.prepareToPlay()
        setVolume(windupSound, windupVolume)
        setVolume(dingSound, dingVolume)
        setVolume(tickingSound, tickingVolume)
        isInitialized = true
    }

    func playWindup() {
        if windupVolume > 0.0 {
            windupSound.currentTime = 0
            DispatchQueue.main.async { [self] in
                dingSound.pause()
                windupSound.play()
            }
            windupTimer?.invalidate()
            windupTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [self] _ in
                isInitialized ? windupSound.pause() : windupSound.stop()
            }
        }
    }

    func playDing() {
        if dingVolume > 0.0 {
            dingSound.currentTime = 0
            DispatchQueue.main.async { [self] in
                windupSound.pause()
                dingSound.play()
            }
            dingTimer?.invalidate()
            dingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [self] _ in
                isInitialized ? dingSound.pause() : dingSound.stop()
            }
        }
    }

    func startTicking(isPaused: Bool = false) {
        if tickingVolume > 0.0 {
            if !isPaused {
                tickingSound.currentTime = 0
            }
            DispatchQueue.main.async { [self] in
                tickingSound.play()
            }
        }
        isTicking = true
    }

    func stopTicking() {
        tickingSound.pause()
        isTicking = false
    }

    func stopPlayers() {
        if !(dingTimer?.isValid ?? false) {
            dingSound.stop()
        }
        if !(windupTimer?.isValid ?? false) {
            windupSound.stop()
        }
        tickingSound.stop()
        isInitialized = false
    }
}
