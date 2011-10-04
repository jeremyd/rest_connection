#    This file is part of RestConnection
#
#    RestConnection is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    RestConnection is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with RestConnection.  If not, see <http://www.gnu.org/licenses/>.

#
# You must have Beta v1.5 API access to use these internal API calls.
#
module RightScale
  module Api
    module McTaggable
      include RightScale::Api::Taggable
      def add_tags(*args)
        return false if args.empty?
        McTag.set(self.href, args.uniq)
        self.tags(true)
      end

      def remove_tags(*args)
        return false if args.empty?
        McTag.unset(self.href, args.uniq)
        @params["tags"] -= args
        self.tags(true)
      end

      def tags(reload=false)
        @params["tags"] ||= []
        @params["tags"].map! { |item| item.is_a?(Hash) ? item["name"] : item }
        @params["tags"].deep_merge!(McTag.search_by_href(self.href).first["tags"].map { |hsh| hsh["name"] }) if reload or @params["tags"].empty?
        @params["tags"]
      end
    end

    module McTaggableExtend
      def find_by_tags(*args)
        a = Array.new
        search = McTag.search(self.resource_plural_name, args.uniq).first
        if search
          search["links"].each do |hash|
            a << self.find(hash["href"])
          end
        end
        return a
      end
    end
  end
end
