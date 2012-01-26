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


class RightScript
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :create, :destroy, :update

  def self.from_yaml(yaml)
    scripts = []
    x = YAML.load(yaml)
    x.keys.each do |script|
      scripts << self.new('href' => "right_scripts/#{script}", 'name' => x[script].ivars['name'])
    end
    scripts
  end

  def self.from_instance_info(file = "/var/spool/ec2/rs_cache/info.yml")
    scripts = []
    if File.exists?(file)
      x = YAML.load(IO.read(file))
    elsif File.exists?(File.join(File.dirname(__FILE__),'info.yml'))
      x = YAML.load(IO.read(File.join(File.dirname(__FILE__),'info.yml')))
    else
      return nil
    end
    x.keys.each do |script|
      scripts << self.new('href' => "right_scripts/#{script}", 'name' => x[script].ivars['name'])
    end
    scripts
  end

end
