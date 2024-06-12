import UIKit
import CoreHaptics
import AVFAudio

final class AppleLogoView: UIView {
	
	var updateTexturePlayer: ((Bool) -> Void)?
}

final class AppleLogoViewController: UIViewController {
	
	private let imageView = UIImageView(image: UIImage(named: "EgestasGradient"))
	private var isConfigure = false
	
	var engine: CHHapticEngine!
	var engineNeedsStart = true
	var texturePlayer: CHHapticAdvancedPatternPlayer!
	private var needsStartPlayer = true
	lazy var supportsHaptics: Bool = {
		CHHapticEngine.capabilitiesForHardware().supportsHaptics
	}()
	
	override func loadView() {
		let appleLogoView = AppleLogoView()
		appleLogoView.updateTexturePlayer = { [weak self] isPlaying in
			self?.updateTexturePlayer(isPlaying)
		}
		view = appleLogoView
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addSubview(imageView)
		
		createAndStartHapticEngine()
		initializeTextureHaptics()
		startTexturePlayerIfNeeded()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		imageView.frame = view.bounds
		imageView.clipsToBounds = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		makeContent()
	}
	
	func makeContent() {
		if isConfigure {
			return
		}
		
		let size = CGSize(width: 300, height: 369)
		view.addAppleLogoSpiler(path: .bigAppleLogo, size: size)
		
		isConfigure = true
	}
}

/// Здесь все что связано с хаптиком.
/// Взял из примера Apple, идеально подошло.
/// https://developer.apple.com/documentation/corehaptics/delivering_rich_app_experiences_with_haptics
extension AppleLogoViewController {
	
	func stopPlayer(_ player: CHHapticPatternPlayer) {
		guard supportsHaptics else { return }
		do {
			try player.stop(atTime: CHHapticTimeImmediate)
		} catch let error {
			print("Error stopping haptic player: \(error)")
		}
	}
	
	func startPlayer(_ player: CHHapticPatternPlayer) {
		guard supportsHaptics else { return }
		do {
			try startHapticEngineIfNecessary()
			try player.start(atTime: CHHapticTimeImmediate)
		} catch let error {
			print("Error starting haptic player: \(error)")
		}
	}
	
	func startHapticEngineIfNecessary() throws {
		if engineNeedsStart {
			try engine.start()
			engineNeedsStart = false
		}
	}
	
	func createAndStartHapticEngine() {
		guard supportsHaptics else { return }
		
		// Create and configure a haptic engine.
		do {
			engine = try CHHapticEngine(audioSession: .sharedInstance())
		} catch let error {
			fatalError("Engine Creation Error: \(error)")
		}
		
		// The stopped handler alerts engine stoppage.
		engine.stoppedHandler = { reason in
			print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
			switch reason {
			case .audioSessionInterrupt:
				print("Audio session interrupt.")
			case .applicationSuspended:
				print("Application suspended.")
			case .idleTimeout:
				print("Idle timeout.")
			case .notifyWhenFinished:
				print("Finished.")
			case .systemError:
				print("System error.")
			case .engineDestroyed:
				print("Engine destroyed.")
			case .gameControllerDisconnect:
				print("Controller disconnected.")
			@unknown default:
				print("Unknown error")
			}
			
			// Indicate that the next time the app requires a haptic, the app must call engine.start().
			self.engineNeedsStart = true
		}
		
		// The reset handler notifies the app that it must reload all of its content.
		// If necessary, it recreates all players and restarts the engine in response to a server restart.
		engine.resetHandler = {
			print("The engine reset --> Restarting now!")
			
			// Tell the app to start the engine the next time a haptic is necessary.
			self.engineNeedsStart = true
		}
		
		// Start the haptic engine to prepare it for use.
		do {
			try engine.start()
			
			// Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
			engineNeedsStart = false
		} catch let error {
			print("The engine failed to start with error: \(error)")
		}
	}
	
	func initializeTextureHaptics() {
		guard supportsHaptics else { return }
		
		// Create a texture player.
		let texturePattern = createPatternFromAHAP("Texture")!
		texturePlayer = try? engine.makeAdvancedPlayer(with: texturePattern)
		texturePlayer?.loopEnabled = true
	}
	
	private func createPatternFromAHAP(_ filename: String) -> CHHapticPattern? {
		// Get the URL for the pattern in the app bundle.
		let patternURL = Bundle.main.url(forResource: filename, withExtension: "ahap")!
		
		do {
			// Read JSON data from the URL.
			let patternJSONData = try Data(contentsOf: patternURL, options: [])
			
			// Create a dictionary from the JSON data.
			let dict = try JSONSerialization.jsonObject(with: patternJSONData, options: [])
			
			if let patternDict = dict as? [CHHapticPattern.Key: Any] {
				// Create a pattern from the dictionary.
				return try CHHapticPattern(dictionary: patternDict)
			}
		} catch let error {
			print("Error creating haptic pattern: \(error)")
		}
		return nil
	}
	
	func updateTexturePlayer(_ isPlaying: Bool) {
		guard supportsHaptics else { return }
		
		guard isPlaying else {
			texturePlayer.loopEnabled = false
			stopPlayer(texturePlayer)
			needsStartPlayer = true
			return
		}
		
		startTexturePlayerIfNeeded()
		
		// Create dynamic parameters for the updated intensity.
		let intensityValue: CFloat = 0.4 // min: 0.05, max: 0.45
		
		let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
														  value: intensityValue,
														  relativeTime: 0)
		// Send dynamic parameter to the haptic player.
		do {
			try startHapticEngineIfNecessary()
			texturePlayer.loopEnabled = true
			try texturePlayer.sendParameters([intensityParameter],
											 atTime: 0)
		} catch let error {
			print("Dynamic Parameter Error: \(error)")
		}
	}
	
	func startTexturePlayerIfNeeded() {
		guard supportsHaptics else { return }
		
		guard needsStartPlayer else {
			return
		}
		
		// Create and send a dynamic parameter with zero intensity at the start of
		// the texture playback. The intensity dynamically modulates as the
		// sphere moves, but it starts from zero.
		let zeroIntensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
															  value: 0,
															  relativeTime: 0)
		do {
			try startHapticEngineIfNecessary()
			try texturePlayer.sendParameters([zeroIntensityParameter], atTime: 0)
		} catch let error {
			print("Dynamic Parameter Error: \(error)")
		}
		
		startPlayer(texturePlayer)
		
		needsStartPlayer = false
	}
}
