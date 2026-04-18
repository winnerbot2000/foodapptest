import SwiftUI

/// A control for editing a rating on a 0–10 scale.  Displays a label,
/// current value and a slider.  The underlying value is bound to an
/// `Int` property on the caller.  Sliders are accessible with
/// VoiceOver due to the discrete step value.
struct RatingSlider: View {
    @Binding private var value: Int
    private let label: String

    init(label: String, value: Binding<Int>) {
        self.label = label
        self._value = value
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .font(AppTypography.subheadline)
                Spacer()
                Text("\(value)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.primary)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in value = Int(newValue) }
                ),
                in: 0...10,
                step: 1
            )
        }
        .padding(.vertical, AppSpacing.sm)
    }
}