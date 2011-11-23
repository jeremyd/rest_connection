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
    @params["multi_cloud_images"].each { |mci| mci.get_settings }
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
