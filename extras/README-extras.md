# Extras 

## cn-daily nb plugin 

### Install 

`nb plugin install https://github.com/pdxmph/cielagonote/main/extras/cn-daily.nb-plugin`

### Usage

```bash
nb daily [<content>] [--prev [<number>]]
```

### Options

| Option | Description |
|:---|:---|
| `--prev [<number>]` | List previous days and show the day by previous `<number>`. |

### Description

Add notes to a daily log.

- When called **without arguments**, the current day's log is displayed.
- When passed `<content>`, a new timestamped entry is added to the current day's log, which is created if it doesn't yet exist.
- Previous day's logs can be listed with the `--prev` option.
- View a previous day's log by passing its `<number>` from the list.

### Examples

```bash
nb daily "Example note content."
nb daily
nb daily --prev
nb daily --prev 3
```

