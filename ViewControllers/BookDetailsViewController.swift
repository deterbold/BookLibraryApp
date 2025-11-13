import UIKit

class BookDetailsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let bookInfoView = UIView()
    private let notesTableView = UITableView()
    
    // Book info elements
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let yearLabel = UILabel()
    private let separatorView = UIView()
    
    // Notes section
    private let notesHeaderLabel = UILabel()
    private let addNoteButton = UIButton(type: .system)
    private let emptyNotesLabel = UILabel()
    
    // MARK: - Properties
    private let book: Book
    private var notes: [Note] = []
    
    // MARK: - Initialization
    init(book: Book) {
        self.book = book
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
        loadNotes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Book Details"
        
        // Add export button to navigation bar
        let exportButton = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportButtonTapped))
        navigationItem.rightBarButtonItem = exportButton
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        setupBookInfoView()
        setupNotesSection()
    }
    
    private func setupBookInfoView() {
        bookInfoView.translatesAutoresizingMaskIntoConstraints = false
        bookInfoView.backgroundColor = .secondarySystemBackground
        bookInfoView.layer.cornerRadius = 12
        bookInfoView.layer.masksToBounds = true
        contentView.addSubview(bookInfoView)
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = book.title
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        bookInfoView.addSubview(titleLabel)
        
        // Author label
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.text = "by \(book.author)"
        authorLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = 0
        authorLabel.textAlignment = .center
        bookInfoView.addSubview(authorLabel)
        
        // Year label
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        yearLabel.text = book.year
        yearLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        yearLabel.textColor = .secondaryLabel
        yearLabel.textAlignment = .center
        bookInfoView.addSubview(yearLabel)
        
        // Separator
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .separator
        contentView.addSubview(separatorView)
    }
    
    private func setupNotesSection() {
        // Notes header
        notesHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        notesHeaderLabel.text = "Notes"
        notesHeaderLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        notesHeaderLabel.textColor = .label
        contentView.addSubview(notesHeaderLabel)
        
        // Add note button
        addNoteButton.translatesAutoresizingMaskIntoConstraints = false
        addNoteButton.setTitle("📷 Add Note", for: .normal)
        addNoteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addNoteButton.backgroundColor = .systemBlue
        addNoteButton.setTitleColor(.white, for: .normal)
        addNoteButton.layer.cornerRadius = 8
        addNoteButton.addTarget(self, action: #selector(addNoteButtonTapped), for: .touchUpInside)
        contentView.addSubview(addNoteButton)
        
        // Empty notes label
        emptyNotesLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyNotesLabel.text = "No notes yet.\nTap 'Add Note' to capture text from a book page."
        emptyNotesLabel.font = UIFont.systemFont(ofSize: 16)
        emptyNotesLabel.textColor = .secondaryLabel
        emptyNotesLabel.textAlignment = .center
        emptyNotesLabel.numberOfLines = 0
        contentView.addSubview(emptyNotesLabel)
        
        // Notes table view
        notesTableView.translatesAutoresizingMaskIntoConstraints = false
        notesTableView.delegate = self
        notesTableView.dataSource = self
        notesTableView.backgroundColor = .systemBackground
        notesTableView.separatorStyle = .singleLine
        notesTableView.isScrollEnabled = false // We're inside a scroll view
        notesTableView.register(NoteTableViewCell.self, forCellReuseIdentifier: NoteTableViewCell.identifier)
        contentView.addSubview(notesTableView)
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
            
            // Book info view
            bookInfoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            bookInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bookInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: bookInfoView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: bookInfoView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: bookInfoView.trailingAnchor, constant: -16),
            
            // Author label
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: bookInfoView.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: bookInfoView.trailingAnchor, constant: -16),
            
            // Year label
            yearLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 4),
            yearLabel.leadingAnchor.constraint(equalTo: bookInfoView.leadingAnchor, constant: 16),
            yearLabel.trailingAnchor.constraint(equalTo: bookInfoView.trailingAnchor, constant: -16),
            yearLabel.bottomAnchor.constraint(equalTo: bookInfoView.bottomAnchor, constant: -20),
            
            // Separator
            separatorView.topAnchor.constraint(equalTo: bookInfoView.bottomAnchor, constant: 24),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Notes header
            notesHeaderLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 24),
            notesHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Add note button
            addNoteButton.centerYAnchor.constraint(equalTo: notesHeaderLabel.centerYAnchor),
            addNoteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addNoteButton.widthAnchor.constraint(equalToConstant: 100),
            addNoteButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Empty notes label
            emptyNotesLabel.topAnchor.constraint(equalTo: notesHeaderLabel.bottomAnchor, constant: 20),
            emptyNotesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emptyNotesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Notes table view
            notesTableView.topAnchor.constraint(equalTo: notesHeaderLabel.bottomAnchor, constant: 16),
            notesTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            notesTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            notesTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Methods
    private func loadNotes() {
        notes = BookLibraryManager.shared.getNotesForBook(book.id)
        updateNotesDisplay()
    }
    
    private func updateNotesDisplay() {
        let hasNotes = !notes.isEmpty
        emptyNotesLabel.isHidden = hasNotes
        notesTableView.isHidden = !hasNotes
        
        if hasNotes {
            notesTableView.reloadData()
            // Update table view height constraint
            updateTableViewHeight()
        }
        
        // Update notes header with count
        let noteCount = notes.count
        notesHeaderLabel.text = noteCount == 0 ? "Notes" : "Notes (\(noteCount))"
    }
    
    private func updateTableViewHeight() {
        notesTableView.layoutIfNeeded()
        let height = notesTableView.contentSize.height
        
        // Remove existing height constraint if any
        notesTableView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.isActive = false
            }
        }
        
        // Add new height constraint
        notesTableView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    // MARK: - Actions
    @objc private func addNoteButtonTapped() {
        let cameraVC = CameraViewController(bookId: book.id)
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    @objc private func exportButtonTapped() {
        guard !notes.isEmpty else {
            let alert = UIAlertController(title: "No Notes", message: "There are no notes to export for this book.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Export All Notes", message: "Choose export format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Plain Text", style: .default) { _ in
            self.exportAllNotesAsPlainText()
        })
        
        alert.addAction(UIAlertAction(title: "Markdown", style: .default) { _ in
            self.exportAllNotesAsMarkdown()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func showNoteDetail(_ note: Note) {
        let detailVC = NoteDetailViewController(note: note)
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func deleteNote(at index: Int) {
        let note = notes[index]
        
        let alert = UIAlertController(
            title: "Delete Note",
            message: "Are you sure you want to delete this note?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            BookLibraryManager.shared.deleteNote(withId: note.id)
            self.loadNotes()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Export Methods
    private func exportAllNotesAsPlainText() {
        let content = generatePlainTextExport()
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
    
    private func exportAllNotesAsMarkdown() {
        let content = generateMarkdownExport()
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
    
    private func generatePlainTextExport() -> String {
        var content = """
        \(book.title)
        by \(book.author) (\(book.year))
        
        Notes Export
        ============
        
        """
        
        for (index, note) in notes.enumerated() {
            let pageInfo = note.pageNumber != nil ? " (Page \(note.pageNumber!))" : ""
            content += """
            
            [\(index + 1)] \(note.title)\(pageInfo)
            Created: \(DateFormatter.noteDateDisplay.string(from: note.dateCreated))
            
            \(note.extractedText)
            
            ---
            
            """
        }
        
        content += """
        
        Exported on \(DateFormatter.noteDateDisplay.string(from: Date()))
        """
        
        return content
    }
    
    private func generateMarkdownExport() -> String {
        var content = """
        # \(book.title)
        
        **Author:** \(book.author)  
        **Year:** \(book.year)
        
        ## Notes
        
        """
        
        for (index, note) in notes.enumerated() {
            let pageInfo = note.pageNumber != nil ? " (Page \(note.pageNumber!))" : ""
            content += """
            
            ### \(index + 1). \(note.title)\(pageInfo)
            
            *Created: \(DateFormatter.noteDateDisplay.string(from: note.dateCreated))*
            
            \(note.extractedText)
            
            ---
            
            """
        }
        
        content += """
        
        *Exported on \(DateFormatter.noteDateDisplay.string(from: Date()))*
        """
        
        return content
    }
}

// MARK: - UITableViewDataSource
extension BookDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteTableViewCell.identifier, for: indexPath) as? NoteTableViewCell else {
            return UITableViewCell()
        }
        
        let note = notes[indexPath.row]
        cell.configure(with: note)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BookDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let note = notes[indexPath.row]
        showNoteDetail(note)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteNote(at: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
}

// MARK: - CameraViewControllerDelegate
extension BookDetailsViewController: CameraViewControllerDelegate {
    func didSaveNote(_ note: Note) {
        // Note is already saved by the camera flow, just reload the display
        loadNotes()
    }
    
    func didCancelCapture() {
        // No action needed
    }
}

// MARK: - NoteDetailViewControllerDelegate
protocol NoteDetailViewControllerDelegate: AnyObject {
    func didUpdateNote()
}

extension BookDetailsViewController: NoteDetailViewControllerDelegate {
    func didUpdateNote() {
        loadNotes()
    }
}

// MARK: - NoteTableViewCell
class NoteTableViewCell: UITableViewCell {
    static let identifier = "NoteTableViewCell"
    
    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let dateLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure labels
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        previewLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2
        
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .tertiaryLabel
        
        // Configure stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(previewLabel)
        stackView.addArrangedSubview(dateLabel)
        
        contentView.addSubview(stackView)
        
        // Set cell properties
        accessoryType = .disclosureIndicator
        selectionStyle = .default
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with note: Note) {
        titleLabel.text = note.title
        
        // Create preview text (first few words)
        let preview = note.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = preview.components(separatedBy: .whitespacesAndNewlines)
        let previewText = words.prefix(15).joined(separator: " ")
        previewLabel.text = previewText + (words.count > 15 ? "..." : "")
        
        // Include page number in date label if available
        var dateText = DateFormatter.noteDateDisplay.string(from: note.dateCreated)
        if let pageNumber = note.pageNumber, !pageNumber.isEmpty {
            dateText += " • Page \(pageNumber)"
        }
        dateLabel.text = dateText
    }
}
