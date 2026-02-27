import SwiftUI
import AVKit

struct AirPlayRoutePickerView: View {
    init() {}

    var body: some View {
        _AirPlayRoutePickerView()
            .frame(width: 44, height: 44)
    }
}

#if os(macOS)
private struct _AirPlayRoutePickerView: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.isRoutePickerButtonBordered = false
        view.setRoutePickerButtonColor(.white, for: .normal)
        view.setRoutePickerButtonColor(.white, for: .active)
        return view
    }
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
#else
private struct _AirPlayRoutePickerView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.delegate = context.coordinator
        view.tintColor = .white
        view.activeTintColor = .systemBlue
        view.backgroundColor = .clear
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = .white
        uiView.activeTintColor = .systemBlue
        uiView.prioritizesVideoDevices = false
    }

    final class Coordinator: NSObject, AVRoutePickerViewDelegate {
    }
}
#endif
