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

#
# API 1.5
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
