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
class McServerTemplate
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  include RightScale::Api::McInput

  def resource_plural_name
    "server_templates"
  end

  def resource_singular_name
    "server_template"
  end

  def self.resource_plural_name
    "server_templates"
  end

  def self.resource_singular_name
    "server_template"
  end

  def self.filters
    [:description, :multi_cloud_image_href, :name, :revision]
  end

  def get_mcis_and_settings
    @params["multi_cloud_images"] = McMultiCloudImage.find_all(self.rs_id)
    @params["multi_cloud_images"].each { |mci| mci.settings } # Eager load
    @mci_links = McServerTemplateMultiCloudImage.find_with_filter(:server_template_href => self.href)
  end

  def multi_cloud_images
    unless @params["multi_cloud_images"]
      get_mcis_and_settings
    end
    @params["multi_cloud_images"]
  end

  def add_multi_cloud_image(mci_href)
    @mci_links = McServerTemplateMultiCloudImage.find_with_filter(:server_template_href => self.href)
    if @mci_links.detect { |mci_link| mci_link.multi_cloud_image == mci_href }
      connection.logger("WARNING: MCI #{mci_href} is already attached")
    else
      ret = McServerTemplateMultiCloudImage.create(:multi_cloud_image_href => mci_href,
                                                   :server_template_href => self.href)
      get_mcis_and_settings
      ret
    end
  end

  def detach_multi_cloud_image(mci_href)
    @mci_links = McServerTemplateMultiCloudImage.find_with_filter(:server_template_href => self.href)
    if link = @mci_links.detect { |mci_link| mci_link.multi_cloud_image == mci_href }
      ret = link.destroy
      get_mcis_and_settings
      ret
    else
      connection.logger("WARNING: MCI #{mci_href} is not attached")
    end
  end

  def set_default_multi_cloud_image(mci_href)
    @mci_links = McServerTemplateMultiCloudImage.find_with_filter(:server_template_href => self.href)
    if link = @mci_links.detect { |mci_link| mci_link.multi_cloud_image == mci_href }
      ret = link.make_default
      get_mcis_and_settings
      ret
    else
      connection.logger("WARNING: MCI #{mci_href} is not attached")
    end
  end

  def commit(message, commit_head_dependencies, freeze_repositories)
    options = {:commit_message => "#{message}",
               :commit_head_dependencies => (commit_head_dependencies && true),
               :freeze_repositories => (freeze_repositories && true)}
    t = URI.parse(self.href)
    location = connection.post(t.path + "/commit", options)
    newrecord = McServerTemplate.new('links' => [ {'rel' => 'self', 'href' => location } ])
    newrecord.reload
    newrecord
  end
end
