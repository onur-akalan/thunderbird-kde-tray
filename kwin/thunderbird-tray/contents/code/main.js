// Hide the Thunderbird main window from the taskbar while minimized, show it again when restored.
// The add-on minimizes the window when X is pressed; it is opened again from the tray
// (~/.local/bin/thunderbird-tray). Compose windows ("... - Thunderbird") are not affected.

function isMain(w) {
    return w.resourceClass.toLowerCase().includes("thunderbird") && w.normalWindow
        && w.caption.endsWith("Mozilla Thunderbird");
}

const asked = new Set();  // windows already asked TakeStartHidden

function sync(w) {
    if (!isMain(w)) {
        return;
    }
    w.skipTaskbar = w.minimized;
    // If the tray started Thunderbird at login, open the window hidden.
    // Asked here because the caption arrives a little after the window opens.
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
