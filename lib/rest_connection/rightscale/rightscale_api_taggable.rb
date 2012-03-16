#--
# Copyright (c) 2010-2012 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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
        @params["tags"] -= args
        self.tags(true)
      end

      def tags(reload=false)
        @params["tags"] ||= []
        @params["tags"].map! { |item| item.is_a?(Hash) ? item["name"] : item }
        @params["tags"].deep_merge!(Tag.search_by_href(self.href).map { |hsh| hsh["name"] }) if reload or @params["tags"].empty?
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
        return tags
      end

      def remove_tags_by_namespace(namespace, *tag_keys)
        tags_to_unset = []
        tags = get_tags_by_namespace(namespace)
        tags.each { |res,hsh|
          hsh.each { |k,v|
            tags_to_unset << "#{namespace}:#{k}=#{v}" if tag_keys.include?(k)
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
            key = tag.split("=").first.split(":")[1..-1].join(":")
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
