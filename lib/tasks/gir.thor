require 'rexml/document'
require 'xdg'

# Command-line tools for creating scrapers from GIR files
class GirCLI < Thor
  def self.to_s
    'Gir'
  end

  def initialize(*args)
    require 'docs'
    super
  end

  desc 'generate_all [--include <path>]', 'Generate scrapers from all installed GIR files'
  option :include, type: :string
  def generate_all(gir_dir = nil)
    if gir_dir
      glob = Dir.glob(gir_dir + '/*.gir')
    else
      glob = XDG::Data.new.directories.map {|dir| dir.glob('gir-1.0/*.gir') }.flatten
    end
    glob.each do |path|
      puts 'Generating scraper for ' + File.basename(path) + '...'
      begin
        generate path
      rescue REXML::ParseException
        puts 'Failed to generate scraper for... ' + File.basename(path) + '...'
      end
    end
  end

  desc 'generate <path> [--include <path>]', 'Generate a scraper from a GIR file'
  option :include, type: :string
  def generate(gir_path)
    gir = read_gir gir_path

    namespace = gir.root.elements['namespace']
    scraper_info = process_namespace namespace
    scraper_info[:slug] = generate_slug scraper_info
    scraper_info[:release] = compute_release gir, scraper_info
    if options[:include]
      scraper_info[:extra_include] = options[:include]
    end
    write_scraper gir_path, scraper_info
  end

  no_commands do
    def read_gir(path)
      gir_file = File.new path
      gir = REXML::Document.new gir_file
      gir_file.close
      gir
    end

    def process_namespace(namespace)
      {
        name: namespace.attributes['name'],
        version: namespace.attributes['version'],
        c_prefix: namespace.attributes['c:symbol-prefixes']
      }
    end

    def generate_slug(scraper_info)
      full_name = scraper_info[:name] + scraper_info[:version]
      full_name.downcase.strip.gsub(/[^\w-]/, '')
    end

    # The "release" is the right-aligned dim label (e.g. "4.8.2"), in contrast
    # to the "version", which is really the API version (e.g. "4.0")
    def determine_release(gir)
      %w(MAJOR MINOR MICRO).map do |name|
        selector = "string(//constant[@name='#{name}_VERSION']/@value)"
        component = REXML::XPath.first gir, selector
        # Try a more lenient search - would match e.g. GDK_PIXBUF_MAJOR
        selector = "string(//constant[contains(@name, '#{name}')]/@value)"
        component = REXML::XPath.first gir, selector if component == ''
        fail 'No version found' if component == ''
        component
      end.join '.'
    rescue
      nil
    end

    def guess_release(gir)
      selector = '//namespace/*[@version]/@version'
      versions = REXML::XPath.match(gir, selector).map do |ver|
        Gem::Version.new(ver.to_s.chomp '.')  # they can have stray periods
      end
      return nil if versions == []
      versions.max.to_s << '+'
    end

    def compute_release(gir, scraper_info)
      release = determine_release gir
      release = guess_release gir if release.nil?
      api_version = scraper_info[:version] + ' API'
      release = api_version if release.nil? || api_version[0..1] > release[0..1]
      release
    end

    def scraper_code(gir_path, info)
      gir_name = "#{info[:name]}-#{info[:version]}.gir"
      code = <<-END.strip_heredoc
    module Docs
      # Autogenerated scraper for #{gir_name}
      class #{info[:slug].capitalize} < GirScraper
#{info.keys.map { |k| "        self.#{k} = '#{info[k]}'" }.join "\n"}
        self.gir_path = '#{gir_path}'
        self.extra_include = '#{info[:extra_include]}'
        options[:attribution].sub! '{GIR_NAME}', '#{gir_name}'
      end
    end
      END
      code
    end

    def write_scraper(gir_path, info)
      scraper_name = File.join 'lib', 'docs', 'scrapers', 'gnome', 'generated',
                               info[:slug] + '.rb'
      out_file = File.new scraper_name, 'w'
      out_file.write scraper_code(gir_path, info)
    end
  end
end
