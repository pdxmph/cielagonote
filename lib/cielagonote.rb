# lib/cielagonote.rb

require 'fileutils'
require 'date'
require 'yaml'

module CielagoNote
  class CLI
    def self.start

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

    end
  end
end
