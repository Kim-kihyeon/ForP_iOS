import SwiftUI

struct ListCourseView: View {
    let places: [CoursePlace]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(places, id: \.order) { place in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.placeName ?? place.keyword)
                            .font(.headline)
                        Text(place.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(place.reason)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}
