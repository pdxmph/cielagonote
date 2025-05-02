# lib/cielagonote.rb

require 'fileutils'
require 'date'
require 'yaml'

module CielagoNote
  class CLI
    def self.start
      # --- LOAD CONFIGURATION ---
      default_config = {
        "notes_dir"          => "~/notes",
        "default_extension"  => "md",
        "exclude_dirs"       => [],
        "editor"             => "vi",
        "hide_hidden"        => false,
        "nb_support"         => false,
        "daily_format"       => "cn"
      }
      config_file   = File.expand_path("~/.cnconfig.yml")
      user_config   = File.exist?(config_file) ? YAML.load_file(config_file) : {}
      config        = default_config.merge(user_config)

      notes_dir         = File.expand_path(config["notes_dir"])
      default_extension = config["default_extension"]
      exclude_dirs      = config["exclude_dirs"]
      hide_hidden       = config["hide_hidden"]
      nb_support        = config["nb_support"]
      daily_format      = config["daily_format"] || "cn"
      editor_cmd        = nb_support ? "nb edit" : config["editor"]

      # --- HELPER FUNCTIONS ---

      # normalize and slugify any title
      def self.slugify(text)
        text
        # normalize any Unicode dashes into ASCII hyphens
        .tr('–—−', '-')
        .downcase
        .strip
        # drop anything that isn’t a word character, space, or hyphen
        .gsub(/[^\w\s-]/, '')
        # turn runs of whitespace into single hyphens
        .gsub(/\s+/, '-')
        # collapse multiple hyphens into one
        .gsub(/-+/, '-')
        # remove leading or trailing hyphens
        .gsub(/\A-+|-+\z/, '')
      end

      # returns the full path if a daily file exists, or nil otherwise
      def self.find_daily_path(notes_dir, extension)
        date_str_nb   = Date.today.strftime('%Y%m%d')
        date_str_user = Date.today.strftime('%Y-%m-%d')

        candidates = [
          "#{date_str_nb}.#{extension}",                # nb’s format
          "daily-#{date_str_user}.#{extension}"         # your slug format
        ]

        candidates.each do |fname|
          full = File.join(notes_dir, fname)
          return full if File.exist?(full)
        end

        nil
      end


      # create (if needed) and open a note, honoring nb_support and special-casing "Daily"
      # in lib/cielagonote.rb, inside CLI
      def self.create_note(notes_dir, title, extension)
        slug     = slugify(title)
        is_daily = title.downcase.start_with?('daily')

        filename = if is_daily
          "#{slug}.#{extension}"
        else
          "#{Date.today.strftime('%Y-%m-%d')}-#{slug}.#{extension}"
        end
        path = File.join(notes_dir, filename)

        unless File.exist?(path)
          File.open(path, 'w') do |f|
            if extension == 'md'
              f.puts "# #{title}"
            elsif extension == 'org'
              f.puts "#+TITLE: #{title}"
            end
          end
          puts "Created: #{path}"
        else
          puts "Note already exists: #{path}"
        end

        path
      end






      def self.today_filename(extension)
        "daily-#{Date.today.strftime('%Y-%m-%d')}.#{extension}"
      end


      def self.load_notes(notes_dir, exclude_dirs, hide_hidden)
        exclude_patterns = exclude_dirs.flat_map { |d| ["--glob '!#{d}'", "--glob '!#{d}/**'"] }.join(' ')
        hidden_flag      = hide_hidden ? "" : "--hidden"
        rg_command       = "rg --files #{hidden_flag} #{exclude_patterns} #{notes_dir}"
        `#{rg_command}`.split("\n").map { |f| f.sub("#{notes_dir}/", '') }.uniq
      end

      def self.edit_with_cleanup(editor_command, path)
        system("#{editor_command} \"#{path}\"")
      end

      # --- MAIN LOOP ---
      loop do
        files = load_notes(notes_dir, exclude_dirs, hide_hidden)
        fzf_command = [
          'fzf',
          '--prompt=Search or create: ',
          '--layout=reverse',
          '--print-query',
          '--expect=enter,ctrl-n,ctrl-d,ctrl-r,ctrl-c,ctrl-t',
          '--preview', %Q{([[ -f #{notes_dir}/{} ]] && bat --style=numbers --color=always #{notes_dir}/{} || echo "No preview available")},
                              '--preview-window', 'right:70%:wrap',
                              '--header', "\e[1m(n)\e[0mew, \e[1m(d)\e[0mel, \e[1m(c)\e[0mopy, \e[1m(r)\e[0mename, \e[1m(t)\e[0moday, \e[1m(enter)\e[0m edit",
                              '--color', 'header:italic:underline,fg+:bright-white,bg+:black,fg:gray'
                              ]

                            selected = IO.popen(fzf_command, 'r+') do |fzf|
                              files.each { |file| fzf.puts(file) }
                              fzf.puts "[+] Create new note: {q}"
                              fzf.close_write
                              fzf.read
                            end

                            break if selected.nil? || selected.strip.empty?

                            lines = selected.lines.map(&:chomp)
                            if lines.length >= 3
                              query, key, selection = lines[0], lines[1], lines[2]
                            elsif lines.length == 2
                              query, key, selection = lines[0], lines[1], ""
                            else
                              query, key, selection = "", lines[0] || "", ""
                            end
                            query.strip!; key.strip!; selection.strip!

                            case key
                            when 'ctrl-n'
                              system("stty sane")
                              path = create_note(notes_dir, query, default_extension)
                              edit_with_cleanup(editor_cmd, path)


                            when 'enter'
                              if selection.start_with?('[+]') || (!query.empty? && selection.empty?)
                                system("stty sane")
                                path = create_note(notes_dir, query, default_extension)
                                edit_with_cleanup(editor_cmd, path)
                              elsif !selection.empty?
                                full_path = File.join(notes_dir, selection)
                                if File.exist?(full_path)
                                  edit_with_cleanup(editor_cmd, full_path)
                                else
                                  puts "Selected file does not exist. Aborting."
                                end
                              else
                                puts "No valid action. Exiting."
                                break
                              end


                            when 'ctrl-d'
                              if selection.empty?
                                puts "No note selected for deletion."
                              else
                                full_path = File.join(notes_dir, selection)
                                if !File.exist?(full_path)
                                  puts "Selected file does not exist. Aborting."
                                else
                                  if nb_support
                                    # let `nb delete` handle its own confirmation prompt
                                    Dir.chdir(notes_dir) do
                                      system("nb delete \"#{selection}\"")
                                    end
                                  else
                                    # manual confirmation for non-nb mode
                                    print "Delete #{selection}? (y/n): "
                                    answer = STDIN.gets.chomp.downcase
                                    if answer == 'y'
                                      File.delete(full_path)
                                      puts "Deleted: #{selection}"
                                    else
                                      puts "Cancelled."
                                    end
                                  end
                                end
                              end

                            when 'ctrl-r'
                              if !selection.empty?
                                full_path = File.join(notes_dir, selection)
                                if File.exist?(full_path)
                                  # restore terminal to cooked + echo mode
                                  system("stty sane")

                                  print "Rename #{selection} to (new name): [#{selection}] "
                                  input    = STDIN.gets.chomp
                                  new_name = input.empty? ? selection : input

                                  if File.exist?(File.join(notes_dir, new_name))
                                    puts "File #{new_name} already exists. Aborting."
                                  else
                                    if nb_support
                                      # do in-place rename via nb
                                      Dir.chdir(notes_dir) do
                                        system("nb rename \"#{selection}\" \"#{new_name}\"")
                                      end
                                      puts "Renamed via nb: #{selection} → #{new_name}"
                                    else
                                      FileUtils.mv(full_path, File.join(notes_dir, new_name))
                                      puts "Renamed: #{selection} → #{new_name}"
                                    end
                                  end
                                else
                                  puts "Selected file does not exist. Aborting."
                                end
                              else
                                puts "No note selected for renaming."
                              end



                            when 'ctrl-c'
                              if !selection.empty?
                                full_path = File.join(notes_dir, selection)
                                if File.exist?(full_path)
                                  if RUBY_PLATFORM.include?('darwin')
                                    system("cat \"#{full_path}\" | pbcopy")
                                    puts "Copied to clipboard."
                                  elsif RUBY_PLATFORM.include?('linux')
                                    system("cat \"#{full_path}\" | xclip -selection clipboard")
                                    puts "Copied to clipboard."
                                  else
                                    puts "Clipboard copy not supported on this platform."
                                  end
                                else
                                  puts "Selected file does not exist. Aborting."
                                end
                              else
                                puts "No note selected to copy."
                              end


                          when 'ctrl-t'
  system("stty sane")

  if nb_support && daily_format == "nb"
    # nb’s YYYYMMDD.ext convention
    today_str = Date.today.strftime("%Y%m%d")
    fname     = "#{today_str}.#{default_extension}"
    full      = File.join(notes_dir, fname)

    if File.exist?(full)
      # file’s already there → open it interactively
      Dir.chdir(notes_dir) do
        system("nb edit \"#{fname}\"")
      end
    else
      # first entry of the day → one‐off prompt
      print "First entry for #{today_str}: "
      entry = STDIN.gets.chomp
      Dir.chdir(notes_dir) do
        system("nb daily \"#{entry}\"")
      end
    end

  else
    # CielagoNote’s own daily convention in either mode
    title = "Daily – #{Date.today.strftime('%Y-%m-%d')}"
    path  = create_note(notes_dir, title, default_extension)
    edit_with_cleanup(editor_cmd, path)
  end
end







                            end
                            end # start
                            end # CLI
                            end # module
