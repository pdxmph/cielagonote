# CHANGELOG


## [0.10] - 2025-05-02

This release improves support for the [stock nb daily plugin][daily], which assumes a file naming convention of `yyyymmdd.ext` and doesn't provide a title line in either case. 

- When `nb_support: true` in your `~/.cnconfig.yml`, `^t` will either create or open a file in the nb-expected format using nb itself to insure proper sync.
- When `nb_support: false` in your `~/.cnconfig.yml`, `^t` will create or open a file in the `daily-yyyy-mm-dd.ext` format, with an l1 title heading. 


## [0.9] - 2025-05-01
- Fixing slugification to remove multiple substitutions from slugified files


## [0.8] - 2025-05-01 
- Removing confirm dialog from deletion when nb_support is true: nb will ask anyhow

## [0.7] - 2025-05-01

Fixes a regression in nb file creation. 

## [0.5] - 2025-05-01

### Changed
- Making a daily note with `^t` creates a specific daily file: `daily-yyyy-mm-dd.ext`. That is at odds with the nb daily plugin convention. For simplicity's sake, cielagonote uses its own format regardless of your `nb_support:` setting in `~/.cnconfig.yml`

## [0.4] - 2025-05-01

### Added 
- Support for nb as a configurable option. See sample config in the README. You can choose between using nb file management, or just use cielagonote as a standalone notes manager in your choice of org-mode or Markdown. 

## [0.3] - 2025-05-01

### Added
- Warnings about using this with nb until I can build an nb config option

### Removed
- No longer `reset`s the terminal when returning from edits. 


[daily]: https://github.com/xwmx/nb/blob/master/plugins/daily.nb-plugin
