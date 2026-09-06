//
//  TimerVolumeView.swift
//  Tally
//
//  Created by George Clinkscales on 9/4/26.
//

#if os(visionOS)
import SwiftUI
import RealityKit

private extension MeshResource {
    // RealityKit has no built-in torus generator, so we build it from scratch.
    static func generateTorus(meanRadius: Float, tubeRadius: Float,
                              ringSegments: Int = 48, tubeSegments: Int = 12) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        for i in 0...ringSegments {
            let theta = Float(i) / Float(ringSegments) * 2 * .pi
            let ct = cos(theta), st = sin(theta)
            for j in 0...tubeSegments {
                let phi = Float(j) / Float(tubeSegments) * 2 * .pi
                let cp = cos(phi), sp = sin(phi)
                positions.append(SIMD3((meanRadius + tubeRadius * cp) * ct,
                                       tubeRadius * sp,
                                       (meanRadius + tubeRadius * cp) * st))
                normals.append(SIMD3(cp * ct, sp, cp * st))
                uvs.append(SIMD2(Float(i) / Float(ringSegments),
                                 Float(j) / Float(tubeSegments)))
            }
        }

        let stride = tubeSegments + 1
        for i in 0..<ringSegments {
            for j in 0..<tubeSegments {
                let a = UInt32(i * stride + j)
                let b = UInt32((i + 1) * stride + j)
                let c = UInt32((i + 1) * stride + j + 1)
                let d = UInt32(i * stride + j + 1)
                indices += [a, b, d, b, c, d]
            }
        }

        var descriptor = MeshDescriptor(name: "torus")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(uvs)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }
}

struct TimerVolumeView: View {
    @Environment(TimerViewModel.self) var timerViewModel
    @Environment(TallyStore.self) var tallyStore

    @State private var orb: ModelEntity?
    @State private var ringContainer: Entity?
    @State private var spatialAudio = TimerSpatialAudio()

    var formattedElapsed: String {
        let total = Int(timerViewModel.elapsedSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        TimelineView(.animation) { context in
            // Named params (not trailing closures) so TimelineView can infer Content
            RealityView(
                make: { content in
                    var orbMat = PhysicallyBasedMaterial()
                    orbMat.baseColor = .init(tint: UIColor(red: 0.2, green: 0.45, blue: 1.0, alpha: 1.0))
                    orbMat.emissiveColor = .init(color: UIColor(red: 0.25, green: 0.4, blue: 1.0, alpha: 1.0))
                    orbMat.emissiveIntensity = 1.5
                    orbMat.roughness = 0.15
                    orbMat.metallic = 0.65

                    let orbEntity = ModelEntity(
                        mesh: .generateSphere(radius: 0.08),
                        materials: [orbMat]
                    )
                    content.add(orbEntity)
                    orb = orbEntity

                    // Spinning container + tilted ring child
                    let container = Entity()

                    var ringMat = PhysicallyBasedMaterial()
                    ringMat.baseColor = .init(tint: UIColor(red: 0.45, green: 0.3, blue: 1.0, alpha: 1.0))
                    ringMat.emissiveColor = .init(color: UIColor(red: 0.45, green: 0.3, blue: 1.0, alpha: 1.0))
                    ringMat.emissiveIntensity = 2.5
                    ringMat.roughness = 0.08
                    ringMat.metallic = 0.95

                    guard let torusMesh = try? MeshResource.generateTorus(meanRadius: 0.13, tubeRadius: 0.006) else { return }
                    let ringEntity = ModelEntity(
                        mesh: torusMesh,
                        materials: [ringMat]
                    )
                    // Tilt ~30° from horizontal like Saturn's rings
                    ringEntity.transform.rotation = simd_quatf(angle: .pi / 6, axis: [1, 0, 0])
                    container.addChild(ringEntity)
                    content.add(container)
                    ringContainer = container
                },
                update: { _ in
                    let elapsed = Float(context.date.timeIntervalSince1970)
                    let running = timerViewModel.isRunning

                    // Update orb glow + breathing pulse
                    if let orbEntity = orb {
                        var mat = PhysicallyBasedMaterial()
                        if running {
                            mat.baseColor = .init(tint: UIColor(red: 0.2, green: 0.45, blue: 1.0, alpha: 1.0))
                            mat.emissiveColor = .init(color: UIColor(red: 0.25, green: 0.4, blue: 1.0, alpha: 1.0))
                            mat.emissiveIntensity = 1.5
                            mat.roughness = 0.15
                            mat.metallic = 0.65
                            let pulse: Float = 1.0 + 0.04 * sin(elapsed * 2.5)
                            orbEntity.scale = SIMD3(repeating: pulse)
                        } else {
                            mat.baseColor = .init(tint: UIColor(red: 0.3, green: 0.3, blue: 0.45, alpha: 1.0))
                            mat.emissiveColor = .init(color: UIColor(red: 0.3, green: 0.3, blue: 0.45, alpha: 1.0))
                            mat.emissiveIntensity = 0.25
                            mat.roughness = 0.35
                            mat.metallic = 0.4
                            orbEntity.scale = SIMD3(repeating: 1.0)
                        }
                        orbEntity.model?.materials = [mat]
                    }

                    // Spin ring container; hide when idle
                    if let container = ringContainer {
                        container.isEnabled = running
                        if running {
                            container.transform.rotation = simd_quatf(
                                angle: elapsed * 0.5,
                                axis: [0, 1, 0]
                            )
                        }
                    }
                }
            )
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                if timerViewModel.isRunning {
                    Text(timerViewModel.activeClient)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedElapsed)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)

                    HStack(spacing: 12) {
                        Button {
                            if timerViewModel.isPaused {
                                timerViewModel.resume()
                            } else {
                                timerViewModel.pause()
                            }
                        } label: {
                            Image(systemName: timerViewModel.isPaused ? "play.fill" : "pause.fill")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            let client = timerViewModel.activeClient
                            let hours = timerViewModel.stop()
                            Task {
                                await tallyStore.addSession(client: client, hours: hours, taskNote: nil)
                            }
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                } else {
                    Text("No active timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 14)
        }
        .onAppear {
            if timerViewModel.isRunning && !timerViewModel.isPaused {
                spatialAudio.startHum()
            }
        }
        .onDisappear {
            spatialAudio.tearDown()
        }
        .onChange(of: timerViewModel.isRunning) { _, running in
            if running && !timerViewModel.isPaused {
                spatialAudio.startHum()
            } else {
                spatialAudio.stopHum()
            }
        }
        .onChange(of: timerViewModel.isPaused) { _, paused in
            if paused {
                spatialAudio.stopHum()
            } else if timerViewModel.isRunning {
                spatialAudio.startHum()
            }
        }
    }
}
#endif
