import UIKit

protocol AddBookViewControllerDelegate: AnyObject {
    func didAddBook(_ book: Book)
    func didCancelAddBook()
}

class AddBookViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    private let authorTextField = UITextField()
    private let titleTextField = UITextField()
    private let yearTextField = UITextField()
    
    private var saveButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    
    // MARK: - Properties
    weak var delegate: AddBookViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTextFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Focus on first text field when view appears
        authorTextField.becomeFirstResponder()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Add Book"
        
        // Setup navigation bar buttons
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        // Initially disable save button
        saveButton.isEnabled = false
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        
        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        contentView.addSubview(stackView)
        
        // Add text fields to stack view
        stackView.addArrangedSubview(createTextFieldContainer(textField: authorTextField, label: "Author"))
        stackView.addArrangedSubview(createTextFieldContainer(textField: titleTextField, label: "Title"))
        stackView.addArrangedSubview(createTextFieldContainer(textField: yearTextField, label: "Year"))
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stack view constraints
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func createTextFieldContainer(textField: UITextField, label: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        labelView.textColor = .label
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = .systemBackground
        
        container.addSubview(labelView)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private func setupTextFields() {
        // Set up text field properties
        authorTextField.placeholder = "Enter author name"
        titleTextField.placeholder = "Enter book title"
        yearTextField.placeholder = "Enter year (e.g., 2023)"
        
        // Set keyboard types
        authorTextField.keyboardType = .default
        titleTextField.keyboardType = .default
        yearTextField.keyboardType = .numbersAndPunctuation
        
        // Set return key types
        authorTextField.returnKeyType = .next
        titleTextField.returnKeyType = .next
        yearTextField.returnKeyType = .done
        
        // Set autocapitalization
        authorTextField.autocapitalizationType = .words
        titleTextField.autocapitalizationType = .words
        yearTextField.autocapitalizationType = .none
        
        // Set delegates
        authorTextField.delegate = self
        titleTextField.delegate = self
        yearTextField.delegate = self
        
        // Add text change listeners
        authorTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        titleTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        yearTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Setup keyboard handling
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
    
    // MARK: - Actions
    @objc private func saveButtonTapped() {
        guard let author = authorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let year = yearTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !author.isEmpty, !title.isEmpty, !year.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill in all fields.")
            return
        }
        
        let newBook = Book(author: author, title: title, year: year)
        
        // Add to library
        BookLibraryManager.shared.addBook(newBook)
        
        // Notify delegate
        delegate?.didAddBook(newBook)
        
        // Dismiss view controller
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        // Check if user has entered any data
        let hasData = !(authorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
                     !(titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
                     !(yearTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        if hasData {
            // Show confirmation alert
            let alert = UIAlertController(title: "Discard Changes?",
                                        message: "You have unsaved changes. Are you sure you want to discard them?",
                                        preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
                self.delegate?.didCancelAddBook()
                self.navigationController?.popViewController(animated: true)
            })
            
            alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
            
            present(alert, animated: true)
        } else {
            // No data, just dismiss
            delegate?.didCancelAddBook()
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func textFieldDidChange() {
        updateSaveButtonState()
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
    private func updateSaveButtonState() {
        let authorText = authorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let titleText = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let yearText = yearTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        saveButton.isEnabled = !authorText.isEmpty && !titleText.isEmpty && !yearText.isEmpty
    }
    
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
extension AddBookViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case authorTextField:
            titleTextField.becomeFirstResponder()
        case titleTextField:
            yearTextField.becomeFirstResponder()
        case yearTextField:
            textField.resignFirstResponder()
            // Trigger save if all fields are filled
            if saveButton.isEnabled {
                saveButtonTapped()
            }
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Scroll to make the active text field visible
        let textFieldFrame = textField.convert(textField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(textFieldFrame, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
}
