import SwiftUI

struct FilterListToggle: View {
    let filterList: FilterList
    let onToggle: (Bool) -> Void

    var body: some View {
        Toggle(
            isOn: Binding(
                get: { filterList.isEnabled },
                set: { newValue in
                    onToggle(newValue)
                }
            )
        ) {
            // No label needed since it's handled in the parent view
            EmptyView()
        }
        .toggleStyle(SwitchToggleStyle())
        .labelsHidden()
    }
}
