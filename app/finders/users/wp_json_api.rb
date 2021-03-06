module WPScan
  module Finders
    module Users
      # WP JSON API
      #
      # Since 4.7 - Need more investigation as it seems WP 4.7.1 reduces the exposure, see https://github.com/wpscanteam/wpscan/issues/1038)
      # For the pagination, see https://github.com/wpscanteam/wpscan/issues/1285
      #
      class WpJsonApi < CMSScanner::Finders::Finder
        MAX_PER_PAGE = 100 # See https://developer.wordpress.org/rest-api/using-the-rest-api/pagination/

        # @param [ Hash ] opts
        #
        # @return [ Array<User> ]
        def aggressive(_opts = {})
          found        = []
          current_page = 0

          loop do
            current_page += 1

            res = Typhoeus.get(api_url, params: { per_page: MAX_PER_PAGE, page: current_page })

            total_pages ||= res.headers['X-WP-TotalPages'].to_i

            users_in_page = users_from_response(res)
            found        += users_in_page

            break if current_page >= total_pages || users_in_page.empty?
          end

          found
        rescue JSON::ParserError, TypeError
          found
        end

        # @param [ Typhoeus::Response ] response
        #
        # @return [ Array<User> ] The users from the response
        def users_from_response(response)
          found = []

          JSON.parse(response.body)&.each do |user|
            found << CMSScanner::User.new(user['slug'],
                                          id: user['id'],
                                          found_by: found_by,
                                          confidence: 100,
                                          interesting_entries: [response.effective_url])
          end

          found
        end

        # @return [ String ] The URL of the API listing the Users
        def api_url
          @api_url ||= target.url('wp-json/wp/v2/users/')
        end
      end
    end
  end
end
