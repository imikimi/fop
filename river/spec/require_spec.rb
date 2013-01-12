require File.join(File.dirname(__FILE__),"spec_helper")

describe "to_code" do
  include RiverSpecHelper

  def in_spec_dir
    pwd = Dir.pwd
    Dir.chdir File.expand_path(File.dirname(__FILE__))
    yield
    Dir.chdir pwd
  end

  it "optional parenthesis" do
    in_spec_dir do
      test_eval <<ENDCODE, 120
require "test_files/require_test.river"
foo
ENDCODE
    end
  end

end
