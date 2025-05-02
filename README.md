**CielagoNote** is a quick little thing to build a Notational Velocity-style TUI app on top of some common shell tools. 

It was origiinally built to assume [`nb`](https://github.com/xwmx/nb) for version-controlled notes, but you can use it on its own with any old editor.   

---

## Features

- Instant fuzzy search across `.org` and `.md` notes (powered by `fzf`)
- Configurable exclusion of hidden directories or special folders (e.g., `.git/`, `denote/`)
- YAML-based configuration (`~/.cnconfig.yml`)
- New notes use date-stamped filenames (`YYYY-MM-DD-slugified-title.md`)
- Clean previews with [`bat`](https://github.com/sharkdp/bat)
- Daily notes: `C-t` to either make or jump to a daily note. 
- Switchable support between the nb command line tool or standalone note creation. 

## nb support 

This started as something to manage nb notes a little more quickly, but took a turn and can either continue to fit into `nb` or can just be a standalone notes manager. 

If all you want is support for fuzzy search in nb itself, you may want to consider a [small plugin by Chris Woodham][fzf] that provides fuzzy title search and drops you into a proper nb edit session on open. 

cielagonote offers similar but also provides a few other convenience features to make it a little more speedy to work with nb. With nb configuration enabled in `~./cnconfig.yml` (see _Configuration_ below): 

- support for nb file management (creation, deletion, renaming) to ensure the underlying nb repo stays in sync with the filesystem and remotes
- support for nb's [daily plugin][], creating daily notes in its preferred `yyyymmdd.ext` format, or opening such notes when it finds them. 

One thing to note: in nb_support mode, cielagonote will use the editor you have configured in nb, overriding the setting in `~/.cnconfig.yml`. That's so we can just use the `nb edit` command and get on with our day.

[fzf]: https://github.com/xwmx/nb/issues/102#issuecomment-922791236
[daily plugin]: https://github.com/xwmx/nb/blob/master/plugins/daily.nb-plugin

---

# configuring how daily notes work

If the `daily_format:` setting is `nb`, cielagonote will use nb's `daily` plugin for creating daily notes: `yyyymmdd.ext`.

If the `daily_format:` setting is `cn`, cielagonote will use cn's preferrred approach: `daily-yyyy-mm-dd.ext`

If you'd prefer cielagonote's format but want to keep using nb for everything else, there's a forked daily plugin you can install instead:

`nb plugin install https://github.com/pdxmph/cielagonote/blob/main/extras/cn-daily.nb-plugin`

That version of the daily plugin creates and expect `daily-yyyy-mm-dd.ext` daily files for creation and listing. 

If you press `^t` and there isn't yet a daily note for the current date:

- `daily_format: nb` will drop you into the command line to enter your first entry. Thereafter, `^t` will open the day's note.
- `daily_format: cn` will create a note if it doesn't exist yet, then drop you into the editor. 

---
## standalone use without nb support

Without nb support enabled, cielagonote is more like a CLI Notational Velocity or [deft][], using standard tools to make, edit, delete, or rename notes. Unlike nb's daily plugin, cielagonote prefers a more readable `daily-yyyy-mm-dd.ext` format for daily notes since that's more amenable to fuzzy filename search, and works better for Markdown wiki systems that parse the file for an l1 title heading.


[deft]: https://github.com/jrblevin/deft


## Requirements


- [Ruby](https://www.ruby-lang.org/) 
- [fzf](https://github.com/junegunn/fzf)
- [ripgrep (rg)](https://github.com/BurntSushi/ripgrep)
- [bat](https://github.com/sharkdp/bat) 
- [nb (optional)](https://github.com/xwmx/nb)


--- 

## Example Workflow

1. Run `cn`
2. Type part of a note name
3. Instantly:
   - Open matching note (Enter)
   - Create new note (Enter or Ctrl-N if you're on a partial match.)
   - Jump to today's daily note (`:today`)
4. Edit notes quickly using your favorite terminal editor (`nb edit`, `emacsclient`, `micro`, etc.)
5. Let `nb` handle version control automatically

---

## Keystrokes

|Key Combo | Action |
|----|----|
|C-c | Copy note to clipboard|
|C-d | Delete note (with confirm)|
|C-r | Rename file|
|C-t | Create or jump to a daily note |
|C-q | Quit|

## Configuration

Example `~/.cnconfig.yml`

```yaml
notes_dir: ~/notes
default_extension: md # or org
exclude_dirs:
  - denote
  - .git
hide_hidden: true # hides .files when enabled
editor: micro # will be overridden with `nb edit` if nb_support == true
nb_support: false # if true, overrides your editor: setting and enables nb file management
daily_format: cn # if `nb` daily notes will use the nb format and commands
```

## Why?

I mean, "because."

I woke up yesterday morning thinking about [a recent bunch of complaining][blog] I did about the over-complication of things that should be simple, and how little I like feeling trapped in fragile stuff. I did some iterating around building some tools inside Emacs to make it easy to do org-capture-style note-taking, but felt sort of itchy that I was still doing it all inside Emacs. 

So I came across nb and took a liking to it thanks to its git syncing, plugin architecture, and general featureset, but I also wanted a faster way to find my notes and do something with them.  I also hate the thought of being married to much of anything in the way of editors, note-taking frameworks, etc. so I started my morning with a zsh wrapper around fzf, and I'm ending my evening with this. 

There are other things that do this with more polish and features. The thing I sort of like about this is that you could take away nb and just keep using it. You can pick whatever editor and use it. Mainly I just thought "I want to find things and edit them and not be a participant in some ecosystem or framework."


[blog]: https://puddingtime.org/lmno-blog-captureel-and-the-whole-lightweight-text-thing
