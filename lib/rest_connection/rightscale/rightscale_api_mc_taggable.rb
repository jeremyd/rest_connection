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
        @params["tags"] ||= []
        @params["tags"].map! { |item| item.is_a?(Hash) ? item["name"] : item }
        @params["tags"].deep_merge!(McTag.search_by_href(self.href).first["tags"].map { |hsh| hsh["name"] }) if reload or @params["tags"].empty?
        @params["tags"]
      end

      def remove_info_tags(*tag_keys)
        remove_tags_by_namespace("info", *tag_keys)
      end

      def set_info_tags(hsh={})
        set_tags_by_namespace("info", hsh)
      end

      def get_info_tags(*tag_keys)
        tags = get_tags_by_namespace("info")
        tags.each { |resource,hsh|
          hsh.reject! { |key,value|
            rej = false
            rej = !tag_keys.include?(key) unless tag_keys.empty?
            rej
          }
        }
        return ret
      end

      def remove_tags_by_namespace(namespace, *tag_keys)
        tags_to_unset = []
        tags = get_tags_by_namespace(*(tag_keys.uniq))
        tags.each { |res,hsh|
          hsh.each { |k,v|
            tags_to_unset << "#{namespace}:#{k}=#{v}"
          }
        }
        self.remove_tags(*tags_to_unset)
      end

      def set_tags_by_namespace(namespace, hsh={})
        keys_to_change = []
        tags_to_set = []
        hsh.each { |k,v| keys_to_change << k; tags_to_set << "#{namespace}:#{k}=#{v}" }
        self.remove_tags_by_namespace(namespace, *keys_to_change)
        self.add_tags(*tags_to_set)
      end

      def get_tags_by_namespace(namespace)
        ret = {}
        tags = {"self" => self.tags(true)}
        tags.each { |res,ary|
          ret[res] ||= {}
          ary.each { |tag|
            next unless tag.start_with?("#{namespace}:")
            key = tag.split("=").first.split(":").last
            value = tag.split(":")[1..-1].join(":").split("=")[1..-1].join("=")
            ret[res][key] = value
          }
        }
        return ret
      end

      def set_tags_to(*args)
        STDERR.puts "set_tags_to(...) is deprecated"
        self.clear_tags("info")
        self.add_tags(*(args.uniq))
      end

      def clear_tags(namespace = nil)
        tag_ary = self.tags(true)
        tag_ary = tag_ary.select { |tag| tag.start_with?("#{namespace}:") } if namespace
        self.remove_tags(*tag_ary)
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
