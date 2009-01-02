require 'test/unit'
require 'rubygems'
require 'test/spec'

require File.dirname(__FILE__) + '/../lib/timecode'


context "Timecode on instantiation should" do
  
  specify "be instantable from int" do
    tc = Timecode.new(10)
    tc.should.be.kind_of Timecode
    tc.total.should.equal 10
  end
  
  specify "always coerce FPS to float" do
    Timecode.new(10, 24).fps.should.be.kind_of(Float)
    Timecode.new(10, 25.0).fps.should.be.kind_of(Float)
  end
  
  specify "create a zero TC with no arguments" do
    Timecode.new(nil).should.be.zero?
  end
end

context "An existing Timecode should" do
  
  before do
    @five_seconds = Timecode.new(5*25, 25)
    @one_and_a_half_film = (90 * 60) * 24
    @film_tc = Timecode.new(@one_and_a_half_film, 24)
  end
  
  
  specify "report that the framerates are in delta" do
    tc = Timecode.new(1)
    tc.framerate_in_delta(25.0000000000000001, 25.0000000000000003).should.equal(true)
  end
 
  specify "validate equality based on delta" do
    t1, t2 = Timecode.new(10, 25.0000000000000000000000000001), Timecode.new(10, 25.0000000000000000000000000002)
    t1.should.equal(t2)
  end
  
  specify "report total as it's to_i" do
    Timecode.new(10).to_i.should.equal(10)
  end
  
  specify "support hours" do
    @five_seconds.should.respond_to :hours
    @five_seconds.hours.should.equal 0
    @film_tc.hours.should.equal 1
  end

  specify "support minutes" do
    @five_seconds.should.respond_to :minutes
    @five_seconds.minutes.should.equal 0
    @film_tc.minutes.should.equal 30
    
  end

  specify "support seconds" do
    @five_seconds.should.respond_to :seconds
    @five_seconds.seconds.should.equal 5
    @film_tc.seconds.should.equal 0
  end
  
  specify "support frames" do
    @film_tc.frames.should.equal 0
  end
  
  specify "report frame_interval as a float" do
    tc = Timecode.new(10)
    tc.should.respond_to :frame_interval
    
    tc.frame_interval.should.be.close 0.04, 0.0001
    tc = Timecode.new(10, 30)
    tc.frame_interval.should.be.close 0.03333, 0.0001
  end
  
end

context "A Timecode of zero should" do
  specify "properly respond to zero?" do
    Timecode.new(0).should.respond_to :zero?
    Timecode.new(0).should.be.zero
    Timecode.new(1).should.not.be.zero
  end
end

context "An existing TImecode on inspection should" do
  specify "properly present himself via inspect" do
    Timecode.new(10, 25).inspect.should.equal "#<Timecode:00:00:00:10 (10F@25.00)>"
  end
  
  specify "properly print itself" do
    Timecode.new(5, 25).to_s.should.equal "00:00:00:05"
  end
end

context "An existing Timecode used within ranges should" do
  specify "properly provide successive value that is one frame up" do
    Timecode.new(10).succ.total.should.equal 11
    Timecode.new(22).succ.should.equal Timecode.new(23) 
  end
  
  specify "work as a range member" do
    r = Timecode.new(10)...Timecode.new(20)
    r.to_a.length.should.equal 10
    r.to_a[4].should.equal Timecode.new(14)
  end
  
end

context "A Timecode on conversion should" do
  specify "copy itself with a different framerate" do
    tc = Timecode.new(40,25)
    at24 = tc.convert(24)
    at24.total.should.equal 40
  end
end

context "A Timecode on calculations should" do
  
  specify "support addition" do
    a, b = Timecode.new(24, 25.000000000000001), Timecode.new(22, 25.000000000000002)
    (a + b).should.equal Timecode.new(24 + 22, 25.000000000000001)
  end
  
  specify "should raise on addition if framerates do not match" do
    lambda{ Timecode.new(10, 25) + Timecode.new(10, 30) }.should.raise(Timecode::WrongFramerate)
  end
  
  specify "when added with an integer instead calculate on total" do
    (Timecode.new(5) + 5).should.equal(Timecode.new(10))
  end
  
  specify "support subtraction" do
    a, b = Timecode.new(10), Timecode.new(4)
    (a - b).should.equal Timecode.new(6)
  end

  specify "on subtraction of an integer instead calculate on total" do
    (Timecode.new(15) - 5).should.equal Timecode.new(10)
  end
  
  specify "raise when subtracting a Timecode with a different framerate" do
    lambda { Timecode.new(10, 25) - Timecode.new(10, 30) }.should.raise(Timecode::WrongFramerate)
  end
  
  specify "support multiplication" do
    (Timecode.new(10) * 10).should.equal(Timecode.new(100))
  end
  
  specify "raise when the resultig Timecode is negative" do
    lambda { Timecode.new(10) * -200 }.should.raise(Timecode::RangeError)
  end
  
  specify "yield a Timecode when divided by an Integer" do
    v = Timecode.new(200) / 20
    v.should.be.kind_of(Timecode)
    v.should.equal Timecode.new(10)
  end
  
  specify "yield a number when divided by another Timecode" do
    v = Timecode.new(200) / Timecode.new(20)
    v.should.be.kind_of(Numeric)
    v.should.equal 10
  end
end

context "A Timecode used with fractional number of seconds" do
  
  specify "should properly return fractional seconds" do
    tc = Timecode.new(100 -1, fps = 25)
    tc.frames.should.equal 24
    
    tc.with_frames_as_fraction.should.equal "00:00:03.96"
    tc.with_fractional_seconds.should.equal "00:00:03.96"
  end

  specify "properly translate to frames when instantiated from fractional seconds" do
    fraction = 7.1
    tc = Timecode.from_seconds(fraction, 10)
    tc.to_s.should.equal "00:00:07:01"

    fraction = 7.5
    tc = Timecode.from_seconds(fraction, 10)
    tc.to_s.should.equal "00:00:07:05"

    fraction = 7.16
    tc = Timecode.from_seconds(fraction, 12.5)
    tc.to_s.should.equal "00:00:07:02"
  end

end

context "Timecode.at() should" do 
  
  specify "disallow more than 99 hrs" do
    lambda{ Timecode.at(99,0,0,0) }.should.not.raise
    lambda{ Timecode.at(100,0,0,0) }.should.raise(Timecode::RangeError)
  end
  
  specify "disallow more than 59 minutes" do
    lambda{ Timecode.at(1,60,0,0) }.should.raise(Timecode::RangeError)
  end

  specify "disallow more than 59 seconds" do
    lambda{ Timecode.at(1,0,60,0) }.should.raise(Timecode::RangeError)
  end
  
  specify "disallow more frames than what the framerate permits" do
    lambda{ Timecode.at(1,0,60,25, 25) }.should.raise(Timecode::RangeError)
    lambda{ Timecode.at(1,0,60,32, 30) }.should.raise(Timecode::RangeError)
  end

end


context "Timecode.parse() should" do
  
  specify "handle complete SMPTE timecode" do

    simple_tc = "00:10:34:10"
    
    lambda { Timecode.parse(simple_tc) }.should.not.raise
    
    Timecode.parse(simple_tc).to_s.should.equal(simple_tc)
  end
  
  specify "refuse to handle timecode that is out of range for the framerate" do
    bad_tc = "00:76:89:30"
    lambda { Timecode.parse(bad_tc, 25) }.should.raise(Timecode::RangeError)
  end
  
  specify "parse a row of numbers as parts of a timecode starting from the right" do
    Timecode.parse("10").should.equal Timecode.new(10)
    Timecode.parse("210").should.equal Timecode.new(60)
    Timecode.parse("10101010").to_s.should.equal "10:10:10:10"
  end
  
  specify "parse a number with f suffix as frames" do
    Timecode.parse("60f").should.equal Timecode.new(60)
  end
  
  specify "parse a number with s suffix as seconds" do
    Timecode.parse("2s", 25).should.equal Timecode.new(50, 25)    
    Timecode.parse("2s", 30).should.equal Timecode.new(60, 30)
  end

  specify "parse a number with m suffix as minutes" do
    Timecode.parse("3m").should.equal Timecode.new(25 * 60 * 3)
  end
  
  specify "parse a number with h suffix as hours" do
    Timecode.parse("3h").should.equal Timecode.new(25 * 60 * 60 * 3)
  end
  
  specify "parse different suffixes as a sum of elements" do
    Timecode.parse("1h 4f").to_s.should.equal '01:00:00:04'
    Timecode.parse("4f 1h").to_s.should.equal '01:00:00:04'
    Timecode.parse("29f 1h").to_s.should.equal '01:00:01:04'
  end
  
  specify "parse timecode with fractional second instead of frames" do
    fraction = "00:00:07.1"
    tc = Timecode.parse_with_fractional_seconds(fraction, 10)
    tc.to_s.should.equal "00:00:07:01"

    fraction = "00:00:07.5"
    tc = Timecode.parse_with_fractional_seconds(fraction, 10)
    tc.to_s.should.equal "00:00:07:05"
    
    fraction = "00:00:07.04"
    tc = Timecode.parse_with_fractional_seconds(fraction, 12.5)
    tc.to_s.should.equal "00:00:07:00"
    
    fraction = "00:00:07.16"
    tc = Timecode.parse_with_fractional_seconds(fraction, 12.5)
    tc.to_s.should.equal "00:00:07:02"
  end
  
  specify "raise on improper format" do
    lambda { Timecode.parse("Meaningless nonsense", 25) }.should.raise Timecode::CannotParse
    lambda { Timecode.parse("", 25) }.should.raise Timecode::CannotParse
  end
  
end

context "Timecode.soft_parse should" do
  
  specify "not raise on improper format and return zero TC instead" do
    lambda do
      tc = Timecode.soft_parse("Meaningless nonsense", 25)
      tc.should.be.zero?
    end.should.not.raise
  end
end

context "Timecode with unsigned integer conversions should" do
  
  specify "parse from an integer" do
    uint, tc = 87310853, Timecode.at(5,34,42,5)
    Timecode.from_uint(uint).should.equal tc
  end
  
  specify "should properly convert a timecode back to integer" do
    uint, tc = 87310853, Timecode.at(5,34,42,5)
    tc.to_uint.should.equal uint
  end
end