module Docs
  class GjsScraper < Github
    self.name = 'GJS'
    self.base_url = 'https://github.com/GNOME/gjs/blob/master/doc/'
    self.root_path = 'README.md'
    self.initial_paths = %w[
      ByteArray
      cairo
      Console
      Encoding
      Environment
      ESModules
      Format
      Gettext
      Lang
      Logging
      Mainloop
      Mapping
      Overrides
      Profiling
      Signals
      System
      Testing
      Timers
    ].map { |name| name + '.md' }

    html_filters.push 'gjs_scraper/entries', 'gjs_scraper/clean_html'

    options[:container] = '.markdown-body'
    options[:title] = 'GJS'
    options[:skip_links] = true

    options[:attribution] = <<-HTML
      &copy; 2022 GJS Contributors<br>
      Licensed under the MIT License.
    HTML

    def get_latest_version(opts)
      tags = get_gitlab_tags('gitlab.gnome.org', 'GNOME', 'gjs', opts)
      tags[0]['name']
    end
  end
end
