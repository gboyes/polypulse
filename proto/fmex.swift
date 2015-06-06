import AVFoundation
import Foundation

// The maximum number of audio buffers in flight. Setting to two allows one
// buffer to be played while the next is being written.
private let kInFlightAudioBuffers: Int = 2

// The number of audio samples per buffer. A lower value reduces latency for
// changes but requires more processing but increases the risk of being unable
// to fill the buffers in time. A setting of 1024 represents about 23ms of
// samples.
private let kSamplesPerBuffer: AVAudioFrameCount = 1024

// The single FM synthesizer instance.
private let gFMSynthesizer: FMSynthesizer = FMSynthesizer()

public class FMSynthesizer {

    // The audio engine manages the sound system.
    private let engine: AVAudioEngine = AVAudioEngine()

    // The player node schedules the playback of the audio buffers.
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()

    // Use standard non-interleaved PCM audio.
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)

    // A circular queue of audio buffers.
    private let audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()

    // The index of the next buffer to fill.
    private var bufferIndex: Int = 0

    // The dispatch queue to render audio samples.
    private let audioQueue: dispatch_queue_t = dispatch_queue_create("FMSynthesizerQueue", DISPATCH_QUEUE_SERIAL)

    // A semaphore to gate the number of buffers processed.
    private let audioSemaphore: dispatch_semaphore_t = dispatch_semaphore_create(kInFlightAudioBuffers)

    public class func sharedSynth() -> FMSynthesizer {
        return gFMSynthesizer
    }

    private init() {
        // Create a pool of audio buffers.
        for var i = 0;  i < kInFlightAudioBuffers; i++ {
            let audioBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: kSamplesPerBuffer)
            audioBuffers.append(audioBuffer)
        }

        // Attach and connect the player node.
        engine.attachNode(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)

        var error: NSError? = nil
        if !engine.startAndReturnError(&error) {
            NSLog("Error starting audio engine: \(error)")
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioEngineConfigurationChange:", name: AVAudioEngineConfigurationChangeNotification, object: engine)
    }

    public func play(carrierFrequency: Float32, modulatorFrequency: Float32, modulatorAmplitude: Float32) {
        let unitVelocity = Float32(2.0 * M_PI / audioFormat.sampleRate)
        let carrierVelocity = carrierFrequency * unitVelocity
        let modulatorVelocity = modulatorFrequency * unitVelocity
        dispatch_async(audioQueue) {
            var sampleTime: Float32 = 0
            while true {
                // Wait for a buffer to become available.
                dispatch_semaphore_wait(self.audioSemaphore, DISPATCH_TIME_FOREVER)

                // Fill the buffer with new samples.
                let audioBuffer = self.audioBuffers[self.bufferIndex]
                let leftChannel = audioBuffer.floatChannelData[0]
                let rightChannel = audioBuffer.floatChannelData[1]
                for var sampleIndex = 0; sampleIndex < Int(kSamplesPerBuffer); sampleIndex++ {
                    let sample = sin(carrierVelocity * sampleTime + modulatorAmplitude * sin(modulatorVelocity * sampleTime))
                    leftChannel[sampleIndex] = sample
                    rightChannel[sampleIndex] = sample
                    sampleTime++
                }
                audioBuffer.frameLength = kSamplesPerBuffer

                // Schedule the buffer for playback and release it for reuse after
                // playback has finished.
                self.playerNode.scheduleBuffer(audioBuffer) {
                    dispatch_semaphore_signal(self.audioSemaphore)
                    return
                }

                self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
            }
        }

        playerNode.pan = 0.8
        playerNode.play()
    }

    @objc private func audioEngineConfigurationChange(notification: NSNotification) -> Void {
        NSLog("Audio engine configuration change: \(notification)")
    }

}

// Play a bell sound:
FMSynthesizer.sharedSynth().play(440.0, modulatorFrequency: 679.0, modulatorAmplitude: 0.8)