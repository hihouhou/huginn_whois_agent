require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::WhoisAgent do
  before(:each) do
    @valid_options = Agents::WhoisAgent.new.default_options
    @checker = Agents::WhoisAgent.new(:name => "WhoisAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
