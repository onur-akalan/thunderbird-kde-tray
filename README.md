# thunderbird-kde-tray

KDE Plasma (Wayland) için Thunderbird sistem tepsisi simgesi. Thunderbird'ün Linux sürümünde tepsiye
küçültme yok: pencere kapatılınca uygulama da kapanıyor, yeni mail bildirimleri de gelmiyor.
Bu repo X'e basınca Thunderbird'ü tepsiye gizler ve simgenin köşesinde bakılmamış yeni mail
sayısını gösterir. Birdtray'in aksine XWayland gerektirmez.

## Çözdüğü sorunlar

| Sorun | Sebep | Çözüm |
|---|---|---|
| X'e basınca Thunderbird tamamen kapanıyor, bildirim gelmiyor | Linux'ta "tepsiye küçült" yok | Eklenti pencerenin kapanmasını yakalayıp küçültür (menüden Çıkış / Ctrl+Q yine kapatır) |
| Küçültülen pencere görev çubuğunda duruyor | — | KWin betiği küçülen ana pencereyi görev çubuğundan gizler; yazma pencerelerine dokunmaz |
| Tepside simge yok | — | `thunderbird-tray`: StatusNotifierItem simgesi, sol tık aç / gizle |
| Yeni mail var mı görünmüyor | — | Simgede kırmızı rozet: 1–5, fazlası 5+ (tüm hesapların Gelen Kutusu) |
| Birdtray Wayland'de pencereyi gizleyemiyor | Wayland'de başka uygulamanın penceresi dışarıdan yönetilemiyor | Pencere işleri KWin betiğiyle yapılır; Thunderbird yerel Wayland'de kalır |
| Açılışta Thunderbird pencere olarak açılıyor | — | Oturum açılışında gizli başlar, yalnızca tepside görünür |

## Kullanım

- **Tepsi simgesine sol tık**: Thunderbird penceresini açar; açık ve öndeyse gizler.
  Thunderbird kapalıysa başlatır.
- **Sağ tık**: Thunderbird'ü göster, Yeni mesaj yaz, Thunderbird'ü tamamen kapat.
- **Pencerenin X düğmesi**: pencere gizlenir, Thunderbird çalışmaya ve bildirim göstermeye devam eder.
- **Rozet**: son baktığından beri gelen yeni mailler (Thunderbird'ün "yeni" sayısı, okunmamış sayısı
  değil). O Gelen Kutusu'na bakınca sıfırlanır. Üzerine gelince sayı yazar.

Komut satırı: `thunderbird-tray --hidden`, `thunderbird-tray --show [mailto:…|-compose]`,
`thunderbird-tray --quit`.

## Kurulum

Gereksinimler: Thunderbird 128+, KDE Plasma 6, Python 3 + PyGObject + pycairo,
`libdbusmenu-glib` (GI typelib `Dbusmenu-0.4`), `qdbus6`, `kwriteconfig6`.

```bash
# Thunderbird kapalıyken (Ctrl+Q)
./install.sh     # sudo gerekmez
./uninstall.sh   # geri alır; Thunderbird'ün hesaplarına ve ayarlarına dokunmaz
```

`install.sh` şunları kurar:

| Dosya | Ne işe yarar |
|---|---|
| `~/.local/bin/thunderbird-tray` | Tepsi simgesi (StatusNotifierItem + dbusmenu), rozet çizimi |
| `<profil>/extensions/thunderbird-tray@onur.local.xpi` | Eklenti: X'e basınca küçült + yeni mail sayısını bildir |
| `<profil>/prefs.js` → `extensions.autoDisableScopes = 14` | Profil klasörüne konan eklenti devre dışı gelmesin |
| `~/.local/share/kwin/scripts/thunderbird-tray` | Küçülen ana pencereyi görev çubuğundan gizler, gizli başlatma |
| `~/.local/share/applications/org.mozilla.Thunderbird.desktop` | Menü kısayolu `thunderbird-tray --show` ile açılır; sistemdeki kısayola dokunulmaz |
| `~/.config/autostart/thunderbird-tray.desktop` | Oturum açılışında `thunderbird-tray --hidden` |

## Nasıl çalışıyor

- **Eklenti** (`addon/`): kapatmayı engelleyen kısım, rsjtdrjgfuzkfg'in
  [Minimize on Close](https://addons.thunderbird.net/thunderbird/addon/minimize-on-close/) eklentisinden
  (MPL 2.0) alındı; o eklenti en fazla Thunderbird 153'e kurulabiliyor. Experiment API'si pencerenin
  `close` olayını ve `window.close`'u yakalar. Yeni mail sayısı `folders.getFolderInfo().newMessageCount`
  ile hesaplanıp `$XDG_RUNTIME_DIR/thunderbird-tray/unread` dosyasına yazılır.
- **Tepsi** (`thunderbird-tray`): bu dosyayı 2 sn'de bir okur, sayı varsa Thunderbird simgesine rozet çizip
  `IconPixmap` olarak verir. Pencereyi açmak / gizlemek için geçici KWin betikleri yükler
  (Wayland'de başka uygulamanın penceresini öne getirmenin yolu).
- **KWin betiği** (`kwin/`): başlığı `… - Mozilla Thunderbird` olan ana pencere küçülünce
  `skipTaskbar` açar. Pencere açılınca tepsinin `org.onur.ThunderbirdTray.TakeStartHidden` D-Bus
  yöntemini sorar; `--hidden` başlangıcında pencereyi hemen küçültür.

## Notlar

- Eklenti imzasız ve experiment API kullanıyor; Thunderbird ikisine de izin veriyor
  (`extensions.experiments.suppressed = false`). İleride bir Thunderbird güncellemesi experiment'leri
  kapatırsa X yine uygulamayı kapatır ve rozet görünmez.
- Filtrelerle başka klasöre taşınan mailler rozete sayılmaz; yalnızca Gelen Kutuları.
- Thunderbird 158, KDE Plasma 6 Wayland (Arch) üzerinde denendi.

## Lisans

MPL 2.0 (eklenti kodu Minimize on Close'tan türetildiği için repo da aynı lisansla).
