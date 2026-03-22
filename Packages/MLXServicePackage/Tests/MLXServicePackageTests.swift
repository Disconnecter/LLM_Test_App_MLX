import Combine
import Foundation
import Testing
@testable import MLXServicePackage

@Suite("LLMServiceTests")
struct MLXServicePackageTests {
    @Test
    func load_success_publishesLoadingThenReady() async {
        let client = MockLLMClientService()
        let sut = makeSUT(client: client)
        let recorder = StateRecorder()
        let cancellable = sut.state.sink { state in
            recorder.append(snapshot(of: state))
        }
        defer { cancellable.cancel() }

        await sut.load()

        #expect(recorder.values == [.idle, .loadingModel, .ready])
        #expect(await client.loadCallCountValue() == 1)
    }

    @Test
    func load_failure_publishesLoadingThenLoadingFailedError() async {
        let client = MockLLMClientService(loadBehavior: .failure(.loadingFailed))
        let sut = makeSUT(client: client)
        let recorder = StateRecorder()
        let cancellable = sut.state.sink { state in
            recorder.append(snapshot(of: state))
        }
        defer { cancellable.cancel() }

        await sut.load()

        #expect(recorder.values == [.idle, .loadingModel, .error(.loadingFailed)])
        #expect(await client.loadCallCountValue() == 1)
    }

    @Test
    func unload_afterSuccessfulLoad_publishesIdleAndUnloadsClient() async {
        let client = MockLLMClientService()
        let sut = makeSUT(client: client)
        let recorder = StateRecorder()
        let cancellable = sut.state.sink { state in
            recorder.append(snapshot(of: state))
        }
        defer { cancellable.cancel() }

        await sut.load()
        await sut.unload()

        #expect(recorder.values == [.idle, .loadingModel, .ready, .idle])
        #expect(await client.unloadCallCountValue() == 1)
    }

    @Test
    func craftResponse_success_streamsChunksThenReady() async {
        let client = MockLLMClientService(responseChunks: ["Hel", "lo"])
        let sut = makeSUT(client: client)

        await sut.load()

        let recorder = StateRecorder()
        let cancellable = sut.state.sink { state in
            recorder.append(snapshot(of: state))
        }
        defer { cancellable.cancel() }

        await sut.craftResponse(for: "Hello")

        #expect(
            recorder.values == [.ready, .chunk("Hel"), .chunk("lo"), .ready]
        )
        #expect(await client.generateInputsValue() == ["Hello"])
    }
}

private extension MLXServicePackageTests {
    func makeSUT(client: MockLLMClientService) -> LLMService {
        LLMService(
            client: client,
            model: .llama3_2_3b,
            configuration: .init(systemPrompt: "Test", maxTokens: 32, temperature: 0.5)
        )
    }

    func snapshot(of state: LLMServiceState) -> RecordedServiceState {
        switch state {
        case .idle:
            .idle
        case .loadingModel:
            .loadingModel
        case .ready:
            .ready
        case .responding(.success(let chunk)):
            .chunk(chunk)
        case .responding(.failure(let error)):
            .responseFailure(error.localizedDescription)
        case .error(let error):
            .error(error)
        }
    }
}
