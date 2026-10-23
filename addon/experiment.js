// Window locking: from rsjtdrjgfuzkfg's "Minimize on Close" add-on (MPL 2.0).
// writeUnread: writes the unseen new mail count to the file watched by the tray script.
const { ExtensionCommon } = ChromeUtils.importESModule(
    "resource://gre/modules/ExtensionCommon.sys.mjs");

this.trayhelper = class extends ExtensionCommon.ExtensionAPI {
  getAPI(context) {
    const extension = context.extension;

    let listeners = []; // onClosing listeners

    // Called when a locked window would close
    const onClosing = function(window) {
      for (let listener of listeners) {
        listener.async(extension.windowManager.getWrapper(window).id);
      }
    };

    const closeEventHandler = function(event) {
      event.preventDefault();
      onClosing(event.target);
    };

    // Redirects the close event (normal case) and window.close (X when tabs are in the title bar)
    const lockWindow = function(window) {
      window.addEventListener("close", closeEventHandler, false);
      window.__tray__originalClose = window.close;
      window.close = function() {
        onClosing(this);
      };
    };

    const unlockWindow = function(window) {
      window.removeEventListener("close", closeEventHandler, false);
      window.close = window.__tray__originalClose;
      delete window.__tray__originalClose;
    };

    let lockedWindows = [];

    context.callOnClose({
      close() {
        for (let window of lockedWindows) {
          unlockWindow(window);
        }
        lockedWindows = [];
      }
    });

    const runtimeDir = Services.env.get("XDG_RUNTIME_DIR") || PathUtils.tempDir;
    const dir = PathUtils.join(runtimeDir, "thunderbird-tray");
    const file = PathUtils.join(dir, "unread");

    return {
      trayhelper: {
        lockWindow(windowId) {
          const window = extension.windowManager.get(windowId, context).window;
          lockWindow(window);
          lockedWindows.push(window);
        },

        unlockWindow(windowId) {
          const window = extension.windowManager.get(windowId, context).window;
          const index = lockedWindows.indexOf(window);
          if (index >= 0) {
            unlockWindow(window);
            lockedWindows.splice(index, 1);
          }
        },

        async writeUnread(count) {
          await IOUtils.makeDirectory(dir, { ignoreExisting: true });
          await IOUtils.writeUTF8(file, String(count), { tmpPath: file + ".tmp" });
        },

        onClosing: new ExtensionCommon.EventManager({
          context,
          name: "trayhelper.onClosing",
          register(fire) {
            listeners.push(fire);
            return function() {
              const index = listeners.indexOf(fire);
              if (index >= 0) {
                listeners.splice(index, 1);
              }
            };
          }
        }).api()
      }
    };
  }
};
