public let stableWinMuxAppId: String = "com.gfavaro.winmux"
public let forkRepositoryURL = "https://github.com/gfavaro/WinMuXx"
#if DEBUG
    public let winMuxAppId: String = "com.gfavaro.winmux.debug"
    public let winMuxAppName: String = "WinMux-GF-Debug"
#else
    public let winMuxAppId: String = stableWinMuxAppId
    public let winMuxAppName: String = "WinMux-GF"
#endif
