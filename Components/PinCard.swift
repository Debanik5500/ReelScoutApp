import SwiftUI

/// A single masonry "pin" in the Library grid: image, heart, place chip, title.
struct PinCard: View {
    let reel: Reel
    let height: CGFloat
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(reel.coverImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pin, style: .continuous))

                Button(action: onLike) {
                    Image(systemName: reel.liked ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(reel.liked ? Theme.accentHighlight : Theme.text)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial, in: Circle())
                }
                .padding(8)

                if let place = reel.place {
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill").font(.system(size: 11))
                            Text(place.name).font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(Theme.placeFg)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: height)

            Text(reel.title ?? "")
                .font(Theme.Font.body(14, weight: .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Text(reel.author)
                .font(Theme.Font.body(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
