module Docs
  class GjsScraper
    # CleanHtmlFilter for GJS's in-tree documentation. This is currently empty,
    # but could be used to make adjustments to the HTML.
    class CleanHtmlFilter < Filter
      def call
        doc
      end
    end
  end
end
