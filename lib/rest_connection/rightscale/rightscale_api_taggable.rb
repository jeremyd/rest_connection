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

module RightScale
  module Api
    module Taggable
      def add_tags(*args)
        return false if args.empty?
        Tag.set(self.href, args.uniq)
        self.tags(true)
      end

      def remove_tags(*args)
        return false if args.empty?
        Tag.unset(self.href, args.uniq)
        self.tags(true)
      end

      def tags(reload=false)
        @params["tags"] ||= []
        @params["tags"].map! { |item| item.is_a?(Hash) ? item["name"] : item }
        @params["tags"].deep_merge!(Tag.search_by_href(self.href).map { |hsh| hsh["name"] }) if reload or @params["tags"].empty?
        @params["tags"]
      end

      def remove_info_tags(*tag_keys)
        tags_to_unset = []
        tags = get_tag_values(*(tag_keys.uniq))
        tags.each { |res,hsh|
          hsh.each { |k,v|
            tags_to_unset << "info:#{k}=#{v}"
          }
        }
        self.remove_tags(*tags_to_unset)
      end
    
      def set_info_tags(hsh={})
        keys_to_change = []
        tags_to_set = []
        hsh.each { |k,v| keys_to_change << k; tags_to_set << "info:#{k}=#{v}" }
        self.remove_tags_by_keys(*keys_to_change)
        self.add_tags(*tags_to_set)
      end
    
      def get_info_tags(*tag_keys)
        ret = {}
        tags = {"self" => self.tags(true)}
        tags.each { |res,ary|
          ret[res] ||= {}
          ary.each { |tag|
            next unless tag.start_with?("info:")
            key = tag.split("=").first.split(":").last
            value = tag.split(":")[1..-1].join(":").split("=")[1..-1].join("=")
            if tag_keys.empty?
              ret[res][key] = value
            else
              ret[res][key] = value if tag_keys.include?(key)
            end
          }
        }
        return ret
      end
  
      def set_tags_to(*args)
        self.clear_tags("info")
        self.add_tags(*(args.uniq))
      end
  
      def clear_tags(namespace = nil)
        tag_ary = self.tags(true)
        tag_ary = tag_ary.select { |tag| tag.start_with?("#{namespace}:") } if namespace
        self.remove_tags(*tag_ary)
      end
    end

    module TaggableExtend
      def find_by_tags(*args)
        a = Array.new
        Tag.search(self.resource_singular_name, args.uniq).each do |object|
          a << self.new(object)
        end
        return a
      end
    end
  end
end
