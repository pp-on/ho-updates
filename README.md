# ho-updates

**ho-updates** ist eine Sammlung von Bash-Skripten zur automatisierten Verwaltung von WordPress-Installationen – lokal, mit DDEV oder auf einem Webserver. Die Skripte unterstützen Installation, Updates, Plugin-Verwaltung, Debugging und mehr.

---

## 📁 Projektstruktur

```
ho-updates/
├── webwerk                  # Hauptskript zum Ausführen von Befehlen
├── install-webwerk.sh      # Setup-Skript zur globalen Installation von 'webwerk'
├── README.md               # Diese Anleitung
└── scripts/
    ├── install/
    │   ├── wplocalinstall.sh
    │   ├── wpfunctionsinstall.sh
    ├── update/
    │   └── wpupdate.sh
    ├── mod/
    │   └── wpmod.sh
    └── utils/
        └── wphelpfunctions.sh
```

---

## ⚙️ Installation

1. Repo clonen
   ```bash
   git clone 
   cd ho-updates
   ```

2. **Setup-Skript ausführen**:
   ```bash
   ./install-webwerk.sh
   ```

   Danach ist `webwerk` systemweit verfügbar.

---

## 🚀 Nutzung

Verwende das Kommando `webwerk` mit folgenden Optionen:

| Befehl             | Beschreibung                                      |
|--------------------|---------------------------------------------------|
| `webwerk install`  | Installiert WordPress im aktuellen Verzeichnis    |
| `webwerk update`   | Führt Updates für Core & Plugins durch            |
| `webwerk mod`      | Wartung: Plugins kopieren, Benutzer anlegen etc. |
| `webwerk debug`    | Aktiviert Debug-Modus in der Installation         |

---

## 🧩 Voraussetzungen

- Bash
- WP-CLI
- MySQL/MariaDB
- Git
- Optional: DDEV für containerisierte Entwicklung

---

## 📝 Hinweise

- Die Skripte sind modular aufgebaut und nutzen `wphelpfunctions.sh` als gemeinsame Funktionsbibliothek.
- Die Verzeichnisnamen werden zur automatischen Generierung von Datenbanknamen und URLs verwendet.
- Für DDEV wird automatisch die passende Konfiguration erstellt.

---

## 📬 Kontakt

Für Fragen oder Erweiterungen: oswaldo.nickel@pfennigparade.de
```
