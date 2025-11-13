import UIKit

protocol NoteReviewViewControllerDelegate: AnyObject {
    func didSaveNote(_ note: Note)
    func didCancelNoteReview()
}

class NoteReviewViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerLabel = UILabel()
    private let pageNumberContainer = UIView()
    private let pageNumberTextField = UITextField()
    private let textViewContainer = UIView()
    private let textView = UITextView()
    private let buttonStackView = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let bookId: UUID
    private let capturedText: String
    weak var delegate: NoteReviewViewControllerDelegate?
    
    // MARK: - Initialization
    init(bookId: UUID, capturedText: String) {
        self.bookId = bookId
        self.capturedText = capturedText
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
        populateData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Focus on page number field first
        pageNumberTextField.becomeFirstResponder()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Review Note"
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        setupHeaderLabel()
        setupPageNumberField()
        setupTextView()
        setupButtons()
        setupKeyboardHandling()
    }
    
    private func setupHeaderLabel() {
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Review captured text between /slashes/ and add page number"
        headerLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        headerLabel.textColor = .secondaryLabel
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        contentView.addSubview(headerLabel)
    }
    
    private func setupPageNumberField() {
        pageNumberContainer.translatesAutoresizingMaskIntoConstraints = false
        pageNumberContainer.backgroundColor = .secondarySystemBackground
        pageNumberContainer.layer.cornerRadius = 12
        contentView.addSubview(pageNumberContainer)
        
        let pageLabel = UILabel()
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.text = "Page:"
        pageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        pageLabel.textColor = .label
        pageNumberContainer.addSubview(pageLabel)
        
        pageNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        pageNumberTextField.placeholder = "Optional"
        pageNumberTextField.font = UIFont.systemFont(ofSize: 16)
        pageNumberTextField.borderStyle = .roundedRect
        pageNumberTextField.backgroundColor = .systemBackground
        pageNumberTextField.keyboardType = .numbersAndPunctuation
        pageNumberTextField.returnKeyType = .done
        pageNumberTextField.delegate = self
        pageNumberContainer.addSubview(pageNumberTextField)
        
        // Page container internal constraints
        NSLayoutConstraint.activate([
            pageLabel.leadingAnchor.constraint(equalTo: pageNumberContainer.leadingAnchor, constant: 16),
            pageLabel.centerYAnchor.constraint(equalTo: pageNumberContainer.centerYAnchor),
            pageLabel.widthAnchor.constraint(equalToConstant: 50),
            
            pageNumberTextField.leadingAnchor.constraint(equalTo: pageLabel.trailingAnchor, constant: 12),
            pageNumberTextField.trailingAnchor.constraint(equalTo: pageNumberContainer.trailingAnchor, constant: -16),
            pageNumberTextField.centerYAnchor.constraint(equalTo: pageNumberContainer.centerYAnchor),
            pageNumberTextField.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupTextView() {
        textViewContainer.translatesAutoresizingMaskIntoConstraints = false
        textViewContainer.backgroundColor = .secondarySystemBackground
        textViewContainer.layer.cornerRadius = 12
        contentView.addSubview(textViewContainer)
        
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = "Captured Text:"
        textLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textLabel.textColor = .label
        textViewContainer.addSubview(textLabel)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.isEditable = true
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.borderWidth = 1
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        
        // Configure text formatting for better readability
        setupTextViewFormatting()
        
        textViewContainer.addSubview(textView)
        
        // Text container internal constraints
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: textViewContainer.topAnchor, constant: 16),
            textLabel.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor, constant: -16),
            
            textView.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupTextViewFormatting() {
        // Create paragraph style for justified text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        
        // Set text view attributes
        textView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    private func setupButtons() {
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        contentView.addSubview(buttonStackView)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = .systemGray4
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(cancelButton)
        
        // Save button
        saveButton.setTitle("Save Note", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(saveButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header label
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Page number container
            pageNumberContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            pageNumberContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            pageNumberContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            pageNumberContainer.heightAnchor.constraint(equalToConstant: 68),
            
            // Text view container
            textViewContainer.topAnchor.constraint(equalTo: pageNumberContainer.bottomAnchor, constant: 20),
            textViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textViewContainer.heightAnchor.constraint(equalToConstant: 320),
            
            // Button stack view
            buttonStackView.topAnchor.constraint(equalTo: textViewContainer.bottomAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func populateData() {
        let cleanedText = preprocessOCRText(capturedText)
        applyFormattedText(cleanedText)
    }
    
    // MARK: - Text Processing Methods
    private func preprocessOCRText(_ rawText: String) -> String {
        var cleanedText = rawText
        
        // Remove excessive whitespace and normalize line breaks
        cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Fix common OCR issues
        cleanedText = cleanedText.replacingOccurrences(of: "\\n\\s*\\n", with: "\n\n", options: .regularExpression) // Normalize paragraph breaks
        cleanedText = cleanedText.replacingOccurrences(of: "([.!?])([A-Z])", with: "$1 $2", options: .regularExpression) // Add space after sentence endings
        cleanedText = cleanedText.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression) // Fix missing spaces between words
        
        // Clean up common OCR artifacts
        cleanedText = cleanedText.replacingOccurrences(of: "\\|", with: "I", options: .regularExpression) // Replace pipes with I
        cleanedText = cleanedText.replacingOccurrences(of: "0(?=[a-zA-Z])", with: "O", options: .regularExpression) // Replace 0 with O before letters
        cleanedText = cleanedText.replacingOccurrences(of: "(?<=[a-zA-Z])0", with: "o", options: .regularExpression) // Replace 0 with o after letters
        
        // Trim whitespace
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
    
    private func applyFormattedText(_ text: String) {
        // Create paragraph style for justified text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        
        // Create attributed string
        let attributedText = NSMutableAttributedString(string: text)
        
        // Apply formatting to entire text
        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttributes([
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ], range: fullRange)
        
        // Set the formatted text
        textView.attributedText = attributedText
    }
    
    // MARK: - Actions
    @objc private func saveButtonTapped() {
        let pageNumber = pageNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPageNumber = pageNumber?.isEmpty == false ? pageNumber : nil
        let finalText = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard !finalText.isEmpty else {
            showAlert(title: "Empty Note", message: "Please ensure the note contains some text.")
            return
        }
        
        let note = Note(
            bookId: bookId,
            extractedText: finalText,
            pageNumber: finalPageNumber
        )
        
        delegate?.didSaveNote(note)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.didCancelNoteReview()
        dismiss(animated: true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        
        // Scroll to active field if it's being covered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.textView.isFirstResponder {
                let textViewFrame = self.textView.convert(self.textView.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(textViewFrame, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension NoteReviewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textView.becomeFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension NoteReviewViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Scroll to make text view visible when editing begins
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let textViewFrame = textView.convert(textView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(textViewFrame, animated: true)
        }
    }
}
