require 'spec_helper'

describe Airbrake::Error do
  before(:all) do
    Airbrake.account = 'myapp'
    Airbrake.auth_token = 'abcdefg123456'
    Airbrake.secure = false
  end

  it "should have correct collection path" do
    Airbrake::Error.collection_path.should == "/errors.xml"
  end

  it "should generate correct error path given an id" do
    Airbrake::Error.error_path(1234).should == "/errors/1234.xml"
  end

  describe '.find' do
    it "should find a page of the 30 most recent errors" do
      errors = Airbrake::Error.find(:all)
      ordered = errors.sort_by(&:most_recent_notice_at).reverse
      ordered.should == errors
      errors.size.should == 30
    end

    it "should paginate errors" do
      errors = Airbrake::Error.find(:all, :page => 2)
      ordered = errors.sort_by(&:most_recent_notice_at).reverse
      ordered.should == errors
      errors.size.should == 2
    end

    it "should find an individual error" do
      error = Airbrake::Error.find(1696170)
      error.action.should == 'index'
      error.id.should == 1696170
    end

    it "should raise an error when not passed an id" do
      lambda do
        Airbrake::Error.find
      end.should raise_error(Airbrake::AirbrakeError)
    end
  end

  describe '.update' do
    it 'should update the status of an error' do
      error = Airbrake::Error.update(1696170, :group => { :resolved => true})
      error.resolved.should be_true
    end
  end

end