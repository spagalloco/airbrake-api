require 'spec_helper'

describe AirbrakeAPI::Project do
  before(:all) do
    AirbrakeAPI.account = 'myapp'
    AirbrakeAPI.auth_token = 'abcdefg123456'
    AirbrakeAPI.secure = false
  end

  it "should have correct projects path" do
    expect(AirbrakeAPI::Project.collection_path).to eq("/api/v4/projects")
  end

  it "should find projects" do
    projects = AirbrakeAPI::Project.find(:all)
    expect(projects.size).to eq(4)
    expect(projects.first.id).to eq(1)
    expect(projects.first.name).to eq('Venkman Project')
  end

end
