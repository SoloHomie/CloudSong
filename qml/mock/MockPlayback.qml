import QtQuick
pragma Singleton

// ═══════════════════════════════════════════════════════════════
//  MockPlayback — 模拟播放服务
//
//  属性/方法名与将来 C++ PlaybackService 保持同名同义;
//  C++ 服务落地后删除本文件, 注入点 (main.qml / PlayerBar /
//  QueueDrawer / 各页的 MockPlayback.xxx 调用) 整体替换即可。
//  本文件只做状态与假计时, 不发声、不加载音频。
// ═══════════════════════════════════════════════════════════════
QtObject {
    id: root

    // ── 播放状态 ──
    property bool   playing: false
    property int    position: 0      // ms
    property int    duration: 0      // ms
    property int    currentIndex: -1
    property string title: ""
    property string artist: ""
    property string album: ""
    property int    seed: 0          // 封面占位色
    property string platform: ""
    property int    loopMode: 0      // 0=列表循环 1=单曲循环 2=随机
    property real   rate: 1.0
    property real   volume: 0.7
    property real   _preMute: 0.7   // 静音前音量 (toggleMute 恢复用)
    property bool   favorite: false
    property bool   desktopLyric: false
    property string quality: "标准品质"

    // 播放队列 (与 QueueDrawer 共用)
    property ListModel queue: ListModel {}

    // ── 操作 (方法名即 C++ 服务接口) ──
    function loadQueue(songs) {
        queue.clear()
        if (!songs || songs.length === 0) return
        for (var i = 0; i < songs.length; i++) queue.append(songs[i])
        playIndex(0)
    }
    function playIndex(i) {
        if (i < 0 || i >= queue.count) return
        currentIndex = i
        var it = queue.get(i)
        title = it.title || ""
        artist = it.artist || ""
        album = it.album || ""
        seed = it.seed !== undefined ? it.seed : 0
        platform = it.platform || ""
        duration = it.duration || 180000
        position = 0
        favorite = it.liked === true
        playing = true
    }
    function playPause() {
        if (queue.count === 0) return
        playing = !playing
    }
    function next() {
        if (queue.count === 0) return
        if (loopMode === 2) { playIndex(Math.floor(Math.random() * queue.count)); return }
        playIndex((currentIndex + 1) % queue.count)
    }
    function prev() {
        if (queue.count === 0) return
        if (position > 3000) { position = 0; return }   // 播放中回退=重头
        playIndex((currentIndex - 1 + queue.count) % queue.count)
    }
    function seek(ms) { position = Math.max(0, Math.min(duration, ms)) }
    function toggleLoop() { loopMode = (loopMode + 1) % 3 }
    function setRate(r) { rate = r }
    function setVolume(v) { volume = Math.max(0, Math.min(1, v)) }
    function toggleMute() {   // 静音/恢复 (接口名与 C++ PlaybackService 对齐)
        if (volume > 0) { _preMute = volume; volume = 0 }
        else volume = _preMute
    }
    function toggleFavorite() {
        favorite = !favorite
        if (currentIndex >= 0) queue.setProperty(currentIndex, "liked", favorite)
    }
    function removeFromQueue(i) {
        if (i < 0 || i >= queue.count) return
        queue.remove(i)
        if (queue.count === 0) { currentIndex = -1; playing = false; return }
        if (i === currentIndex) playIndex(Math.min(i, queue.count - 1))
        else if (i < currentIndex) currentIndex--
    }
    function clearQueue() {
        queue.clear()
        currentIndex = -1
        playing = false
    }

    // ── 假计时 (250ms 步进; 手动节流, 不用连续动画) ──
    // 属性形式声明: QtObject 子项无默认属性, 直接声明 Timer 子项有加载风险
    property Timer ticker: Timer {
        interval: 250
        repeat: true
        running: root.playing && root.duration > 0
        onTriggered: {
            root.position += 250
            if (root.position >= root.duration) {
                if (root.loopMode === 1) root.position = 0
                else root.next()
            }
        }
    }
}
