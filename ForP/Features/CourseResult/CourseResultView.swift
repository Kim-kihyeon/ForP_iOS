import SwiftUI

struct CourseResultView: View {
    @State private var viewModel = CourseResultViewModel()
    let course: Course

    var body: some View {
        Group {
            switch course.mode {
            case .ordered:
                OrderedCourseView(places: course.places)
            case .list:
                ListCourseView(places: course.places)
            }
        }
        .navigationTitle(course.title)
    }
}
