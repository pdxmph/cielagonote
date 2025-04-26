#!/usr/bin/env ruby

require 'fileutils'
require 'date'
require 'yaml'

# --- LOAD CONFIGURATION ---
default_config = {
  "notes_dir" => "~/notes",
  "default_extension" => "md",
  "exclude_dirs" => [],
  "editor" => "nb edit"
}

config_file = File.expand_path("~/.zvconfig.yml")
user_config = File.exist?(config_file) ? YAML.load_file(config_file) : {}

config = default_config.merge(user_config)

notes_dir = File.expand_path(config["notes_dir"])
default_extension = config["default_extension"]
exclude_dirs = config["exclude_dirs"]
editor = config["editor"]

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

def load_notes(notes_dir, exclude_dirs)
  exclude_patterns = exclude_dirs.flat_map { |d| ["--glob '!#{d}'", "--glob '!#{d}/**'"] }.join(' ')
  rg_command = "rg --files --hidden #{exclude_patterns} #{notes_dir}"
  rg_output = `#{rg_command}`
  rg_output.split("\n").map { |f| f.sub("#{notes_dir}/", '') }.uniq
end

def today_note_name(extension)
  "daily-#{Date.today.strftime("%m-%d-%Y")}.#{extension}"
end

# --- MAIN LOOP ---
loop do
  files = load_notes(notes_dir, exclude_dirs)
  today_file = today_note_name(default_extension)

  fzf_command = [
    'fzf',
    '--prompt=Search or create: ',
    '--layout=reverse',
    '--print-query',
    '--expect=enter,ctrl-n',
    '--preview', %Q{( [[ {} == "[+] Create new note:"* ]] && echo "Will create: #{today_date}-$(echo {q} | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g').#{default_extension}" ) || ([[ -f #{notes_dir}/{} ]] && bat --style=numbers --color=always #{notes_dir}/{} || echo "No preview available")},
    '--preview-window', 'right:70%:wrap'
  ]

  selected = IO.popen(fzf_command, 'r+') do |fzf|
    ([today_file] + files).each { |file| fzf.puts(file) }
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

  # --- DEBUG OUTPUT (optional, comment out if noisy) ---
  puts "DEBUG:"
  puts "Key: #{key.inspect}"
  puts "Query: #{query.inspect}"
  puts "Selection: #{selection.inspect}"
  puts "------"

  # --- ACTIONS ---
  if key == 'ctrl-n' && !query.empty?
    # Force create new note from query
    path = create_note(notes_dir, query, default_extension)
    system("#{editor} \"#{path}\"")
  elsif key == 'enter'
    if selection == today_file
      # Special :today file handling
      path = File.join(notes_dir, today_file)
      unless File.exist?(path)
        create_note(notes_dir, "Daily - #{today_date}", default_extension)
      end
      system("#{editor} \"#{path}\"")
    elsif selection.start_with?("[+] Create new note:")
      # Create from "new note" special entry
      path = create_note(notes_dir, query, default_extension)
      system("#{editor} \"#{path}\"")
    elsif !selection.empty?
      # Normal open selected file
      full_path = File.join(notes_dir, selection)
      system("#{editor} \"#{full_path}\"")
    elsif !query.empty?
      # Create from query if no selection
      path = create_note(notes_dir, query, default_extension)
      system("#{editor} \"#{path}\"")
    else
      puts "No valid action. Exiting."
      break
    end
  else
    puts "No valid action. Exiting."
    break
  end
end
