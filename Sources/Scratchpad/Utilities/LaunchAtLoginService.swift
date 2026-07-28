import ServiceManagement

/// Registers Scratchpad as a login item.
protocol LaunchAtLoginService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

/// Uses `SMAppService`, the modern replacement for the deprecated
/// `SMLoginItemSetEnabled`.
final class SMAppServiceLaunchAtLoginService: LaunchAtLoginService {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
