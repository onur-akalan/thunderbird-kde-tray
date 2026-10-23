// Thunderbird ana penceresi küçültülünce görev çubuğundan gizle, geri açılınca göster.
// "Minimize on Close" eklentisi X'e basınca pencereyi küçültüyor; pencere tepsiden
// (~/.local/bin/thunderbird-tray) açılıyor. Yazma pencereleri ("... - Thunderbird") etkilenmez.

function isMain(w) {
    return w.resourceClass.toLowerCase().includes("thunderbird") && w.normalWindow
        && w.caption.endsWith("Mozilla Thunderbird");
}

const asked = new Set();  // TakeStartHidden sorulmuş pencereler

function sync(w) {
    if (!isMain(w)) {
        return;
    }
    w.skipTaskbar = w.minimized;
    // Oturum açılışında tepsi Thunderbird'ü başlattıysa pencereyi gizli aç.
    // Başlık pencere açıldıktan biraz sonra geldiği için burada soruluyor.
    if (!asked.has(w.internalId.toString())) {
        asked.add(w.internalId.toString());
        callDBus("org.onur.ThunderbirdTray", "/ThunderbirdTray", "org.onur.ThunderbirdTray",
                 "TakeStartHidden", hidden => { if (hidden) w.minimized = true; });
    }
}

function setup(w) {
    if (!w.resourceClass.toLowerCase().includes("thunderbird")) {
        return;
    }
    w.minimizedChanged.connect(() => sync(w));
    w.captionChanged.connect(() => sync(w));
    w.closed.connect(() => asked.delete(w.internalId.toString()));
    sync(w);
}

workspace.windowList().forEach(setup);
workspace.windowAdded.connect(setup);
