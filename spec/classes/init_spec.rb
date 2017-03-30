require 'spec_helper'
describe 'yabt' do

  context 'with defaults for all parameters' do
    it { should contain_class('yabt') }
  end
end
