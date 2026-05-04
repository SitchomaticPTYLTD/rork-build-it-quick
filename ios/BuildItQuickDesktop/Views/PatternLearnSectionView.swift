import SwiftUI

struct PatternLearnSectionView: View {
    @Bindable var viewModel: AITextMorphViewModel
    let onShowLibrary: () -> Void
    let onShowSave: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            heroCard
            examplesCard
            confidenceCard
            applyCard
            resultCard
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.linearGradient(colors: [.purple, .indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pattern Learn")
                        .font(.title3.weight(.bold))
                    Text("Show 2–3 before → after examples. The AI infers the rule, then transforms bulk text the same way.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button(action: onShowLibrary) {
                    Label("Library", systemImage: "books.vertical.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.indigo.opacity(0.12), in: .capsule)
                        .foregroundStyle(.indigo)
                }
                .buttonStyle(.plain)
                if !viewModel.savedPatterns.isEmpty {
                    Text("\(viewModel.savedPatterns.count) saved")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
    }

    // MARK: - Examples card

    private var examplesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Examples", systemImage: "rectangle.on.rectangle.angled")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.usableExamplesCount) usable")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            PatternTemplatePickerView(templates: PatternTemplate.library) { template in
                withAnimation(.spring(duration: 0.45, bounce: 0.18)) {
                    viewModel.applyTemplate(template)
                }
            }

            VStack(spacing: 12) {
                ForEach(Array(viewModel.examples.enumerated()), id: \.element.id) { index, _ in
                    PatternExampleCardView(
                        index: index + 1,
                        pair: pairBinding(at: index),
                        canRemove: viewModel.examples.count > 1,
                        onRemove: {
                            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                                viewModel.removeExample(viewModel.examples[index])
                            }
                        },
                        onDuplicate: {
                            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                                viewModel.duplicateExample(viewModel.examples[index])
                            }
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.22)) {
                        viewModel.addExamplePair()
                    }
                } label: {
                    Label("Add Example", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [6, 4]))
                                .foregroundStyle(.indigo.opacity(0.6))
                        )
                        .foregroundStyle(.indigo)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.18)) {
                        viewModel.clearExamples()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 46, height: 46)
                        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset examples")
            }
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
    }

    // MARK: - Confidence card

    private var confidenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Pattern Insight", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                if viewModel.learnedPattern != nil {
                    Button {
                        onShowSave()
                    } label: {
                        Label("Save", systemImage: "bookmark.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.indigo)
                }
            }

            if let pattern = viewModel.learnedPattern {
                HStack(alignment: .top, spacing: 16) {
                    PatternConfidenceRingView(confidence: pattern.confidence)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(confidenceHeadline(pattern.confidence))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(confidenceColor(pattern.confidence))
                        Text(pattern.rule)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if pattern.confidence < 70 {
                    Label("Add 1–2 more examples for a stronger rule.", systemImage: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.12), in: .rect(cornerRadius: 12))
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                    Text("Tap Analyze and I'll explain the pattern I see.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Refine (optional)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.refinement)
                        .font(.callout)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 56, maxHeight: 110)
                        .padding(10)
                        .background(Color(.tertiarySystemBackground), in: .rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                        }
                    if viewModel.refinement.isEmpty {
                        Text("e.g. \"treat the email as the key\"")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
            }

            if let error = viewModel.analyzeError {
                MorphErrorBannerView(message: error) {
                    Task { await viewModel.analyzeExamples() }
                }
            }

            Button {
                Task { await viewModel.analyzeExamples() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isAnalyzing {
                        ProgressView().tint(.white)
                        Text("Analyzing…")
                    } else {
                        Image(systemName: "wand.and.stars.inverse")
                        Text(viewModel.learnedPattern == nil ? "ANALYZE PATTERN" : "RE-ANALYZE")
                    }
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.linearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing), in: .rect(cornerRadius: 16))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canAnalyze)
            .opacity(viewModel.canAnalyze ? 1 : 0.5)
            .sensoryFeedback(.success, trigger: viewModel.learnedPattern?.confidence)
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
        .animation(.spring(duration: 0.45, bounce: 0.18), value: viewModel.learnedPattern)
    }

    // MARK: - Apply card

    private var applyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Apply to Bulk Data", systemImage: "square.stack.3d.up.fill")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.bulkInputLineCount) lines")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.bulkInput)
                    .font(.callout.monospaced())
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180, maxHeight: 280)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                    }
                if viewModel.bulkInput.isEmpty {
                    Text("Paste hundreds or thousands of lines here…")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            if viewModel.isApplying && viewModel.applyProgressTotal > 0 {
                BatchProgressView(
                    current: viewModel.applyProgressCurrent,
                    total: viewModel.applyProgressTotal,
                    fraction: viewModel.applyProgressFraction
                )
            }

            if let error = viewModel.applyError {
                MorphErrorBannerView(message: error) {
                    viewModel.applyPattern()
                }
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.applyPattern()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isApplying {
                            ProgressView().tint(.white)
                            Text("\(viewModel.applyProgressCurrent)/\(viewModel.applyProgressTotal)")
                                .font(.headline.monospacedDigit())
                        } else {
                            Image(systemName: "bolt.fill")
                            Text("APPLY PATTERN")
                                .font(.headline.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary, in: .rect(cornerRadius: 16))
                    .foregroundStyle(Color(.systemBackground))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canApplyPattern && !viewModel.isApplying)
                .opacity((viewModel.canApplyPattern || viewModel.isApplying) ? 1 : 0.5)

                if viewModel.isApplying {
                    Button {
                        viewModel.cancelApply()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title3.weight(.bold))
                            .frame(width: 56, height: 56)
                            .background(Color.red.opacity(0.15), in: .rect(cornerRadius: 16))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        viewModel.clearBulk()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.title3.weight(.bold))
                            .frame(width: 56, height: 56)
                            .background(Color.red.opacity(0.12), in: .rect(cornerRadius: 16))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.learnedPattern == nil {
                Label("Analyze a pattern first to enable Apply.", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
    }

    // MARK: - Result card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Result", systemImage: "doc.text.fill")
                    .font(.headline)
                Spacer()
                if !viewModel.bulkOutput.isEmpty {
                    Button {
                        viewModel.copyBulkOutput()
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if !viewModel.bulkOutput.isEmpty {
                HStack(spacing: 10) {
                    statPill(label: "IN", value: viewModel.bulkInputLineCount, color: .indigo)
                    statPill(label: "OUT", value: viewModel.bulkOutputLineCount, color: .green)
                    statPill(
                        label: "Δ",
                        value: viewModel.bulkOutputLineCount - viewModel.bulkInputLineCount,
                        color: .orange,
                        showsSign: true
                    )
                    Spacer(minLength: 0)
                }

                ScrollView {
                    Text(viewModel.bulkOutput)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .frame(maxHeight: 360)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                MorphEmptyStateView(
                    title: "No transformation yet",
                    systemImage: "rectangle.and.text.magnifyingglass",
                    message: "Teach the AI a pattern, paste bulk data, and tap Apply to see the result here."
                )
            }
        }
        .padding(18)
        .morphGlassSurface(cornerRadius: 24)
        .animation(.spring(duration: 0.4, bounce: 0.18), value: viewModel.bulkOutput)
    }

    // MARK: - Helpers

    private func statPill(label: String, value: Int, color: Color, showsSign: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(showsSign && value > 0 ? "+\(value)" : "\(value)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: .capsule)
    }

    private func confidenceHeadline(_ confidence: Int) -> String {
        switch confidence {
        case 90...: "High confidence"
        case 70..<90: "Solid pattern"
        case 40..<70: "Possible pattern"
        default: "Low confidence"
        }
    }

    private func confidenceColor(_ confidence: Int) -> Color {
        switch confidence {
        case 0..<40: .red
        case 40..<70: .orange
        default: .green
        }
    }

    private func pairBinding(at index: Int) -> Binding<ExamplePair> {
        Binding(
            get: {
                guard viewModel.examples.indices.contains(index) else { return ExamplePair() }
                return viewModel.examples[index]
            },
            set: { newValue in
                guard viewModel.examples.indices.contains(index) else { return }
                viewModel.examples[index] = newValue
            }
        )
    }
}
