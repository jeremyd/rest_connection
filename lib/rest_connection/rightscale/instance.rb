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

# This is an instance facing api and can only be used with
# an authentication URL normally found in the instance's userdata called
# RS_API_URL
class Instance 
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend
  #def create_ebs_volume_from_snap(snap_aws_id)
  #  connection.post('create_ebs_volume.js', :aws_id => snap_aws_id )
  #end 

  def attach_ebs_volume(params)
    connection.put('attach_ebs_volume.js', params)
  end

  def create_ebs_snapshot(params)
    connection.post('create_ebs_snapshot.js', params)
  end

  def detach_ebs_volume(params)
    connection.put('detach_ebs_volume.js', params)
  end

  def delete_ebs_volume(params)
    connection.delete('delete_ebs_volume.js', params)
  end

  def create_ebs_volume(params)
    connection.post('create_ebs_volume.js', params)
  end
end
