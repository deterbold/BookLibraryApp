import UIKit

class NoteDetailViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleTextField = UITextField()
    private let pageNumberTextField = UITextField()
    private let textView = UITextView()
    private let dateLabel = UILabel()
    private let separatorView = UIView()
    
    // MARK: - Properties
    private var note: Note
    weak var delegate: NoteDetailViewControllerDelegate?
    private var hasUnsavedChanges = false
    
    // MARK: - Initialization
    init(note: Note) {
        self.note = note
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
        setupNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if hasUnsavedChanges {
            saveChanges()
        }
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Note Details"
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title text field
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleTextField.borderStyle = .none
        titleTextField.backgroundColor = .systemBackground
        titleTextField.placeholder = "Note Title"
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        contentView.addSubview(titleTextField)
        
        // Page number container
        let pageContainer = UIView()
        pageContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageContainer)
        
        let pageLabel = UILabel()
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.text = "Page:"
        pageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        pageLabel.textColor = .secondaryLabel
        pageContainer.addSubview(pageLabel)
        
        pageNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        pageNumberTextField.font = UIFont.systemFont(ofSize: 16)
        pageNumberTextField.borderStyle = .roundedRect
        pageNumberTextField.backgroundColor = .secondarySystemBackground
        pageNumberTextField.placeholder = "Optional"
        pageNumberTextField.keyboardType = .numbersAndPunctuation
        pageNumberTextField.returnKeyType = .done
        pageNumberTextField.delegate = self
        pageNumberTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        pageContainer.addSubview(pageNumberTextField)
        
        // Page container constraints
        NSLayoutConstraint.activate([
            pageLabel.leadingAnchor.constraint(equalTo: pageContainer.leadingAnchor),
            pageLabel.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
            pageLabel.widthAnchor.constraint(equalToConstant: 50),
            
            pageNumberTextField.leadingAnchor.constraint(equalTo: pageLabel.trailingAnchor, constant: 8),
            pageNumberTextField.centerYAnchor.constraint(equalTo: pageContainer.centerYAnchor),
            pageNumberTextField.widthAnchor.constraint(equalToConstant: 100),
            pageNumberTextField.heightAnchor.constraint(equalToConstant: 32),
            
            pageContainer.heightAnchor.constraint(equalToConstant: 32),
            pageContainer.trailingAnchor.constraint(greaterThanOrEqualTo: pageNumberTextField.trailingAnchor)
        ])
        
        // Date label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        contentView.addSubview(dateLabel)
        
        // Separator
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .separator
        contentView.addSubview(separatorView)
        
        // Text view
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.isEditable = true
        textView.isScrollEnabled = false // Let the outer scroll view handle scrolling
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets.zero
        textView.delegate = self
        
        // Configure text formatting for better readability
        setupTextViewFormatting()
        
        contentView.addSubview(textView)
        
        // Keyboard handling
        setupKeyboardHandling()
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
            
            // Title text field
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 30),
            
            // Page number container
            contentView.subviews[1].topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 12),
            contentView.subviews[1].leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: contentView.subviews[1].bottomAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Separator
            separatorView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Text view
            textView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    private func setupNavigationBar() {
        // Add share button
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped))
        navigationItem.rightBarButtonItems = [shareButton]
        updateNavigationBar()
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
    
    private func setupTextViewFormatting() {
        // Create paragraph style for justified text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        
        // Set text view attributes
        textView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    private func updateNavigationBar() {
        // Update title to show if there are unsaved changes
        if hasUnsavedChanges {
            title = "Note Details•"
        } else {
            title = "Note Details"
        }
    }
    
    private func populateData() {
        titleTextField.text = note.title
        pageNumberTextField.text = note.pageNumber ?? ""
        applyFormattedText(note.extractedText)
        dateLabel.text = "Created: \(DateFormatter.noteDateDisplay.string(from: note.dateCreated))"
    }
    
    // MARK: - Text Formatting Methods
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
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ], range: fullRange)
        
        // Set the formatted text
        textView.attributedText = attributedText
    }
    
    // MARK: - Actions
    @objc private func textDidChange() {
        hasUnsavedChanges = true
        updateNavigationBar()
    }
    
    @objc private func shareButtonTapped() {
        let alert = UIAlertController(title: "Export Note", message: "Choose export format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Plain Text", style: .default) { _ in
            self.shareAsPlainText()
        })
        
        alert.addAction(UIAlertAction(title: "Markdown", style: .default) { _ in
            self.shareAsMarkdown()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        present(alert, animated: true)
    }
    
    private func shareAsPlainText() {
        let pageInfo = note.pageNumber != nil ? "\nPage: \(note.pageNumber!)" : ""
        let textToShare = """
        \(note.title)
        \(pageInfo)
        
        \(note.extractedText)
        
        Created: \(DateFormatter.noteDateDisplay.string(from: note.dateCreated))
        """
        
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
    
    private func shareAsMarkdown() {
        let pageInfo = note.pageNumber != nil ? "\n**Page:** \(note.pageNumber!)" : ""
        let markdownContent = """
        # \(note.title)
        \(pageInfo)
        
        \(note.extractedText)
        
        ---
        *Created: \(DateFormatter.noteDateDisplay.string(from: note.dateCreated))*
        """
        
        let activityVC = UIActivityViewController(activityItems: [markdownContent], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Helper Methods
    private func saveChanges() {
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty, !text.isEmpty else {
            return
        }
        
        let pageNumber = pageNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPageNumber = pageNumber?.isEmpty == false ? pageNumber : nil
        
        // Update the note
        note.title = title
        note.extractedText = text
        note.pageNumber = finalPageNumber
        
        // Save to manager
        BookLibraryManager.shared.updateNote(note)
        
        hasUnsavedChanges = false
        updateNavigationBar()
        
        // Notify delegate
        delegate?.didUpdateNote()
    }
    
    private func showUnsavedChangesAlert(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Unsaved Changes",
            message: "You have unsaved changes. What would you like to do?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            self.saveChanges()
            completion(true)
        })
        
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            completion(true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension NoteDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case titleTextField:
            pageNumberTextField.becomeFirstResponder()
        case pageNumberTextField:
            textView.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textDidChange()
    }
}

// MARK: - UITextViewDelegate
extension NoteDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textDidChange()
        
        // Update content size
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        textView.invalidateIntrinsicContentSize()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Scroll to make text view visible
        let textViewFrame = textView.convert(textView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(textViewFrame, animated: true)
    }
}
