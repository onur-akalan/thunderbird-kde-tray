// --- Minimize instead of closing on X ("Minimize on Close", MPL 2.0) ---
(async function() {
  let mainWindows = []; // ids of open main windows

  // When a main window tries to close: minimize it if it is the last one and not minimized
  const windowClosingCallback = async function(windowId) {
    let index = mainWindows.indexOf(windowId);
    if (index >= 0) {
      if (mainWindows.length <= 1 &&
          (await messenger.windows.get(windowId)).state != "minimized") {
        await messenger.windows.update(windowId, { "state": "minimized" });
        return;
      }
      mainWindows.splice(index, 1);
    }
    await messenger.trayhelper.unlockWindow(windowId);
    await messenger.windows.remove(windowId);
  };
  await messenger.trayhelper.onClosing.addListener(windowClosingCallback);

  const windowRegistrationListener = async function(windowInfo) {
    if (windowInfo.id && windowInfo.type === "normal") {
      mainWindows.push(windowInfo.id);
      await messenger.trayhelper.lockWindow(windowInfo.id);
    }
  };
  await messenger.windows.onCreated.addListener(windowRegistrationListener);
  for (let windowInfo of await messenger.windows.getAll()) {
    await windowRegistrationListener(windowInfo);
  }
})().catch(console.error);

// --- Unseen new mail count (inboxes of all accounts) ---
// Not the unread count: Thunderbird's "new" count, reset when the folder is viewed
(function() {
  let inboxes = null; // folder ids; looked up again when accounts / folders change
  let timer = null;
  let last = -1;

  const findInboxes = async function() {
    const ids = [];
    const walk = function(folders) {
      for (const f of folders || []) {
        if ((f.specialUse || []).includes("inbox")) {
          ids.push(f.id);
        }
        walk(f.subFolders);
      }
    };
    for (const account of await messenger.accounts.list(true)) {
      walk(account.rootFolder ? [account.rootFolder] : account.folders);
    }
    return ids;
  };

  const update = async function() {
    try {
      if (!inboxes) {
        inboxes = await findInboxes();
      }
      let count = 0;
      for (const id of inboxes) {
        count += (await messenger.folders.getFolderInfo(id)).newMessageCount || 0;
      }
      if (count !== last) {
        last = count;
        await messenger.trayhelper.writeUnread(count);
      }
    } catch (e) {
      console.error(e);
      inboxes = null; // the folder may have been deleted; look up again next time
    }
  };

  // Collapse bursts of changes into one update
  const schedule = function() {
    clearTimeout(timer);
    timer = setTimeout(update, 300);
  };

  messenger.folders.onFolderInfoChanged.addListener(schedule);
  const reset = function() { inboxes = null; schedule(); };
  messenger.folders.onCreated.addListener(reset);
  messenger.folders.onDeleted.addListener(reset);
  messenger.folders.onRenamed.addListener(reset);
  messenger.accounts.onCreated?.addListener(reset);
  messenger.accounts.onDeleted?.addListener(reset);
  setInterval(update, 15000); // fallback for missed events
  update();
})();
