# lib/cielagonote.rb

require 'fileutils'
require 'date'
require 'yaml'

module CielagoNote
  class CLI
    def self.start
      # --- LOAD CONFIGURATION ---
      default_config = {
        "notes_dir" => "~/notes",
        "default_extension" => "md",
        "exclude_dirs" => [],
        "editor" => "nb edit",
        "hide_hidden" => false
      }

      config_file = File.expand_path("~/.cnconfig.yml")
      user_config = File.exist?(config_file) ? YAML.load_file(config_file) : {}

      config = default_config.merge(user_config)

      notes_dir = File.expand_path(config["notes_dir"])
      default_extension = config["default_extension"]
      exclude_dirs = config["exclude_dirs"]
      editor = config["editor"]
      hide_hidden = config["hide_hidden"]

      # --- HELPER FUNCTIONS ---
      def self.slugify(text)
        text.downcase.strip.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-')
      end

      def self.today_date
        Date.today.strftime("%Y-%m-%d")
      end

      def self.create_note(notes_dir, title, extension)
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

      def self.load_notes(notes_dir, exclude_dirs, hide_hidden)
        exclude_patterns = exclude_dirs.flat_map { |d| ["--glob '!#{d}'", "--glob '!#{d}/**'"] }.join(' ')
        hidden_flag = hide_hidden ? "" : "--hidden"
        rg_command = "rg --files #{hidden_flag} #{exclude_patterns} #{notes_dir}"
        rg_output = `#{rg_command}`
        rg_output.split("\n").map { |f| f.sub("#{notes_dir}/", '') }.uniq
      end

      def self.today_note_name(extension)
        "daily-#{Date.today.strftime("%m-%d-%Y")}.#{extension}"
      end

      def self.edit_with_cleanup(editor_command, path)
        system("#{editor_command} \"#{path}\"; reset")
      end

      # --- MAIN LOOP ---
      loop do
        files = load_notes(notes_dir, exclude_dirs, hide_hidden)
        today_file = today_note_name(default_extension)

        fzf_command = [
          'fzf',
          '--prompt=Search or create: ',
          '--layout=reverse',
          '--print-query',
          '--expect=enter,ctrl-n',
          '--preview', %Q{( [[ {} == "[+] Create new note:"* ]] && echo "Will create: #{today_date}-$(echo {q} | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g').#{default_extension}" ) || ([[ -f #{notes_dir}/{} ]] && bat --style=numbers --color=always #{notes_dir}/{} || echo "No preview available")},
          '--preview-window', 'right:70%:wrap',
          '--header', 'Select a note or create a new one',
          '--color', 'header:italic:underline,fg+:bright-white,bg+:black,fg:gray'
        ]

        selected = IO.popen(fzf_command, 'r+') do |fzf|
          ([today_file] + files + ["[+] Create new note: {q}"]).each { |file| fzf.puts(file) }
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

        # --- DEBUG OUTPUT (optional) ---
        puts "DEBUG:"
        puts "Key: #{key.inspect}"
        puts "Query: #{query.inspect}"
        puts "Selection: #{selection.inspect}"
        puts "------"

        # --- ACTIONS ---
        if key == 'ctrl-n' && !query.empty?
          path = create_note(notes_dir, query, default_extension)
          edit_with_cleanup(editor, path)
        elsif key == 'enter'
          if selection == today_file
            path = File.join(notes_dir, today_file)
            unless File.exist?(path)
              create_note(notes_dir, "Daily - #{today_date}", default_extension)
            end
            edit_with_cleanup(editor, path)
          elsif selection.start_with?("[+] Create new note")
            path = create_note(notes_dir, query, default_extension)
            edit_with_cleanup(editor, path)
          elsif !selection.empty?
            full_path = File.join(notes_dir, selection)
            edit_with_cleanup(editor, full_path)
          elsif !query.empty?
            path = create_note(notes_dir, query, default_extension)
            edit_with_cleanup(editor, path)
          else
            puts "No valid action. Exiting."
            break
          end
        else
          puts "No valid action. Exiting."
          break
        end
      end # end loop
    end # end self.start
  end # end CLI class
end # end module
