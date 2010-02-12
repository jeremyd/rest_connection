class Executable < RightScale::Api::Base

  # executable can be EITHER a right_script or recipe
  # executable example params format:
  # can have recipes AND right_scripts
  # @params =
  #    { :recipe =>
  #      :position => 12,
  #      :apply => "operational",
  #      :right_script => { "href" => "http://blah", 
  #                         "name" => "blah" 
  #                         ...
  #      }

  def recipe?
    if self["recipe"].nil? && right_script['href']
      return false
    end
    true
  end

  def right_script?
    if self["recipe"].nil? && right_script['href']
      return true
    end
    false
  end

  def name
    if right_script?
      return right_script.name
    else
      return recipe
    end
  end

  def href
    if right_script? 
      return right_script.href
    else
      #recipes do not have hrefs, only names
      return recipe
    end
  end

  def right_script
    RightScript.new(@params['right_script'])
  end
end
