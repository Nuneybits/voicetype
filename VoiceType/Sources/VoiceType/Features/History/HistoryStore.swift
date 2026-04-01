import Foundation
import SQLite3

final class HistoryStore {
    private var db: OpaquePointer?

    init(path: String = HistoryStore.defaultPath) {
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            fatalError("Failed to open database at \(path)")
        }
        createTable()
    }

    deinit {
        sqlite3_close(db)
    }

    static var defaultPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VoiceType", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.sqlite").path
    }

    private func createTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS transcriptions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                app_name TEXT NOT NULL,
                app_bundle_id TEXT NOT NULL,
                word_count INTEGER NOT NULL,
                created_at REAL NOT NULL
            );
        """
        sqlite3_exec(db, sql, nil, nil, nil)

        let indexSQL = "CREATE INDEX IF NOT EXISTS idx_created_at ON transcriptions(created_at DESC);"
        sqlite3_exec(db, indexSQL, nil, nil, nil)
    }

    func insert(text: String, appName: String, appBundleID: String) throws {
        let sql = "INSERT INTO transcriptions (text, app_name, app_bundle_id, word_count, created_at) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        let wordCount = text.split(separator: " ").count
        sqlite3_bind_text(stmt, 1, (text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (appName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (appBundleID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 4, Int32(wordCount))
        sqlite3_bind_double(stmt, 5, Date().timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryError.insertFailed
        }
    }

    func fetchRecent(limit: Int) throws -> [TranscriptionRecord] {
        let sql = "SELECT id, text, app_name, app_bundle_id, word_count, created_at FROM transcriptions ORDER BY created_at DESC LIMIT ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var records: [TranscriptionRecord] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let record = TranscriptionRecord(
                id: sqlite3_column_int64(stmt, 0),
                text: String(cString: sqlite3_column_text(stmt, 1)),
                appName: String(cString: sqlite3_column_text(stmt, 2)),
                appBundleID: String(cString: sqlite3_column_text(stmt, 3)),
                wordCount: Int(sqlite3_column_int(stmt, 4)),
                createdAt: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
            )
            records.append(record)
        }
        return records
    }

    func pruneKeeping(count: Int) throws {
        let sql = "DELETE FROM transcriptions WHERE id NOT IN (SELECT id FROM transcriptions ORDER BY created_at DESC LIMIT ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(count))
        sqlite3_step(stmt)
    }

    func totalWordCount() throws -> Int {
        let sql = "SELECT COALESCE(SUM(word_count), 0) FROM transcriptions"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    func totalDictationCount() throws -> Int {
        let sql = "SELECT COUNT(*) FROM transcriptions"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }
}

enum HistoryError: Error {
    case prepareFailed
    case insertFailed
}
