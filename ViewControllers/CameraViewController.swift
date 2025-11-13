import UIKit
import AVFoundation
import Vision

protocol CameraViewControllerDelegate: AnyObject {
    func didSaveNote(_ note: Note)
    func didCancelCapture()
}

class CameraViewController: UIViewController {
    
    // MARK: - UI Elements
    private let previewView = UIView()
    private let captureButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let flashButton = UIButton(type: .system)
    private let helpButton = UIButton(type: .system)
    private let instructionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let overlayView = UIView()
    private let focusIndicator = UIView()
    private let zoomLabel = UILabel()
    
    // MARK: - Camera Properties
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var currentDevice: AVCaptureDevice?
    private var deviceInput: AVCaptureDeviceInput?
    
    // MARK: - Zoom and Focus Properties
    private var initialZoomScale: CGFloat = 1.0
    private var currentZoomScale: CGFloat = 1.0
    private var maxZoomScale: CGFloat = 5.0
    
    // MARK: - Properties
    weak var delegate: CameraViewControllerDelegate?
    private let bookId: UUID
    private var isFlashOn = false
    
    // MARK: - Initialization
    init(bookId: UUID) {
        self.bookId = bookId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        checkCameraPermission()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.stopRunning()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .black
        title = "Capture Text"
        
        // Preview view
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.backgroundColor = .black
        view.addSubview(previewView)
        
        // Overlay view for visual guidance
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.layer.borderColor = UIColor.systemBlue.cgColor
        overlayView.layer.borderWidth = 2
        overlayView.layer.cornerRadius = 8
        overlayView.alpha = 0.7
        previewView.addSubview(overlayView)
        
        // Instruction label
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.text = "Tap to focus • Pinch to zoom\nOnly text between /slashes/ will be captured"
        instructionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 3
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.layer.masksToBounds = true
        view.addSubview(instructionLabel)
        
        // Capture button
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.backgroundColor = .systemBlue
        captureButton.setTitle("Capture", for: .normal)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        captureButton.layer.cornerRadius = 25
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Cancel button
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.8)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.layer.cornerRadius = 20
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Flash button
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        flashButton.setTitle("⚡", for: .normal)
        flashButton.setTitleColor(.white, for: .normal)
        flashButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        flashButton.layer.cornerRadius = 20
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        view.addSubview(flashButton)
        
        // Help button
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        helpButton.setTitle("?", for: .normal)
        helpButton.setTitleColor(.white, for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        helpButton.layer.cornerRadius = 15
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)
        view.addSubview(helpButton)
        
        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Focus indicator
        focusIndicator.translatesAutoresizingMaskIntoConstraints = false
        focusIndicator.backgroundColor = .clear
        focusIndicator.layer.borderColor = UIColor.systemYellow.cgColor
        focusIndicator.layer.borderWidth = 2
        focusIndicator.layer.cornerRadius = 4
        focusIndicator.alpha = 0
        focusIndicator.isUserInteractionEnabled = false
        view.addSubview(focusIndicator)
        
        // Zoom label
        zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomLabel.text = "1.0x"
        zoomLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        zoomLabel.textColor = .white
        zoomLabel.textAlignment = .center
        zoomLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        zoomLabel.layer.cornerRadius = 12
        zoomLabel.layer.masksToBounds = true
        zoomLabel.alpha = 0
        view.addSubview(zoomLabel)
        
        // Add gesture recognizers
        setupGestureRecognizers()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Preview view
            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20),
            
            // Overlay view (centered in preview with some padding)
            overlayView.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: previewView.centerYAnchor),
            overlayView.widthAnchor.constraint(equalTo: previewView.widthAnchor, multiplier: 0.8),
            overlayView.heightAnchor.constraint(equalTo: previewView.heightAnchor, multiplier: 0.4),
            
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Capture button
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 120),
            captureButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel button
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Flash button
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 40),
            flashButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Help button
            helpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            helpButton.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            helpButton.widthAnchor.constraint(equalToConstant: 30),
            helpButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Focus indicator
            focusIndicator.widthAnchor.constraint(equalToConstant: 80),
            focusIndicator.heightAnchor.constraint(equalToConstant: 80),
            
            // Zoom label
            zoomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            zoomLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            zoomLabel.widthAnchor.constraint(equalToConstant: 60),
            zoomLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupGestureRecognizers() {
        // Tap to focus
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus))
        previewView.addGestureRecognizer(tapGesture)
        
        // Pinch to zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom))
        previewView.addGestureRecognizer(pinchGesture)
        
        previewView.isUserInteractionEnabled = true
    }
    
    // MARK: - Camera Setup
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showAlert(title: "Camera Error", message: "Unable to access camera")
            return
        }
        
        currentDevice = backCamera
        maxZoomScale = min(backCamera.activeFormat.videoMaxZoomFactor, 5.0)
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: backCamera)
            photoOutput = AVCapturePhotoOutput()
            
            if let deviceInput = deviceInput,
               captureSession.canAddInput(deviceInput) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(deviceInput)
                captureSession.addOutput(photoOutput)
                
                setupPreviewLayer()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
            }
        } catch {
            showAlert(title: "Camera Error", message: "Unable to initialize camera: \(error.localizedDescription)")
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(previewLayer)
    }
    
    // MARK: - Actions
    @objc private func captureButtonTapped() {
        let settings = AVCapturePhotoSettings()
        
        // Configure flash
        if currentDevice?.hasFlash == true {
            settings.flashMode = isFlashOn ? .on : .off
        }
        
        // Start loading indicator
        loadingIndicator.startAnimating()
        captureButton.isEnabled = false
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelCapture()
        dismiss(animated: true)
    }
    
    @objc private func flashButtonTapped() {
        guard currentDevice?.hasFlash == true else { return }
        
        isFlashOn.toggle()
        flashButton.backgroundColor = isFlashOn ? UIColor.systemYellow.withAlphaComponent(0.8) : UIColor.black.withAlphaComponent(0.6)
    }
    
    @objc private func helpButtonTapped() {
        let alert = UIAlertController(
            title: "Selective Text Capture",
            message: """
            This app only captures text that is marked between forward slashes.
            
            Example:
            "This is normal text /but only this will be captured/ and this won't."
            
            • Use /text/ to mark what you want to capture
            • Multiple /sections/ can be captured from one image
            • Make sure your slashes are clear and visible
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Focus and Zoom Gesture Handlers
    @objc private func handleTapToFocus(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: previewView)
        
        // Convert touch point to camera coordinates (0,0 to 1,1)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        // Focus and expose at the tapped point
        focusAndExposure(at: devicePoint)
        
        // Show focus indicator
        showFocusIndicator(at: touchPoint)
    }
    
    @objc private func handlePinchToZoom(_ gesture: UIPinchGestureRecognizer) {
        guard let device = currentDevice else { return }
        
        switch gesture.state {
        case .began:
            initialZoomScale = currentZoomScale
            
        case .changed:
            let scale = initialZoomScale * gesture.scale
            let clampedScale = max(1.0, min(scale, maxZoomScale))
            
            if clampedScale != currentZoomScale {
                currentZoomScale = clampedScale
                setZoom(scale: currentZoomScale)
                updateZoomLabel()
            }
            
        case .ended, .cancelled:
            hideZoomLabel()
            
        default:
            break
        }
    }
    
    // MARK: - Camera Focus and Zoom Methods
    private func focusAndExposure(at devicePoint: CGPoint) {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Set focus point
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            
            // Set exposure point
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure camera focus/exposure: \(error)")
        }
    }
    
    private func setZoom(scale: CGFloat) {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = scale
            device.unlockForConfiguration()
        } catch {
            print("Failed to set zoom: \(error)")
        }
    }
    
    private func showFocusIndicator(at point: CGPoint) {
        // Position focus indicator at tap point
        focusIndicator.center = point
        focusIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        focusIndicator.alpha = 1.0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.focusIndicator.transform = CGAffineTransform.identity
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 0.5) {
                self.focusIndicator.alpha = 0
            }
        }
    }
    
    private func updateZoomLabel() {
        zoomLabel.text = String(format: "%.1fx", currentZoomScale)
        
        if zoomLabel.alpha == 0 {
            UIView.animate(withDuration: 0.2) {
                self.zoomLabel.alpha = 1.0
            }
        }
    }
    
    private func hideZoomLabel() {
        UIView.animate(withDuration: 0.3, delay: 1.0) {
            self.zoomLabel.alpha = 0
        }
    }
    
    // MARK: - Text Recognition
    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.captureButton.isEnabled = true
                self.showAlert(title: "Error", message: "Unable to process image")
            }
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.captureButton.isEnabled = true
                
                if let error = error {
                    self.showAlert(title: "Text Recognition Error", message: error.localizedDescription)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.showAlert(title: "No Text Found", message: "No text could be detected in the image")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.showAlert(title: "No Text Found", message: "No text could be detected in the image")
                } else {
                    // Extract text between slashes
                    let extractedText = self.extractTextBetweenSlashes(from: recognizedText)
                    
                    if extractedText.isEmpty {
                        self.showAlert(
                            title: "No Bracketed Text Found",
                            message: "No text between forward slashes (/) was found. Make sure to capture text that includes /bracketed content/."
                        )
                    } else {
                        // Navigate to review screen with extracted text
                        self.showNoteReview(with: extractedText)
                    }
                }
            }
        }
        
        // Configure text recognition for better accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.captureButton.isEnabled = true
                    self.showAlert(title: "Processing Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Permission Required",
            message: "Please enable camera access in Settings to capture text from images.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.delegate?.didCancelCapture()
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showNoteReview(with text: String) {
        let reviewVC = NoteReviewViewController(bookId: bookId, capturedText: text)
        reviewVC.delegate = self
        reviewVC.modalPresentationStyle = .pageSheet
        
        // Configure sheet presentation for iOS 15+
        if let sheet = reviewVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(reviewVC, animated: true)
    }
    
    // MARK: - Text Extraction Methods
    private func extractTextBetweenSlashes(from text: String) -> String {
        // Regular expression to find text between forward slashes
        let pattern = "/(.*?)/"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var extractedTexts: [String] = []
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let range = match.range(at: 1) // Get the first capture group (content between slashes)
                let extractedText = nsString.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !extractedText.isEmpty {
                    extractedTexts.append(extractedText)
                }
            }
        }
        
        // Join multiple bracketed sections with double line breaks
        return extractedTexts.joined(separator: "\n\n")
    }
}

// MARK: - NoteReviewViewControllerDelegate
extension CameraViewController: NoteReviewViewControllerDelegate {
    func didSaveNote(_ note: Note) {
        // Save the note and forward to delegate
        BookLibraryManager.shared.addNote(note)
        delegate?.didSaveNote(note)
        dismiss(animated: true)
    }
    
    func didCancelNoteReview() {
        // User cancelled the review, stay on camera screen
        // No action needed, they can capture again or cancel
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.captureButton.isEnabled = true
                self.showAlert(title: "Capture Error", message: error.localizedDescription)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.captureButton.isEnabled = true
                self.showAlert(title: "Error", message: "Unable to process captured image")
            }
            return
        }
        
        // Process the image for text recognition
        recognizeText(in: image)
    }
}
