import UIKit

class LibraryViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let addFirstBookButton = UIButton(type: .system)
    
    private var addButton: UIBarButtonItem!
    private var sortByAuthorButton: UIBarButtonItem!
    private var sortByTitleButton: UIBarButtonItem!
    private var sortByYearButton: UIBarButtonItem!
    
    // MARK: - Properties
    private var books: [Book] = []
    private var currentSortOption: BookSortOption = .author
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupToolbar()
        setupEmptyState()
        setupConstraints()
        loadBooks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBooks()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "My Library"
        
        // Setup navigation bar
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
        
        // Show toolbar
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Register cell
        tableView.register(BookTableViewCell.self, forCellReuseIdentifier: BookTableViewCell.identifier)
        
        view.addSubview(tableView)
    }
    
    private func setupToolbar() {
        // Create sort buttons
        sortByAuthorButton = UIBarButtonItem(title: "Author", style: .plain, target: self, action: #selector(sortByAuthorTapped))
        sortByTitleButton = UIBarButtonItem(title: "Title", style: .plain, target: self, action: #selector(sortByTitleTapped))
        sortByYearButton = UIBarButtonItem(title: "Year", style: .plain, target: self, action: #selector(sortByYearTapped))
        
        // Create flexible spaces
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Set toolbar items
        toolbarItems = [
            flexibleSpace,
            sortByAuthorButton,
            flexibleSpace,
            sortByTitleButton,
            flexibleSpace,
            sortByYearButton,
            flexibleSpace
        ]
        
        // Set initial sort button state
        updateSortButtonStates()
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.backgroundColor = .systemBackground
        emptyStateView.isHidden = true
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "No books in your library yet"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        
        addFirstBookButton.translatesAutoresizingMaskIntoConstraints = false
        addFirstBookButton.setTitle("Add Your First Book", for: .normal)
        addFirstBookButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addFirstBookButton.backgroundColor = .systemBlue
        addFirstBookButton.setTitleColor(.white, for: .normal)
        addFirstBookButton.layer.cornerRadius = 8
        addFirstBookButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(addFirstBookButton)
        view.addSubview(emptyStateView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Empty state view constraints
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Empty state label constraints
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -30),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -40),
            
            // Add first book button constraints
            addFirstBookButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 24),
            addFirstBookButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            addFirstBookButton.widthAnchor.constraint(equalToConstant: 200),
            addFirstBookButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data Methods
    private func loadBooks() {
        books = BookLibraryManager.shared.getSortedBooks(by: currentSortOption)
        updateUI()
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = books.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        // Update toolbar visibility based on content
        navigationController?.setToolbarHidden(isEmpty, animated: true)
    }
    
    private func updateSortButtonStates() {
        // Reset all buttons to normal state
        sortByAuthorButton.style = .plain
        sortByTitleButton.style = .plain
        sortByYearButton.style = .plain
        
        // Highlight current sort option
        switch currentSortOption {
        case .author:
            sortByAuthorButton.style = .done
        case .title:
            sortByTitleButton.style = .done
        case .year:
            sortByYearButton.style = .done
        }
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let addBookVC = AddBookViewController()
        addBookVC.delegate = self
        navigationController?.pushViewController(addBookVC, animated: true)
    }
    
    @objc private func sortByAuthorTapped() {
        currentSortOption = .author
        updateSortButtonStates()
        loadBooks()
    }
    
    @objc private func sortByTitleTapped() {
        currentSortOption = .title
        updateSortButtonStates()
        loadBooks()
    }
    
    @objc private func sortByYearTapped() {
        currentSortOption = .year
        updateSortButtonStates()
        loadBooks()
    }
    
    // MARK: - Helper Methods
    private func deleteBook(at indexPath: IndexPath) {
        let book = books[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Book",
            message: "Are you sure you want to delete \"\(book.title)\" by \(book.author)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            BookLibraryManager.shared.deleteBook(withId: book.id)
            self.loadBooks()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension LibraryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookTableViewCell.identifier, for: indexPath) as? BookTableViewCell else {
            return UITableViewCell()
        }
        
        let book = books[indexPath.row]
        cell.configure(with: book)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LibraryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let book = books[indexPath.row]
        let bookDetailsVC = BookDetailsViewController(book: book)
        navigationController?.pushViewController(bookDetailsVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteBook(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
}

// MARK: - AddBookViewControllerDelegate
extension LibraryViewController: AddBookViewControllerDelegate {
    func didAddBook(_ book: Book) {
        loadBooks()
    }
    
    func didCancelAddBook() {
        // No action needed
    }
}

// MARK: - BookTableViewCell
class BookTableViewCell: UITableViewCell {
    static let identifier = "BookTableViewCell"
    
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let yearLabel = UILabel()
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
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        
        authorLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        authorLabel.textColor = .secondaryLabel
        
        yearLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        yearLabel.textColor = .secondaryLabel
        
        // Configure stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(authorLabel)
        stackView.addArrangedSubview(yearLabel)
        
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
    
    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = "by \(book.author)"
        yearLabel.text = book.year
    }
}
