# Changelog

## [1.10.0](https://github.com/igorbasko01/food-locker/compare/v1.9.0...v1.10.0) (2026-07-13)


### Features

* keep screen awake for 15s after each bite ([#59](https://github.com/igorbasko01/food-locker/issues/59)) ([e847371](https://github.com/igorbasko01/food-locker/commit/e84737133b1cd78677def45a3196bde404cb4dcf))
* reorder bite tab, center bite screen, and plan follow-ups ([#57](https://github.com/igorbasko01/food-locker/issues/57)) ([680948e](https://github.com/igorbasko01/food-locker/commit/680948ed0479e25633e9b4a00b7bb570c4400765))

## [1.9.0](https://github.com/igorbasko01/food-locker/compare/v1.8.0...v1.9.0) (2026-07-13)


### Features

* add bite logging screen with today's count (bite-pacing Phase 4) ([#54](https://github.com/igorbasko01/food-locker/issues/54)) ([3e1a0c2](https://github.com/igorbasko01/food-locker/commit/3e1a0c22774328b241ff01080579c80c2665ad18))
* add BiteRepository seam over Drift (bite-pacing Phase 3) ([#53](https://github.com/igorbasko01/food-locker/issues/53)) ([361c3b9](https://github.com/igorbasko01/food-locker/commit/361c3b9bf1588db2fc17e5de30dc69e4f493b8f8))
* add Drift bite log store (bite-pacing Phase 1) ([#51](https://github.com/igorbasko01/food-locker/issues/51)) ([24d2af6](https://github.com/igorbasko01/food-locker/commit/24d2af6a09590bd285e05848645d05603573aad6))
* add flutter-emulator-run skill ([#47](https://github.com/igorbasko01/food-locker/issues/47)) ([#48](https://github.com/igorbasko01/food-locker/issues/48)) ([e54f4e4](https://github.com/igorbasko01/food-locker/commit/e54f4e4002623dfd77c48dab323616cbbce114e2))
* add pacing visualization to bite screen (bite-pacing Phase 5) ([#55](https://github.com/igorbasko01/food-locker/issues/55)) ([395fabf](https://github.com/igorbasko01/food-locker/commit/395fabffa0bdec0d796c3febef8a2cf118165d0a))
* add pacing_config table with default seed (bite-pacing Phase 2) ([#52](https://github.com/igorbasko01/food-locker/issues/52)) ([bbb82a1](https://github.com/igorbasko01/food-locker/commit/bbb82a1b7865b2e8e0c69ba669540ca1375b55b2))
* add resolve-github-issue skill ([#44](https://github.com/igorbasko01/food-locker/issues/44)) ([#45](https://github.com/igorbasko01/food-locker/issues/45)) ([63ffd48](https://github.com/igorbasko01/food-locker/commit/63ffd486ddc5425697e0781e15b25f16d18c9710))
* two-store CSV backup for the bite log (bite-pacing Phases 6 & 7) ([#56](https://github.com/igorbasko01/food-locker/issues/56)) ([4c6f573](https://github.com/igorbasko01/food-locker/commit/4c6f5738fc72c5d3e0f18046f814171fb9e7761e))

## [1.8.0](https://github.com/igorbasko01/food-locker/compare/v1.7.1...v1.8.0) (2026-06-17)


### Features

* remove food tracking and transition to weight-only tracking ([#38](https://github.com/igorbasko01/food-locker/issues/38)) ([5356406](https://github.com/igorbasko01/food-locker/commit/5356406ea93aa6dc63d5ba5e668d49a244931fdf))

## [1.7.1](https://github.com/igorbasko01/food-locker/compare/v1.7.0...v1.7.1) (2026-05-20)


### Bug Fixes

* break overeating streak when food tracking day is missing ([#36](https://github.com/igorbasko01/food-locker/issues/36)) ([1831743](https://github.com/igorbasko01/food-locker/commit/183174309b43c00457c58f3249fc1119b16a8270))

## [1.7.0](https://github.com/igorbasko01/food-locker/compare/v1.6.0...v1.7.0) (2026-05-19)


### Features

* remove manual overate toggle and derive it dynamically from weight ([#34](https://github.com/igorbasko01/food-locker/issues/34)) ([7340ebb](https://github.com/igorbasko01/food-locker/commit/7340ebb226c5815ab8c863384784e18f6060fe8c))

## [1.6.0](https://github.com/igorbasko01/food-locker/compare/v1.5.1...v1.6.0) (2026-04-02)


### Features

* **weight:** add lowest weight statistics for all-time, 30d, 7d with… ([#31](https://github.com/igorbasko01/food-locker/issues/31)) ([838eae2](https://github.com/igorbasko01/food-locker/commit/838eae255f83c6f6148350ab95730dbdc028a21a))
* **weight:** add support for editing and deleting weight entries ([#29](https://github.com/igorbasko01/food-locker/issues/29)) ([fb46285](https://github.com/igorbasko01/food-locker/commit/fb46285e77886d63ad3eb11c09998dfb3420ea5e))

## [1.5.1](https://github.com/igorbasko01/food-locker/compare/v1.5.0...v1.5.1) (2026-03-31)


### Bug Fixes

* handle null overate in FoodDay for backward compatibility ([#27](https://github.com/igorbasko01/food-locker/issues/27)) ([ca75423](https://github.com/igorbasko01/food-locker/commit/ca754235ba7185746b31a84db89d4f2f5fd69a95))

## [1.5.0](https://github.com/igorbasko01/food-locker/compare/v1.4.0...v1.5.0) (2026-03-31)


### Features

* add body weight tracking feature with fl_chart visualization ([9836314](https://github.com/igorbasko01/food-locker/commit/98363145e72b70803ab76232a10652abe5c0c546))
* allow adjusting meal/snack time via long press ([#24](https://github.com/igorbasko01/food-locker/issues/24)) ([165d486](https://github.com/igorbasko01/food-locker/commit/165d486e6b2cf6581a5c433c68ce77aa210767af))

## [1.4.0](https://github.com/igorbasko01/food-locker/compare/v1.3.0...v1.4.0) (2026-03-28)


### Features

* add overeating streak banner to home page ([#22](https://github.com/igorbasko01/food-locker/issues/22)) ([1c9c8fc](https://github.com/igorbasko01/food-locker/commit/1c9c8fc010bcc89fb0c6ff78d920ddb2de7bfe7d))
* **ui:** add weekday indicator to history and home pages ([#20](https://github.com/igorbasko01/food-locker/issues/20)) ([e929acf](https://github.com/igorbasko01/food-locker/commit/e929acf1a63597e85dbdf2ff0ac0902000ae2492))

## [1.3.0](https://github.com/igorbasko01/food-locker/compare/v1.2.0...v1.3.0) (2026-03-28)


### Features

* allow editing historical days with time picker ([#19](https://github.com/igorbasko01/food-locker/issues/19)) ([6ecbc27](https://github.com/igorbasko01/food-locker/commit/6ecbc27c5688211d7f96a6ae9d13e8cfa3fc211d))
* **days:** add overate tracking per day ([#16](https://github.com/igorbasko01/food-locker/issues/16)) ([e8901ac](https://github.com/igorbasko01/food-locker/commit/e8901acbedf9c51efdec5965c435170c2ec856fb))
* show food day date and add refresh button on home page ([#18](https://github.com/igorbasko01/food-locker/issues/18)) ([976dcd8](https://github.com/igorbasko01/food-locker/commit/976dcd816387c120d4a1a700d3ae43ce4dc2ca9d))

## [1.2.0](https://github.com/igorbasko01/food-locker/compare/v1.1.1...v1.2.0) (2026-03-14)


### Features

* **ci:** attach compiled apk to github release assets ([#11](https://github.com/igorbasko01/food-locker/issues/11)) ([f8e2f30](https://github.com/igorbasko01/food-locker/commit/f8e2f30469ed18820b3243f938715f5e2bfbdba6))
* Implement history page with collapsible days ([14094c2](https://github.com/igorbasko01/food-locker/commit/14094c2479d6260245dddc3f1374eca6b4f698e0))


### Bug Fixes

* **ci:** grant write permissions to build workflow to allow uploading assets to release ([#13](https://github.com/igorbasko01/food-locker/issues/13)) ([d1410af](https://github.com/igorbasko01/food-locker/commit/d1410af1fe3b86d2d4fa8ea2466cc89a053c207f))
* **ci:** trigger release workflow natively by authenticating release … ([#9](https://github.com/igorbasko01/food-locker/issues/9)) ([7d2985c](https://github.com/igorbasko01/food-locker/commit/7d2985cd5a00cf3b444ceb6c670c779a2beff0df))

## [1.1.1](https://github.com/igorbasko01/food-locker/compare/v1.1.0...v1.1.1) (2026-03-14)


### Bug Fixes

* **ci:** grant write permissions to build workflow to allow uploading assets to release ([#13](https://github.com/igorbasko01/food-locker/issues/13)) ([d1410af](https://github.com/igorbasko01/food-locker/commit/d1410af1fe3b86d2d4fa8ea2466cc89a053c207f))

## [1.1.0](https://github.com/igorbasko01/food-locker/compare/v1.0.1...v1.1.0) (2026-03-14)


### Features

* **ci:** attach compiled apk to github release assets ([#11](https://github.com/igorbasko01/food-locker/issues/11)) ([f8e2f30](https://github.com/igorbasko01/food-locker/commit/f8e2f30469ed18820b3243f938715f5e2bfbdba6))

## [1.0.1](https://github.com/igorbasko01/food-locker/compare/v1.0.0...v1.0.1) (2026-03-14)


### Bug Fixes

* **ci:** trigger release workflow natively by authenticating release … ([#9](https://github.com/igorbasko01/food-locker/issues/9)) ([7d2985c](https://github.com/igorbasko01/food-locker/commit/7d2985cd5a00cf3b444ceb6c670c779a2beff0df))

## 1.0.0 (2026-03-14)


### Features

* Implement history page with collapsible days ([14094c2](https://github.com/igorbasko01/food-locker/commit/14094c2479d6260245dddc3f1374eca6b4f698e0))
