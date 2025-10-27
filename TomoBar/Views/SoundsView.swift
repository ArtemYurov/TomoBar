import AppKit
import SwiftUI

struct SoundsView: View {
    @EnvironmentObject var player: TBPlayer
    var sliderWidth: CGFloat

    var body: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.fixed(sliderWidth))
        ]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("SoundsView.isWindupEnabled.label",
                                   comment: "Windup label"))
            VolumeSlider(volume: $player.windupVolume)
            Text(NSLocalizedString("SoundsView.isDingEnabled.label",
                                   comment: "Ding label"))
            VolumeSlider(volume: $player.dingVolume)
            Text(NSLocalizedString("SoundsView.isTickingEnabled.label",
                                   comment: "Ticking label"))
            VolumeSlider(volume: $player.tickingVolume)
        }.padding(4)
        Button {
            TBStatusItem.shared.closePopover(nil)
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: player.soundFolder.path)
        } label: {
            Text(NSLocalizedString("SoundsView.openSoundFolder.label", comment: "Open sound folder label"))
        }
        Spacer().frame(minHeight: 0)
    }
}
