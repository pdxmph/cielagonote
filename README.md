**CielagoNote** is a quick little thing to build a Notational Velocity-style TUI app on top of some common shell tools. 

It was origiinally built to assume [`nb`](https://github.com/xwmx/nb) for version-controlled notes, but you can use it on its own with any old editor and should look at the "Warnings" below before using it that way. 

---

## Features

- Instant fuzzy search across `.org` and `.md` notes (powered by `fzf`)
- Configurable exclusion of hidden directories or special folders (e.g., `.git/`, `denote/`)
- YAML-based configuration (`~/.zvconfig.yml`)
- New notes use date-stamped filenames (`YYYY-MM-DD-slugified-title.md`)
- Clean previews with [`bat`](https://github.com/sharkdp/bat)
- Daily notes: `C-t` to either make or jump to a daily note. 

## Warnings

This started as something to manage nb notes a little more quickly, but took a turn and can either continue to fit into `nb` or can just be a standalone notes manager: 

- There's a fuzzy search plugin for nb that works fine and keeps you in complete alignment with nb if that's what you want, and may be good enough for most people. 
- I've added preliminary support for nb file management and creation. It needs to be turned on in the config file (see _Configuration_ below)
- With nb support enabled: 
  - rename, deletion, and creation all go through nb commands
  - your editor preference is overrideden in favor of your `nb` editor setting

This all seems to work just fine, but it's preliminary support so you should pay attention to the first few outcomes. 

---

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
|C-c | Copy to clipboard|
|C-d | Delete note (with confirm)|
|C-r | Rename file|
|C-t | Create or jump to daily-yyyy-mm-dd.ext|
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
```

## Why?

I mean, "because."

I woke up yesterday morning thinking about [a recent bunch of complaining][blog] I did about the over-complication of things that should be simple, and how little I like feeling trapped in fragile stuff. I did some iterating around building some tools inside Emacs to make it easy to do org-capture-style note-taking, but felt sort of itchy that I was still doing it all inside Emacs. 

So I came across nb and took a liking to it thanks to its git syncing, plugin architecture, and general featureset, but I also wanted a faster way to find my notes and do something with them.  I also hate the thought of being married to much of anything in the way of editors, note-taking frameworks, etc. so I started my morning with a zsh wrapper around fzf, and I'm ending my evening with this. 

There are other things that do this with more polish and features. The thing I sort of like about this is that you could take away nb and just keep using it. You can pick whatever editor and use it. Mainly I just thought "I want to find things and edit them and not be a participant in some ecosystem or framework."


[blog]: https://puddingtime.org/lmno-blog-captureel-and-the-whole-lightweight-text-thing
