# PublicGuard

## Kort vurdering

Ideen er god, men den skal vinkles rigtigt.

Som ren "MacBook-tyverialarm" er den nok ikke i sig selv et stærkt match til OpenAI Codex for OSS. OpenAI kigger især efter aktive open source-projekter med meningsfuld brug, bred adoption eller klar betydning for softwareøkosystemet, samt aktiv vedligeholdelse som PR-review, issue-triage og releases.

Hvis projektet derimod bygges som et open source macOS security/privacy utility for developers, students and creators working in public, bliver det meget mere seriøst.

## Koncept

PublicGuard er en open-source macOS menu bar app, der hjælper udviklere, studerende og creators med at beskytte deres laptop, når de arbejder i offentlige rum.

Appen reagerer på mistænkelige fysiske events som:

- Sleep/wake-events
- Frakobling af oplader
- Bluetooth-afstand fra telefon
- Netværks- eller lokationsændringer

Det er langt stærkere end bare "alarm når skærmen klappes i".

## Navneforslag

- PublicGuard
- CaféLock
- OpenSeat
- AwayGuard
- MacSentry
- BuildInPublic Guard

Favoritten er **PublicGuard**, fordi det lyder seriøst, OSS-agtigt og ikke gimmicky.

## Kort Pitch

PublicGuard is an open-source macOS menu bar app that helps developers, students, and creators protect their laptop when working in public spaces. It triggers loud alarms and optional lock/security workflows when suspicious physical events occur, such as charger disconnect, wake while armed, Bluetooth distance from phone, or network/location changes.

## Stærk README-positionering

README'en skal sælge projektet som:

> An open-source macOS menu bar security app for people who build in public.

Og som:

> For developers, students, founders, designers, and open-source maintainers working from cafés, libraries, universities, coworking spaces, and public areas.

## Endelig App-Idé

**PublicGuard** - an open-source macOS menu bar security app for people who build in public.

Core:

> Arm your Mac before stepping away.
> If someone unplugs the charger, wakes it while armed, changes networks, or moves it away from your phone, PublicGuard reacts with alarms, lock actions, and local security logs.

## MVP

Start simpelt.

### Version 0.1

- macOS menu bar app
- "Arm / Disarm" knap
- Meget høj alarmlyd
- Log sleep and respond when Mac wakes while armed
- Alarm hvis oplader fjernes
- Alarm hvis Mac vågner fra sleep mens appen er armed
- Kræv password/Touch ID for at disarme
- Log over events:
  - Armed time
  - Sleep/wake while armed
  - Charger removed
  - Alarm triggered
  - Alarm stopped

Det er realistisk hurtigt og kan stadig virke professionelt.

## MVP Feature-List til GitHub

- Menu bar Arm/Disarm
- Loud alarm when Mac wakes while armed
- Alarm when charger disconnects
- Lock screen action
- Grace period before alarm
- Touch ID/password protected disarm
- Local-only event log
- Privacy-first: no cloud account, no tracking
- Open trigger/action plugin architecture

## Aktuel Implementeringsstatus

Projektet er startet som en native Swift/AppKit macOS menu bar-app via Swift Package Manager.

Implementeret:

- Swift Package scaffold
- README
- MIT License
- CONTRIBUTING.md
- SECURITY.md
- CHANGELOG.md
- docs/development.md
- docs/roadmap.md
- GitHub Actions CI workflow
- GitHub issue templates
- Pull request template
- Local unsigned `.app` bundle build script
- Menu bar status item
- Arm/Disarm flow
- Touch ID/password-beskyttet disarm via LocalAuthentication
- Lokal event-log i Application Support
- Recent Events preview i menu bar
- Event log open/clear actions
- Charger disconnect trigger via IOKit power polling
- Wi-Fi network change trigger via CoreWLAN polling
- Sleep/wake trigger via NSWorkspace notifications
- Konfigurerbar grace period før respons
- Loud alarm og silent response modes
- Configurable alarm sound setting med bundled local choices og Apple Alarm som default
- Per-trigger enable/disable settings
- Notification enable/disable setting
- Lock screen enable/disable setting
- Manual response test fra menu bar
- Looping alarmlyd via bundled MP3/WAV eller gentagne macOS system sounds
- Authenticated alarm stop med lokal `alarm_stopped` audit logging
- Lokal macOS-notifikation ved alarm
- Optional lock screen action via CGSession
- Lokal app bundle build via `scripts/build_app.sh`
- `swift build` verifieret
- Unit tests for guard state og event logging
- Unit tests for network change event logging
- Unit tests for trigger settings persistence and ignored trigger logging
- Unit tests for notification setting persistence
- Unit tests for lock screen setting persistence
- Unit tests for event log clearing
- Unit tests for recent event log previews
- Unit tests for settings persistence
- Unit tests for alarm sound setting persistence and bundled resource metadata
- Unit tests for alarm stop state and event logging
- `swift test` verifieret med 24 passing tests
- Smoke-testet executable launch; app skriver `app_started` til lokal event-log

Kendt MVP-begrænsning:

- Direkte alarm mens låget er lukket kan ikke pålideligt køre, fordi Mac'en typisk går i sleep. Første native version logger sleep og reagerer på wake while armed. Lid-close-detektion skal senere forbedres med mere specifik power/sleep-state håndtering.

## Features der Gør Projektet Stærkere

### 1. iPhone Proximity Trigger

Det her er virkelig godt:

- Brug Bluetooth proximity til at opdage, om din iPhone/telefon er tæt på
- Hvis MacBook bevæger sig væk fra telefonen: alarm
- Hvis telefonen går væk, men Mac'en bliver: eventuelt auto-lock i stedet for alarm

Det er sværere end MVP, så lav det som roadmap.

### 2. Charger Disconnect Trigger

Hvis nogen prøver at tage computeren, trækker de ofte opladeren ud først.

Trigger:

> Power adapter disconnected while armed

Action:

> Alarm + lock screen + notification

Det er en super praktisk feature.

### 3. Motion Trigger

MacBooks har ikke altid direkte "motion sensor" på moderne modeller, men man kan stadig arbejde med:

- Sudden wake
- Lid close
- Power disconnect
- Bluetooth distance
- Network change
- Find My-lignende proxy via iPhone senere

### 4. Network Change Trigger

Hvis Mac'en forlader caféens Wi-Fi eller skifter netværk mens armed:

Trigger:

> Wi-Fi SSID changed/disconnected

Action:

> Alarm or silent alert

Det kan være fedt, fordi det indikerer, at computeren er flyttet.

### 5. Silent Mode

Ikke altid skal appen skrige. Nogle vil hellere have:

- Lås skærm
- Tag webcam snapshot
- Send lokal notifikation
- Start lyd efter 10 sekunder
- Skriv event-log

Webcam snapshot kan dog være følsomt privacy-wise, så det skal være opt-in og meget tydeligt.

### 6. Sleep/Wake Delay

Når Mac'en vågner mens PublicGuard er armed, skal appen ikke nødvendigvis gå amok med det samme.

Eksempel:

> Wake while armed -> configured grace period -> configured response

Så brugeren kan nå at disarme.

### 7. Public Session Mode

En fed UX-feature:

- Working at cafe
- Working at library
- Working at school
- Working in office

Hver mode har forskellige triggers.

Eksempel:

Café mode:

- Lid close alarm
- Charger disconnect alarm
- Phone distance trigger
- Max volume alarm

Library mode:

- Silent notification first
- Lock screen
- Alarm only after 15 sec

## Roadmap

- iPhone Bluetooth proximity
- Location-based triggers
- Public session presets
- Apple Watch support
- Shortcuts integration
- Find My-style helper workflow
- Encrypted event logs
- More alarm sound tuning and manual loudness QA

## OpenAI- og OSS-Vinkel

For at gøre projektet mere relevant til Codex for OSS skal det ikke beskrives som:

> I made a Mac alarm app.

Det skal i stedet beskrives som:

> This is an open-source macOS security utility for developers and maintainers who work in public spaces. It helps protect open-source contributors' devices, code, tokens, SSH keys, and local development environments from opportunistic theft or unauthorized access.

Den vinkel er meget stærkere.

OpenAI nævner også, at API credits kan bruges til coding, maintainer automation, release workflows og core OSS work. Derfor kan man skrive, at Codex skal bruges til:

- macOS permissions/security review
- SwiftUI implementation
- GitHub Actions
- Tests
- Docs
- Release automation
- Issue triage
- Contributor onboarding
- Security hardening

## Features hvor AI/Codex Giver Mening

For selve appen behøver der ikke være AI i runtime. Faktisk er det bedre, hvis appen er lokal og privacy-first.

Men i OSS-projektet kan AI bruges til udvikling og vedligeholdelse:

- Automated PR summaries
- Security review of macOS permission-sensitive code
- Release note generation
- Issue triage
- Documentation improvements
- Test generation

Det passer bedre til OpenAI-programmet end at smide AI ind i appen uden grund.

## Tekniske Valg

Byg projektet i:

- Swift
- SwiftUI
- AppKit

Det passer bedst, fordi det er en macOS menu bar app.

## Foreslået Repo-Struktur

```text
PublicGuard/
  PublicGuard.xcodeproj
  PublicGuard/
    App/
    MenuBar/
    Security/
    Triggers/
    Audio/
    Logs/
  docs/
  examples/
  .github/workflows/
  README.md
  LICENSE
  CONTRIBUTING.md
  SECURITY.md
  CHANGELOG.md
```

## Trigger-Moduler

- LidCloseTrigger
- PowerDisconnectTrigger
- BluetoothProximityTrigger
- NetworkChangeTrigger
- WakeFromSleepTrigger
- IdleTimeoutTrigger

## Action-Moduler

- PlayAlarmAction
- LockScreenAction
- ShowNotificationAction
- WriteLogAction
- DelayAction

Denne arkitektur gør projektet mere OSS-venligt, fordi andre kan bidrage med nye triggers og actions.

## Hvad Projektet Skal Undgå

Undgå at gøre den til en creepy tracking-app.

Skriv ikke:

- Track your stolen laptop live
- Record the thief
- Spy through webcam
- Send location secretly

Skriv hellere:

- Privacy-first local protection
- User-controlled triggers
- No background tracking
- No cloud dependency
- No hidden recording

Det gør projektet mere seriøst og mere Apple/OpenAI-venligt.

## Samlet Vurdering

Ja, byg den.

Den er mere interessant end en random SaaS-idé, fordi den har:

- Klar use case
- Hurtigt MVP-scope
- macOS-native angle
- Security/privacy angle
- OSS-potentiale
- "Build in public" brand
- Mulighed for contributors
- Reel nytte for studerende, devs og founders

I forhold til OpenAI-godkendelse bliver projektet stærkest, hvis det hurtigt kommer til at ligne et rigtigt open source-projekt med docs, issues, releases og roadmap. OpenAI kigger på brug, betydning og aktiv vedligeholdelse.

## Konklusion

PublicGuard er en ret god lille OSS-app, hvis den positioneres som et privacy-first macOS security utility for folk, der arbejder offentligt med kode, data, credentials og lokale udviklingsmiljøer.
