module Docs
  class GjsScraper
    class EntriesFilter < Docs::EntriesFilter
      SKIP_SYMBOLS = [
        'ECMAScript Modules'
      ]

      # "name" is the title of the entry in the sidebar.
      def get_name
        node = at_css('h1')
        name = node.content.strip
      end

      # "type" is the expandable group the "name" is under.
      def get_type
        node = at_css('h1')
        type = node.content.strip
      end

      def strip_symbol (node, entry)
        # If this is a function (e.g. "baz()"), strip down to the member
        # name to get a reasonable sidebar entry and fragment link
        func_match = /(.*)(?=\(.*\))/.match(entry[0])
        if func_match
          entry[0] = func_match[1] + '()'
          entry[1] = node['id'] = func_match[1].parameterize
        end
      end

      def additional_entries
        # skip README.md
        return [] if root_page?

        css('h2, h3').each_with_object [] do |node, entries|
          # skip `###` entries for pages that don't have symbols
          next if node.name == 'h3' and SKIP_SYMBOLS.include? type
          
          # common filtering
          name = node.content.strip
          id = node['id'] = name.parameterize
          type = self.get_type
          entry = [name, id, type]
            
          if node.name == 'h3'
            strip_symbol node, entry
          end
          
          entries << entry
        end
      end
    end
  end
end
