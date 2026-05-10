//
//  CloudKitVotingService.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import CloudKit
import Combine
import Foundation

struct CloudChallengePost: Identifiable, Equatable {
    let id: String
    let recordID: CKRecord.ID
    let authorID: String
    let authorName: String
    let caption: String
    let outfitName: String
    let outfitSummary: String
    let voteCount: Int
    let createdAt: Date
    let imageFileURL: URL?

    var isCurrentUserPost: Bool {
        authorID == CloudVotingViewModel.currentUserID
    }
}

struct CloudVotingService {
    private enum RecordType {
        static let challengePost = "ChallengePost"
        static let vote = "Vote"
    }

    private enum Field {
        static let challengeID = "challengeID"
        static let authorID = "authorID"
        static let authorName = "authorName"
        static let caption = "caption"
        static let outfitName = "outfitName"
        static let outfitSummary = "outfitSummary"
        static let voteCount = "voteCount"
        static let createdAt = "createdAt"
        static let imageAsset = "imageAsset"
        static let postRecordName = "postRecordName"
        static let voterID = "voterID"
    }

    private let database: CKDatabase

    init(containerIdentifier: String = AppConfiguration.cloudKitContainerIdentifier) {
        database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    func fetchPosts() async throws -> [CloudChallengePost] {
        let predicate = NSPredicate(format: "%K == %@", Field.challengeID, AppConfiguration.currentChallengeID)
        let query = CKQuery(recordType: RecordType.challengePost, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: Field.createdAt, ascending: false)]

        let result = try await database.records(matching: query, resultsLimit: 50)
        let records = result.matchResults.compactMap { _, recordResult in
            try? recordResult.get()
        }

        return records.compactMap(makePost(from:))
    }

    func fetchVotedPostIDs(for userID: String) async throws -> Set<String> {
        let predicate = NSPredicate(format: "%K == %@", Field.voterID, userID)
        let query = CKQuery(recordType: RecordType.vote, predicate: predicate)
        let result = try await database.records(matching: query, resultsLimit: 100)

        let votedIDs = result.matchResults.compactMap { _, recordResult -> String? in
            guard let record = try? recordResult.get() else { return nil }
            return record[Field.postRecordName] as? String
        }

        return Set(votedIDs)
    }

    func submitPost(
        authorID: String,
        authorName: String,
        caption: String,
        outfitName: String,
        outfitSummary: String,
        imageData: Data?
    ) async throws {
        let record = CKRecord(recordType: RecordType.challengePost)
        record[Field.challengeID] = AppConfiguration.currentChallengeID
        record[Field.authorID] = authorID
        record[Field.authorName] = authorName
        record[Field.caption] = caption
        record[Field.outfitName] = outfitName
        record[Field.outfitSummary] = outfitSummary
        record[Field.voteCount] = 0
        record[Field.createdAt] = Date()

        if let imageData, let fileURL = try? writeTemporaryImage(data: imageData) {
            record[Field.imageAsset] = CKAsset(fileURL: fileURL)
        }

        _ = try await database.save(record)
    }

    func vote(for post: CloudChallengePost, userID: String) async throws {
        let voteID = CKRecord.ID(recordName: voteRecordName(postID: post.recordID.recordName, userID: userID))
        let vote = CKRecord(recordType: RecordType.vote, recordID: voteID)
        vote[Field.postRecordName] = post.recordID.recordName
        vote[Field.voterID] = userID
        vote[Field.createdAt] = Date()

        _ = try await database.save(vote)
        try await updateVoteCount(for: post.recordID, by: 1)
    }

    func removeVote(for post: CloudChallengePost, userID: String) async throws {
        let voteID = CKRecord.ID(recordName: voteRecordName(postID: post.recordID.recordName, userID: userID))
        try await database.deleteRecord(withID: voteID)
        try await updateVoteCount(for: post.recordID, by: -1)
    }

    private func updateVoteCount(for postRecordID: CKRecord.ID, by delta: Int) async throws {
        let record = try await database.record(for: postRecordID)
        let currentCount = record[Field.voteCount] as? Int ?? 0
        record[Field.voteCount] = max(currentCount + delta, 0)
        _ = try await database.save(record)
    }

    private func makePost(from record: CKRecord) -> CloudChallengePost? {
        guard
            let authorID = record[Field.authorID] as? String,
            let authorName = record[Field.authorName] as? String,
            let caption = record[Field.caption] as? String,
            let outfitName = record[Field.outfitName] as? String,
            let outfitSummary = record[Field.outfitSummary] as? String
        else {
            return nil
        }

        let asset = record[Field.imageAsset] as? CKAsset

        return CloudChallengePost(
            id: record.recordID.recordName,
            recordID: record.recordID,
            authorID: authorID,
            authorName: authorName,
            caption: caption,
            outfitName: outfitName,
            outfitSummary: outfitSummary,
            voteCount: record[Field.voteCount] as? Int ?? 0,
            createdAt: record[Field.createdAt] as? Date ?? .now,
            imageFileURL: asset?.fileURL
        )
    }

    private func voteRecordName(postID: String, userID: String) -> String {
        let safeUserID = userID
            .replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
        return "vote_\(postID)_\(safeUserID)"
    }

    private func writeTemporaryImage(data: Data) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

@MainActor
final class CloudVotingViewModel: ObservableObject {
    static var currentUserID = ""

    @Published private(set) var posts: [CloudChallengePost] = []
    @Published private(set) var votedPostIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published var message: String?

    private let service = CloudVotingService()

    func load(userID: String) async {
        Self.currentUserID = userID
        isLoading = true
        defer { isLoading = false }

        do {
            async let posts = service.fetchPosts()
            async let votedPostIDs = service.fetchVotedPostIDs(for: userID)
            self.posts = try await posts
            self.votedPostIDs = try await votedPostIDs
            message = nil
        } catch {
            message = "ما قدرنا نحمّل المشاركات. تأكدي من iCloud والاتصال."
        }
    }

    func submit(outfit: Outfit, profile: Profile, userID: String) async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await service.submitPost(
                authorID: userID,
                authorName: profile.name,
                caption: "مشاركتي في تحدي الأسبوع من دولابي.",
                outfitName: outfit.name,
                outfitSummary: outfit.summaryText,
                imageData: outfit.coverImageData
            )
            message = "تم نشر مشاركتك في التحدي."
            await load(userID: userID)
        } catch {
            message = "ما قدرنا ننشر المشاركة. جرّبي مرة ثانية."
        }
    }

    func toggleVote(for post: CloudChallengePost, userID: String) async {
        do {
            if votedPostIDs.contains(post.id) {
                try await service.removeVote(for: post, userID: userID)
                votedPostIDs.remove(post.id)
            } else {
                try await service.vote(for: post, userID: userID)
                votedPostIDs.insert(post.id)
            }

            posts = try await service.fetchPosts()
            message = nil
        } catch {
            message = "ما قدرنا نحفظ التصويت. جرّبي مرة ثانية."
        }
    }
}

private extension Outfit {
    var summaryText: String {
        if let onePieceGarment {
            return "\(onePieceGarment.title) • \(onePieceGarment.colorName)"
        }

        let top = topGarment?.title ?? "قطعة علوية"
        let bottom = bottomGarment?.title ?? "قطعة سفلية"
        return "\(top) + \(bottom)"
    }

    var coverImageData: Data? {
        onePieceGarment?.imageData ?? topGarment?.imageData ?? bottomGarment?.imageData
    }
}
