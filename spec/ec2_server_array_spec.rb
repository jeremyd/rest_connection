require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe Ec2ServerArray, "takes over the world with some server arrays" do
  before(:all) do
    # store temporary resources in @t_resources so we can tear down afterwards
    @t_resources = Hash.new
    @t_resources[:deployment] = Deployment.create(:nickname => "testdeploymentcandelete123")
    @default_sec_group = Ec2SecurityGroup.find(:first) { |g| g.aws_group_name == 'default' }
    @mci = MultiCloudImage.find(:first)
# Need to hardcode a server template with a script with no inputs, for the test of run on all
    @server_template = ServerTemplate.find(63400)
    #@t_resources[:server_template] = ServerTemplate.create( :nickname => "Nickname of the ServerTemplate",
    #                                                        :description => "Description of the ServerTemplate",
    #                                                        :multi_cloud_image_href => @mci.href 
    #                                                        )

# SSH Keys index call is 403 forbidden so lookup is not possible. 
# Hardcoded for a default key.
    @ssh_key = Ec2SshKey.find(7053)
    @t_resources[:ec2_server_array] = Ec2ServerArray.create(:nickname => "testarraycandelete123", 
                                                            :description => "created by specs run, you can delete this if you want", 
                                                            :array_type => "alert", 
                                                            #:elasticity_params => , 
                                                            :active => 'true',
                                                            :deployment_href => @t_resources[:deployment].href, 
                                                            :server_template_href => @server_template.href, 
                                                            #:indicator_href,
                                                            #:audit_queue_href, 
                                                            :ec2_ssh_key_href => @ssh_key.href, 
                                                            :ec2_security_group_href => @default_sec_group.href,
                                                            #:ec2_security_groups_href => , 
                                                            #:elasticity_function, 
                                                            :elasticity => { :min_count => "1", :max_count => "2" }, 
                                                            #:parameters, 
                                                            #:tags,
                                                            :collect_audit_entries => "1"
                                                            )
    @my_array = @t_resources[:ec2_server_array]
  end

  it "should get all the instances in the array" do
    my_instances = @my_array.instances
    my_instances.class.should == Array
  end 

  it "should run a script on all the servers in the array" do
    right_script = @server_template.executables.first
    result = @my_array.run_script_on_all(right_script, [@server_template.href])
    puts "hello"
    puts "blah" 
  end

  it "should terminate all instances in the array" do
    @my_array.active = "false"
    @my_array.save
    @my_array.terminate_all
  end

  after(:all) do
    @t_resources.each do |key,val|
      val.destroy
    end
  end
end
