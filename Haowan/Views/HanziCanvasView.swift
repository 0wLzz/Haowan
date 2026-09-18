import SwiftUI
import PencilKit

/// A SwiftUI wrapper around `PKCanvasView`, adapted from Apple's "Building a
/// handwriting recognition experience with PencilKit" sample. It overlays
/// the mi-zi-ge guide grid so the canvas doubles as practice paper (the
/// "paper" from the homepage spec).
struct HanziCanvasView: View {
    var model: WritingCanvasModel
    /// Draw the built-in mi-zi-ge guide grid. Turn this off when the canvas
    /// sits on artwork that already prints its own grid (e.g. the paper card).
    var showsGuideGrid: Bool = true
    /// Show PencilKit's floating tool palette. Off gives a clean, fixed-pen
    /// writing surface for the styled task screen.
    var showsToolPicker: Bool = true

    var body: some View {
        ZStack {
            if showsGuideGrid { GridPaperView() }
            CanvasRepresentable(model: model, showsToolPicker: showsToolPicker)
        }
    }
}

private struct CanvasRepresentable: UIViewRepresentable {
    var model: WritingCanvasModel
    var showsToolPicker: Bool = true

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        canvasView.tool = PKInkingTool(.fountainPen, color: .black, width: 8)

        if showsToolPicker {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
            context.coordinator.toolPicker = toolPicker
        }

        model.canvasView = canvasView
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    @MainActor
    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let model: WritingCanvasModel
        var toolPicker: PKToolPicker?
        init(model: WritingCanvasModel) { self.model = model }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            model.handleDrawingChange()
        }
    }
}

/// Owns the live `PKCanvasView` and exposes just what the writing screen
/// needs: whether there's ink on the page, and the current drawing to grade.
@Observable
@MainActor
final class WritingCanvasModel {
    private(set) var hasStrokes = false
    @ObservationIgnored var canvasView: PKCanvasView?

    func handleDrawingChange() {
        let newValue = !(canvasView?.drawing.strokes.isEmpty ?? true)
        if hasStrokes != newValue { hasStrokes = newValue }
    }

    func clear() {
        canvasView?.drawing = PKDrawing()
        hasStrokes = false
    }

    var currentDrawing: PKDrawing {
        canvasView?.drawing ?? PKDrawing()
    }

    /// A PNG of the learner's ink, rendered over the full canvas area so the
    /// character keeps the position and proportion it was written in. Used to
    /// show "what you wrote" on the end-of-day book page.
    func drawingPNGData() -> Data? {
        guard let canvasView else { return nil }
        let bounds = canvasView.bounds
        guard bounds.width > 1, bounds.height > 1 else { return nil }
        let scale = max(canvasView.traitCollection.displayScale, 1)
        let image = canvasView.drawing.image(from: bounds, scale: scale)
        return image.pngData()
    }
}
