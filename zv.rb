#!/usr/bin/env ruby

require 'fileutils'
require 'date'

# --- CONFIGURATION ---
notes_dir = File.expand_path("~/notes")
default_extension = "md"  # or "org"
editor = "nb edit"        # your editing command (adjust if needed)
use_fulltext_search = true
# ----------------------

# --- HELPER FUNCTIONS ---
def slugify(text)
  text.downcase.strip.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-')
end

def today_date
  Date.today.strftime("%Y-%m-%d")
end

def create_note(notes_dir, title, extension)
  filename = "#{today_date}-#{slugify(title)}.#{extension}"
  path = File.join(notes_dir, filename)

  unless File.exist?(path)
    File.open(path, 'w') do |f|
      if extension == "md"
        f.puts "# #{title}"
      elsif extension == "org"
        f.puts "#+TITLE: #{title}"
      end
    end
    puts "Created: #{path}"
  else
    puts "Note already exists: #{path}"
  end

  path
end

# --- MAIN LOOP ---
loop do
  files = Dir.glob("#{notes_dir}/**/*.{org,md}").map { |f| f.sub("#{notes_dir}/", '') }

  matches = if use_fulltext_search
    rg_output = `rg --files-with-matches --hidden --glob '!denote/**' '' #{notes_dir}`
    rg_output.split("\n").map { |f| f.sub("#{notes_dir}/", '') }.uniq
  else
    files
  end

  today_slug = today_date

  fzf_command = [
    'fzf',
    '--prompt=Search or create: ',
    '--layout=reverse',
    '--print-query',
    '--expect=enter,ctrl-n',
    '--preview', %Q{( [[ {} == ":today" ]] && ([[ -f #{notes_dir}/daily-#{today_slug}.#{default_extension} ]] && bat --style=numbers --color=always #{notes_dir}/daily-#{today_slug}.#{default_extension} || echo "No daily note yet.") ) || ([[ -f #{notes_dir}/{} ]] && bat --style=numbers --color=always #{notes_dir}/{} || echo "Will create: #{today_date}-$(echo {} | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g').#{default_extension}")},
    '--preview-window', 'right:70%:wrap'
  ]

  selected = IO.popen(fzf_command, 'r+') do |fzf|
    matches.each { |file| fzf.puts(file) }
    fzf.close_write
    fzf.read
  end

  if selected.nil? || selected.strip.empty?
    puts "No input given. Exiting."
    break
  end

  lines = selected.lines.map(&:chomp)

  if lines.length >= 3
    query = lines[0]
    key = lines[1]
    selection = lines[2]
  elsif lines.length == 2
    query = lines[0]
    key = lines[1]
    selection = ""
  else
    query = ""
    key = lines[0] || ""
    selection = ""
  end

  query.strip!
  key.strip!
  selection.strip!

  # --- DEBUG OUTPUT ---
  puts "DEBUG:"
  puts "Key: #{key.inspect}"
  puts "Query: #{query.inspect}"
  puts "Selection: #{selection.inspect}"
  puts "------"

  if key == 'ctrl-n' && !query.empty?
    # Force create new note from query
    path = create_note(notes_dir, query, default_extension)
    system("#{editor} \"#{path}\"")
  elsif key == 'enter' && !selection.empty?
    # Normal open selected file
    full_path = File.join(notes_dir, selection)
    system("#{editor} \"#{full_path}\"")
  elsif key == 'enter' && !query.empty?
    # Create new note if no selection
    path = create_note(notes_dir, query, default_extension)
    system("#{editor} \"#{path}\"")
  else
    puts "No valid action. Exiting."
    break
  end
end
