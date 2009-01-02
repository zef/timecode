require 'rubygems'
require './lib/timecode.rb'
require 'hoe'

Class.new(Hoe) do
  def extra_deps
    @extra_deps.reject! { |x| Array(x).first == 'hoe' }
    @extra_deps
  end
end.new('timecode', Timecode::VERSION) do |p|
  p.developer('Julik', 'me@julik.nl')
  p.extra_deps.reject! {|e| e[0] == 'hoe' }
  p.extra_deps << 'test-spec'
  p.rubyforge_name = 'wiretap'
  p.remote_rdoc_dir = 'timecode'
end

task "specs" do
  `specrb test/* --rdox > SPECS.txt`
end