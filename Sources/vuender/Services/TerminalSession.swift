import Foundation
import Dispatch
import Darwin

/// Простая сессия псевдотерминала для встраиваемого zsh.
final class TerminalSession: ObservableObject, @unchecked Sendable {
    @Published private(set) var output: String = ""
    @Published private(set) var isRunning: Bool = false

    private var masterFD: Int32 = -1
    private var readSource: DispatchSourceRead?
    private var process: Process?
    private var slaveHandle: FileHandle?

    private let queue = DispatchQueue(label: "vuender.terminal.read")
    private let outputLimit = 100_000

    func start(shell: String = "/bin/zsh", arguments: [String] = ["-l"]) {
        stop()

        masterFD = posix_openpt(O_RDWR | O_NOCTTY)
        guard masterFD >= 0 else { return }
        guard grantpt(masterFD) == 0, unlockpt(masterFD) == 0, let namePtr = ptsname(masterFD) else {
            stop()
            return
        }

        let slavePath = String(cString: namePtr)
        let slaveFD = open(slavePath, O_RDWR)
        guard slaveFD >= 0 else {
            stop()
            return
        }

        slaveHandle = FileHandle(fileDescriptor: slaveFD, closeOnDealloc: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = arguments
        process.standardInput = slaveHandle
        process.standardOutput = slaveHandle
        process.standardError = slaveHandle
        process.environment = ProcessInfo.processInfo.environment

        do {
            try process.run()
            self.process = process
            isRunning = true
            beginReading()
            process.terminationHandler = { @Sendable [weak self] _ in
                DispatchQueue.main.async {
                    self?.isRunning = false
                }
            }
        } catch {
            stop()
        }
    }

    func send(_ text: String) {
        guard masterFD >= 0 else { return }
        let message = text.hasSuffix("\n") ? text : text + "\n"
        message.withCString { ptr in
            _ = write(masterFD, ptr, strlen(ptr))
        }
    }

    func clear() {
        output = ""
    }

    func stop() {
        readSource?.cancel()
        readSource = nil

        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }

        process?.terminate()
        process = nil
        slaveHandle = nil
        isRunning = false
    }

    private func beginReading() {
        guard masterFD >= 0 else { return }

        let source = DispatchSource.makeReadSource(fileDescriptor: masterFD, queue: queue)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            var buffer = [UInt8](repeating: 0, count: 4096)
            let count = read(self.masterFD, &buffer, buffer.count)

            if count > 0 {
                let text = String(decoding: buffer[0..<count], as: UTF8.self)
                DispatchQueue.main.async {
                    self.appendOutput(text)
                }
            } else {
                self.stop()
            }
        }

        source.setCancelHandler { [weak self] in
            guard let fd = self?.masterFD, fd >= 0 else { return }
            close(fd)
        }

        readSource = source
        source.resume()
    }

    private func appendOutput(_ text: String) {
        output += text
        if output.count > outputLimit {
            output.removeFirst(output.count - outputLimit)
        }
    }

    deinit {
        stop()
    }
}

