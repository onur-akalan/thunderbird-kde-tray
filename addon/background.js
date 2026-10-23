// --- X'e basınca küçült ("Minimize on Close", MPL 2.0) ---
(async function() {
  let mainWindows = []; // açık ana pencerelerin id'leri

  // Ana pencere kapanmaya çalışınca: son pencereyse ve küçük değilse küçült
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

// --- Bakılmamış yeni mail sayısı (tüm hesapların Gelen Kutusu) ---
// Okunmamış sayısı değil: Thunderbird'ün "yeni" sayısı, klasöre bakınca sıfırlanır
(function() {
  let inboxes = null; // folder id'leri; hesap/klasör değişince yeniden bulunur
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
      inboxes = null; // klasör silinmiş olabilir; sonraki turda yeniden bul
    }
  };

  // Kısa sürede gelen çok sayıda değişikliği tek güncellemede topla
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
  setInterval(update, 15000); // olay kaçarsa yedek
  update();
})();
