require 'rubygems'
require 'hoe'
require './lib/timecode.rb'

Hoe.new('timecode', Timecode::VERSION) do |p|
  p.developer('Julik', 'me@julik.nl')
  p.extra_deps.reject! {|e| e[0] == 'hoe' }
  p.extra_deps << 'test-spec'
  p.rubyforge_name = 'guerilla-di'
  p.remote_rdoc_dir = 'timecode'
end

task "specs" do
  `specrb test/* --rdox > SPECS.txt`
end