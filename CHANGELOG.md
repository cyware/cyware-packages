# Change Log
All notable changes to this project will be documented in this file.
## [4.9.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.9.0
## [4.8.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.8.0

## [4.7.1]

- https://github.com/cyware/cyware-packages/releases/tag/v4.7.1

## [v4.7.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.7.0

## [v4.6.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.6.0

## [v4.5.4]

- https://github.com/cyware/cyware-packages/releases/tag/v4.5.4

## [v4.5.3]

- https://github.com/cyware/cyware-packages/releases/tag/v4.5.3

## [v4.5.2]

- https://github.com/cyware/cyware-packages/releases/tag/v4.5.2

## [v4.5.1]

- https://github.com/cyware/cyware-packages/releases/tag/v4.5.1

## [v4.5.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.5.0

## [v4.4.5]

- https://github.com/cyware/cyware-packages/releases/tag/v4.4.5

## [v4.4.4]

- https://github.com/cyware/cyware-packages/releases/tag/v4.4.4

## [v4.4.3]

- https://github.com/cyware/cyware-packages/releases/tag/v4.4.3

## [v4.4.2]

- https://github.com/cyware/cyware-packages/releases/tag/v4.4.2

## [v4.3.11]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.11

## [v4.4.1]

- https://github.com/cyware/cyware-packages/releases/tag/v4.4.1

## [v4.4.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.4.0

## [v4.3.10]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.10

## [v4.3.9]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.9

## [v4.3.8]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.8

## [v4.3.7]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.7

## [v4.3.6]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.6

## [v4.3.5]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.5

## [v4.3.4]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.4

## [v4.3.3]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.3

## [v4.3.2]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.2

## [v4.2.7]

- https://github.com/cyware/cyware-packages/releases/tag/v4.2.7

## [v4.3.1]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.1

## [v4.3.0]

- https://github.com/cyware/cyware-packages/releases/tag/v4.3.0

## [v4.2.6]

- Update SPECS [#1392](https://github.com/cyware/cyware-packages/pull/1392)

## [v4.2.5]

- Update SPECS [#991](https://github.com/cyware/cyware-packages/pull/991)

## [v4.2.4]

- Update SPECS [#927](https://github.com/cyware/cyware-packages/pull/927)

## [v4.2.3]

- Update SPECS [#915](https://github.com/cyware/cyware-packages/pull/915)

## [v4.2.2]

- Update SPECS [#846](https://github.com/cyware/cyware-packages/pull/846)

## [v4.2.1]

- Update SPECS [#833](https://github.com/cyware/cyware-packages/pull/833)

## [v4.2.0]

- Update SPECS [#556](https://github.com/cyware/cyware-packages/pull/556)

## [v4.1.5]

- Update SPECS [#726](https://github.com/cyware/cyware-packages/pull/726)

## [v4.1.4]

- Update SPECS [#684](https://github.com/cyware/cyware-packages/pull/684)

## [v4.1.3]

- Update SPECS [#668](https://github.com/cyware/cyware-packages/pull/668)

## [v4.1.2]

- Update SPECS [#656](https://github.com/cyware/cyware-packages/pull/656)

## [v4.1.1]

- Updated Cyware app build script [#648](https://github.com/cyware/cyware-packages/pull/648)

## [v4.0.2]

### Added

- Added a new welcome message to Cyware VM ([#535](https://github.com/cyware/cyware-packages/pull/535)).

### Fixed

- Fixed the group of the `ossec.conf` in IBM AIX package ([#541](https://github.com/cyware/cyware-packages/pull/541)).

## [v4.0.1]

### Fixed

- Added new SSL certificates to secure Kibana communications and ensure HTTPS access to the UI ([#534](https://github.com/cyware/cyware-packages/pull/534)).

## [v4.0.0]

### Added

- Added Open Distro for Elasticsearch packages to Cyware's software repository.

### Changed

- Cyware services are no longer enabled nor started in a fresh install ([#466](https://github.com/cyware/cyware-packages/pull/466)).
- Cyware services will be restarted on upgrade if they were running before upgrading them ([#481](https://github.com/cyware/cyware-packages/pull/481)) and ([#482](https://github.com/cyware/cyware-packages/pull/482)).
- Cyware API and Cyware Manager services are unified in a single `cyware-manager` service ([#466](https://github.com/cyware/cyware-packages/pull/466)).
- Cyware app for Splunk and Cyware plugin for Kibana have been renamed ([#479](https://github.com/cyware/cyware-packages/pull/479)).
- Cyware VM now uses Cyware and Open Distro for Elasticsearch ([#462](https://github.com/cyware/cyware-packages/pull/462)).

### Fixed

- Unit files for systemd are now installed on `/usr/lib/systemd/system` ([#466](https://github.com/cyware/cyware-packages/pull/466)).
- Unit files are now correctly upgraded ([#466](https://github.com/cyware/cyware-packages/pull/466)).
- `ossec-init.conf` file now shows the build date for any system ([#466](https://github.com/cyware/cyware-packages/pull/466)).
- Fixed an error setting SCA file permissions on .deb packages ([#466](https://github.com/cyware/cyware-packages/pull/466)).

### Removed

- Cyware API package has been removed. Now, the Cyware API is embedded into the Cyware Manager installation ([cyware/cyware#5721](https://github.com/cyware/cyware/pull/5721)).
- Removed OpenSCAP files and integration ([#466](https://github.com/cyware/cyware-packages/pull/466)).
