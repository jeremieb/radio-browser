import SwiftUI
import AVKit

struct AirPlayRoutePickerView: View {
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
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = .white
        view.backgroundColor = .clear
        return view
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#endif
