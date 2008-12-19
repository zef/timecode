require 'rubygems'
require 'hoe'
require './lib/timecode.rb'

Hoe.new('timecode', Timecode::VERSION) do |p|
  p.developer('Julik', 'me@julik.nl')
  p.extra_deps.reject! {|e| e[0] == 'hoe' }
  p.rubyforge_name = 'wiretap'
  p.remote_rdoc_dir = 'timecode'
end