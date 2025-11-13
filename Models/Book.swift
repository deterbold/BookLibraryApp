import Foundation

// MARK: - Note Model
struct Note: Codable, Equatable {
    let id: UUID
    let bookId: UUID
    var extractedText: String
    let dateCreated: Date
    var title: String // Optional title for the note
    var pageNumber: String? // Page number where the text was found
    
    init(bookId: UUID, extractedText: String, title: String = "", pageNumber: String? = nil) {
        self.id = UUID()
        self.bookId = bookId
        self.extractedText = extractedText
        self.dateCreated = Date()
        self.title = title.isEmpty ? "Note \(DateFormatter.noteTitle.string(from: Date()))" : title
        self.pageNumber = pageNumber
    }
}

// MARK: - Updated Book Model
struct Book: Codable, Equatable {
    let id: UUID
    var author: String
    var title: String
    var year: String
    let dateCreated: Date
    
    init(author: String, title: String, year: String) {
        self.id = UUID()
        self.author = author
        self.title = title
        self.year = year
        self.dateCreated = Date()
    }
}

// MARK: - Sorting Options
enum BookSortOption {
    case author
    case title
    case year
}

// MARK: - Updated Book Library Manager
class BookLibraryManager {
    static let shared = BookLibraryManager()
    
    private let userDefaults = UserDefaults.standard
    private let booksKey = "SavedBooks"
    private let notesKey = "SavedNotes"
    
    private var books: [Book] = []
    private var notes: [Note] = []
    
    private init() {
        loadBooks()
        loadNotes()
    }
    
    // MARK: - Book CRUD Operations
    
    func addBook(_ book: Book) {
        books.append(book)
        saveBooks()
    }
    
    func deleteBook(at index: Int) {
        guard index < books.count else { return }
        let bookId = books[index].id
        books.remove(at: index)
        
        // Also delete all notes for this book
        notes.removeAll { $0.bookId == bookId }
        
        saveBooks()
        saveNotes()
    }
    
    func deleteBook(withId id: UUID) {
        books.removeAll { $0.id == id }
        // Also delete all notes for this book
        notes.removeAll { $0.bookId == id }
        
        saveBooks()
        saveNotes()
    }
    
    func getAllBooks() -> [Book] {
        return books
    }
    
    func getSortedBooks(by sortOption: BookSortOption) -> [Book] {
        switch sortOption {
        case .author:
            return books.sorted { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
        case .title:
            return books.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .year:
            return books.sorted { book1, book2 in
                let year1 = book1.year.trimmingCharacters(in: .whitespacesAndNewlines)
                let year2 = book2.year.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let int1 = Int(year1), let int2 = Int(year2) {
                    return int1 < int2
                }
                
                return year1.localizedCaseInsensitiveCompare(year2) == .orderedAscending
            }
        }
    }
    
    func getBook(withId id: UUID) -> Book? {
        return books.first { $0.id == id }
    }
    
    // MARK: - Note CRUD Operations
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    func deleteNote(withId id: UUID) {
        notes.removeAll { $0.id == id }
        saveNotes()
    }
    
    func deleteNote(at index: Int, for bookId: UUID) {
        let bookNotes = getNotesForBook(bookId)
        guard index < bookNotes.count else { return }
        
        let noteToDelete = bookNotes[index]
        notes.removeAll { $0.id == noteToDelete.id }
        saveNotes()
    }
    
    func getNotesForBook(_ bookId: UUID) -> [Note] {
        return notes.filter { $0.bookId == bookId }.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    func getAllNotes() -> [Note] {
        return notes.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    func updateNote(_ updatedNote: Note) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    // MARK: - Persistence
    
    private func saveBooks() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(books)
            userDefaults.set(data, forKey: booksKey)
        } catch {
            print("Failed to save books: \(error)")
        }
    }
    
    private func loadBooks() {
        guard let data = userDefaults.data(forKey: booksKey) else {
            books = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            books = try decoder.decode([Book].self, from: data)
        } catch {
            print("Failed to load books: \(error)")
            books = []
        }
    }
    
    private func saveNotes() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notes)
            userDefaults.set(data, forKey: notesKey)
        } catch {
            print("Failed to save notes: \(error)")
        }
    }
    
    private func loadNotes() {
        guard let data = userDefaults.data(forKey: notesKey) else {
            notes = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            notes = try decoder.decode([Note].self, from: data)
        } catch {
            print("Failed to load notes: \(error)")
            notes = []
        }
    }
    
    // MARK: - Utility Methods
    
    func getBookCount() -> Int {
        return books.count
    }
    
    func getBook(at index: Int) -> Book? {
        guard index < books.count else { return nil }
        return books[index]
    }
    
    func getNoteCount(for bookId: UUID) -> Int {
        return notes.filter { $0.bookId == bookId }.count
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let noteTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let noteDateDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
