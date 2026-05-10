//
//  VoteTabView.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftData
import SwiftUI
import UIKit

struct VoteTabView: View {
    let profile: Profile
    let userIdentifier: String

    @StateObject private var votingViewModel = CloudVotingViewModel()
    @State private var selectedOutfit: Outfit?

    private var savedOutfits: [Outfit] {
        profile.outfits.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            challengeCard
            submissionCard
            messageView
            communityFeed
            leaderboardCard
        }
        .task {
            await votingViewModel.load(userID: userIdentifier)
        }
        .refreshable {
            await votingViewModel.load(userID: userIdentifier)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("تحدي الإطلالات")
                .font(.system(size: 30, weight: .semibold, design: .serif))
            Text("البنات يشاركون إطلالاتهم، والباقين يصوتون للإطلالة اللي تعجبهم مثل اللايك.")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var challengeCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("تحدي هذا الأسبوع")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("مباشر", systemImage: "icloud.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tallaSage)
                }

                Text("مناسبة قريبة؟ نسقيها من دولابك")
                    .font(.system(size: 25, weight: .semibold, design: .serif))

                Text("انشري إطلالة محفوظة من قطعك، وخلي البنات يصوتون عليها. المشاركات والأصوات محفوظة في CloudKit.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var submissionCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("شاركي في التحدي")
                    .font(.system(size: 24, weight: .semibold, design: .serif))

                if savedOutfits.isEmpty {
                    Text("احفظي إطلالة من تبويب الدولاب أولًا، بعدها تقدرين تنشرينها في التحدي.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("اختاري إطلالة محفوظة، ثم انشريها للبنات عشان يصوتون لها.")
                        .foregroundStyle(.secondary)

                    ForEach(Array(savedOutfits.prefix(3))) { outfit in
                        Button {
                            selectedOutfit = outfit
                        } label: {
                            HStack(spacing: 12) {
                                OutfitPreview(outfit: outfit)
                                    .frame(width: 72, height: 84)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(outfit.name)
                                        .font(.headline)
                                    Text(outfitSummary(outfit))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: selectedOutfit?.persistentModelID == outfit.persistentModelID ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedOutfit?.persistentModelID == outfit.persistentModelID ? Color.tallaSage : Color.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button(votingViewModel.isSubmitting ? "جاري النشر..." : "انشري مشاركتي") {
                        guard let selectedOutfit else { return }
                        Task {
                            await votingViewModel.submit(
                                outfit: selectedOutfit,
                                profile: profile,
                                userID: userIdentifier
                            )
                        }
                    }
                    .buttonStyle(TallaPrimaryButtonStyle())
                    .disabled(selectedOutfit == nil || votingViewModel.isSubmitting)
                }
            }
        }
    }

    @ViewBuilder
    private var messageView: some View {
        if let message = votingViewModel.message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(message.contains("تم") ? Color.tallaSage : .red)
                .padding(.horizontal, 4)
        }
    }

    private var communityFeed: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("مشاركات البنات")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                Spacer()
                if votingViewModel.isLoading {
                    ProgressView()
                }
            }

            if votingViewModel.posts.isEmpty, !votingViewModel.isLoading {
                TallaCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("لسه ما فيه مشاركات")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                        Text("كوني أول وحدة تشارك في تحدي الأسبوع.")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(votingViewModel.posts) { post in
                    ChallengePostCard(
                        post: post,
                        isCurrentUser: post.authorID == userIdentifier,
                        didVote: votingViewModel.votedPostIDs.contains(post.id),
                        onVote: {
                            Task {
                                await votingViewModel.toggleVote(for: post, userID: userIdentifier)
                            }
                        }
                    )
                }
            }
        }
    }

    private var leaderboardCard: some View {
        let topPosts = votingViewModel.posts
            .sorted { $0.voteCount > $1.voteCount }
            .prefix(3)

        return TallaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("الأكثر تصويتًا")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                    Spacer()
                    Text("هذا الأسبوع")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                if topPosts.isEmpty {
                    Text("تظهر هنا أعلى المشاركات بعد بدء التصويت.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(topPosts)) { post in
                        leaderboardRow(
                            name: post.authorName,
                            role: post.outfitName,
                            score: "\(post.voteCount) صوت"
                        )
                    }
                }
            }
        }
    }

    private func outfitSummary(_ outfit: Outfit) -> String {
        if let onePiece = outfit.onePieceGarment {
            return "\(onePiece.title) • \(onePiece.colorName)"
        }

        let top = outfit.topGarment?.title ?? "قطعة علوية"
        let bottom = outfit.bottomGarment?.title ?? "قطعة سفلية"
        return "\(top) + \(bottom)"
    }

    private func leaderboardRow(name: String, role: String, score: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.tallaSoft)
                .frame(width: 42, height: 42)
                .overlay {
                    Text(String(name.prefix(1)))
                        .font(.headline)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(score)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ChallengePostCard: View {
    let post: CloudChallengePost
    let isCurrentUser: Bool
    let didVote: Bool
    let onVote: () -> Void

    var body: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isCurrentUser ? Color.tallaSage.opacity(0.45) : Color.tallaSoft)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Text(String(post.authorName.prefix(1)))
                                .font(.headline)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isCurrentUser ? "\(post.authorName) • أنتِ" : post.authorName)
                            .font(.headline)
                        Text(post.outfitName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                CloudPostImageView(fileURL: post.imageFileURL)
                    .frame(height: 280)

                Text(post.caption)
                    .foregroundStyle(.secondary)

                Text(post.outfitSummary)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.tallaTaupe)

                HStack {
                    Button(action: onVote) {
                        Label(didVote ? "تم التصويت" : "صوّتي", systemImage: didVote ? "heart.fill" : "heart")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(didVote ? Color.tallaBlush : Color.tallaInk)
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCurrentUser)

                    Text("\(post.voteCount) صوت")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 86, alignment: .trailing)
                }

                if isCurrentUser {
                    Text("مشاركتك ظاهرة للبنات. ما تقدرين تصوتين لنفسك.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CloudPostImageView: View {
    let fileURL: URL?

    var body: some View {
        Group {
            if let fileURL,
               let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.tallaSoft, Color.tallaTaupe.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 34))
                        Text("إطلالة مشاركة")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                        Text("الصورة تظهر هنا إذا كانت المشاركة تحتوي صورة.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct OutfitPreview: View {
    let outfit: Outfit

    var body: some View {
        Group {
            if let onePiece = outfit.onePieceGarment {
                GarmentImageView(garment: onePiece, height: 280)
            } else {
                HStack(spacing: 8) {
                    if let top = outfit.topGarment {
                        GarmentImageView(garment: top, height: 280)
                    }
                    if let bottom = outfit.bottomGarment {
                        GarmentImageView(garment: bottom, height: 280)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
