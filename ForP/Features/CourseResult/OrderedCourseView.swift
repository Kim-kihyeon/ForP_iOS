import SwiftUI

struct OrderedCourseView: View {
    let places: [CoursePlace]

    var body: some View {
        List(places, id: \.order) { place in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(place.order). \(place.placeName ?? place.keyword)")
                    .font(.headline)
                Text(place.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(place.reason)
                    .font(.caption2)
            }
        }
    }
}
