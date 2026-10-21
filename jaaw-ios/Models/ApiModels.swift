import Foundation

// MARK: - jaaw API models
// POST /login returns all of these in one payload.

struct UserProfile: Codable, Hashable {
    var name: String = ""
    var registrationNumber: String = ""
    var batch: String = ""
    var semester: String = ""
    var department: String = ""
    var section: String = ""
    var mobileNumber: String = ""
    var program: String = ""
}

struct AttendanceRecord: Codable, Hashable {
    var courseCode: String = ""
    var courseTitle: String = ""
    var courseType: String = ""
    var slot: String = ""
    var classesConducted: Int = 0
    var classesAbsent: Int = 0
    var attendancePercentage: Double = 0
}

struct MarkAssessment: Codable, Hashable {
    var title: String = ""
    var obtainedMarks: String = ""
    var maximumMarks: String = ""

    /// A component is only meaningful when it carries a positive maximum.
    /// The portal leaks non-score rows — repeated headings (`Mark / Max. Mark`),
    /// blank cells and `0/0` placeholders — which all parse to a missing/zero
    /// maximum and would otherwise render as "0.00/0.00" in the breakdown.
    var isMeaningful: Bool {
        guard let max = Double(maximumMarks.trimmingCharacters(in: .whitespaces)),
              max > 0
        else { return false }
        return true
    }
}

struct MarkRecord: Codable, Hashable {
    var courseCode: String = ""
    var courseType: String = ""
    var summary: String = ""
    var assessments: [MarkAssessment] = []
    var totalMarksObtained: Double?
    var totalMarksMaximum: Double?

    enum CodingKeys: String, CodingKey {
        case courseCode, courseType, summary, assessments
        case totalMarksObtained, totalMarksMaximum
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        courseCode = (try? c.decode(String.self, forKey: .courseCode)) ?? ""
        courseType = (try? c.decode(String.self, forKey: .courseType)) ?? ""
        summary = (try? c.decode(String.self, forKey: .summary)) ?? ""
        assessments = ((try? c.decode([MarkAssessment].self, forKey: .assessments)) ?? [])
            .filter(\.isMeaningful)
        totalMarksObtained = Self.decodeDouble(c, key: .totalMarksObtained)
        totalMarksMaximum = Self.decodeDouble(c, key: .totalMarksMaximum)
    }

    init(
        courseCode: String = "",
        courseType: String = "",
        summary: String = "",
        assessments: [MarkAssessment] = [],
        totalMarksObtained: Double? = nil,
        totalMarksMaximum: Double? = nil
    ) {
        self.courseCode = courseCode
        self.courseType = courseType
        self.summary = summary
        self.assessments = assessments
        self.totalMarksObtained = totalMarksObtained
        self.totalMarksMaximum = totalMarksMaximum
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(courseCode, forKey: .courseCode)
        try c.encode(courseType, forKey: .courseType)
        try c.encode(summary, forKey: .summary)
        try c.encode(assessments, forKey: .assessments)
        try c.encodeIfPresent(totalMarksObtained, forKey: .totalMarksObtained)
        try c.encodeIfPresent(totalMarksMaximum, forKey: .totalMarksMaximum)
    }

    static func decodeDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let v = try? c.decode(Double.self, forKey: key) { return v }
        if let v = try? c.decode(Int.self, forKey: key) { return Double(v) }
        if let s = try? c.decode(String.self, forKey: key) { return Double(s.trimmingCharacters(in: .whitespaces)) }
        return nil
    }
}

struct CourseSlot: Codable, Hashable {
    var slotCode: String = ""
    var slotType: String = ""
    var rawType: String = ""
    var faculty: String = ""
    var room: String = ""
    var slotLabel: String = ""
}

struct CourseCatalogEntry: Codable, Hashable {
    var courseCode: String = ""
    var courseTitle: String = ""
    var credits: String = ""
    var slots: [CourseSlot] = []
}

struct ScheduleEntry: Codable, Hashable {
    var slotCode: String = ""
    var courseCode: String = ""
    var courseTitle: String = ""
    var slotType: String = ""
    var rawType: String = ""
    var room: String = ""
    var faculty: String = ""
    var timeLabel: String = ""
    var startTime: String = ""
    var endTime: String = ""
}

struct ScheduleDay: Codable, Hashable {
    var dayLabel: String = ""
    var entries: [ScheduleEntry] = []
}

struct CalendarEntry: Codable, Hashable {
    var date: String = ""
    var day: String = ""
    var title: String?
    var dayOrder: String?
    var category: String = "empty"
    var month: String = ""
    var monthIndex: Int = 0
    var rawMonthLabel: String = ""
}

struct CalendarMonth: Codable, Hashable {
    var month: String = ""
    var monthIndex: Int = 0
    var year: Int = 0
    var label: String = ""
    var entries: [CalendarEntry] = []
}

struct AcademicCalendar: Codable, Hashable {
    var plannerType: String = ""
    var academicYearLabel: String = ""
    var sourcePage: String = ""
    var months: [CalendarMonth] = []
}

struct SessionPayload: Codable, Hashable {
    var cookies: [String: String] = [:]
}

struct LoginResponse: Codable {
    var success: Bool = false
    /// The server's explanation when `success` is false.
    var message: String?
    var profile: UserProfile = UserProfile()
    var attendance: [AttendanceRecord] = []
    var marks: [MarkRecord] = []
    var schedule: [ScheduleDay] = []
    var courses: [CourseCatalogEntry] = []
    var calendar: AcademicCalendar = AcademicCalendar()
    var session: SessionPayload = SessionPayload()
}
