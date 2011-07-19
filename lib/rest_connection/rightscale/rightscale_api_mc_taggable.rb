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
      def add_tags(*args)
        return false if args.empty?
        McTag.set(self.href, args.uniq)
        self.tags(true)
      end

      def remove_tags(*args)
        return false if args.empty?
        McTag.unset(self.href, args.uniq)
        self.tags(true)
      end

      def tags(reload=false)
        @params["tags"] = McTag.search_by_href(self.href).first["tags"] if reload
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
          ary.each { |hsh|
            next unless hsh["name"].start_with?("info:")
            key, value = hsh["name"].split(":").last.split("=")
            ret[res][key] = value if tag_keys.include?(key)
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
        tag_ary = tag_ary.select { |hsh| hsh["name"].start_with?("#{namespace}:") } if namespace
        self.remove_tags(*(tag_ary.map { |k,v| v }))
      end
    end

    module McTaggableExtend
      def find_by_tags(*args)
        a = Array.new
        McTag.search(self.resource_singular_name, args.uniq).each do |object|
          a << self.new(object)
        end
        return a
      end
    end
  end
end
