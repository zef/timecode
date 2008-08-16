require 'test/unit'
require 'rubygems'
require 'timecode'

# for Fixnum#hours
require 'active_support'

class TimecodeTest < Test::Unit::TestCase
  
  def test_basics
    five_seconds_of_pal = 5.seconds * 25
    tc = Timecode.new(five_seconds_of_pal, 25)
    assert_equal 0, tc.hours
    assert_equal 0, tc.minutes
    assert_equal 5, tc.seconds
    assert_equal 0, tc.frames
    assert_equal five_seconds_of_pal, tc.total
    assert_equal "00:00:05:00", tc.to_s
    
    one_and_a_half_hour_of_hollywood = 90.minutes * 24

    film_tc = Timecode.new(one_and_a_half_hour_of_hollywood, 24)
    assert_equal 1, film_tc.hours
    assert_equal 30, film_tc.minutes
    assert_equal 0, film_tc.seconds
    assert_equal 0, film_tc.frames
    assert_equal one_and_a_half_hour_of_hollywood, film_tc.total
    assert_equal "01:30:00:00", film_tc.to_s

    assert_equal "01:30:00:04", (film_tc + 4).to_s
    assert_equal "01:30:01:04", (film_tc + 28).to_s

    assert_raise(Timecode::WrongFramerate) do
      tc + film_tc
    end
    
    two_seconds_and_five_frames_of_pal = ((2.seconds * 25) + 5)
    pal_tc = Timecode.new(two_seconds_and_five_frames_of_pal, 25)
    assert_nothing_raised do
      added_tc = pal_tc + tc
      assert_equal "00:00:07:05", added_tc.to_s
    end

  end
    
  def test_parse
    simple_tc = "00:10:34:10"
    
    assert_nothing_raised do
      @tc = Timecode.parse(simple_tc)
      assert_equal simple_tc, @tc.to_s
    end
  
    bad_tc = "00:76:89:30"
    unknown_gobbledygook = "this is insane"
    
    assert_raise(Timecode::CannotParse) do
      tc = Timecode.parse(unknown_gobbledygook, 25)
    end
    
    assert_raise(Timecode::RangeError) do
      Timecode.parse(bad_tc, 25)
    end
  end
  
  def test_zero
    assert Timecode.new(0).zero?
    assert !Timecode.new(1).zero?
    assert !Timecode.new(1000).zero?
  end
  
  def test_parse_from_numbers
    assert_equal Timecode.new(10), Timecode.parse("10")
    assert_equal Timecode.new(60), Timecode.parse("210")
    assert_equal "10:10:10:10", Timecode.parse("10101010").to_s
  end
  
  def test_parse_with_f
    assert_equal Timecode.new(60), Timecode.parse("60f")
  end
  
  def test_parse_s
    assert_equal Timecode.new(50), Timecode.parse("2s")
  end

  def test_parse_m
    assert_equal Timecode.new(25 * 60 * 3), Timecode.parse("3m")
  end

  def test_parse_h
    assert_equal Timecode.new(25 * 60 * 60 * 3), Timecode.parse("3h")
  end
  
  def test_parse_block
    assert_equal '01:00:00:04', Timecode.parse("1h 4f").to_s
    assert_equal '01:00:00:04', Timecode.parse("4f 1h").to_s
    assert_equal '01:00:01:04', Timecode.parse("29f 1h").to_s
  end
  
  def test_float_framerate
    tc = Timecode.new(25, 12.5)
    assert_equal "00:00:02:00", tc.to_s
  end
  
  def test_timecode_with_nil_gives_zero
    assert_equal Timecode.new(0), Timecode.new(nil)
  end
  
  def test_parse_fractional_tc
    fraction = "00:00:07.1"
    tc = Timecode.parse_with_fractional_seconds(fraction, 10)
    assert_equal "00:00:07:01", tc.to_s

    fraction = "00:00:07.5"
    tc = Timecode.parse_with_fractional_seconds(fraction, 10)
    assert_equal "00:00:07:05", tc.to_s
    
    fraction = "00:00:07.04"
    tc = Timecode.parse_with_fractional_seconds(fraction, 12.5)
    assert_equal "00:00:07:00", tc.to_s
    
    fraction = "00:00:07.16"
    tc = Timecode.parse_with_fractional_seconds(fraction, 12.5)
    assert_equal "00:00:07:02", tc.to_s
  end
  
  def test_parse_with_calculation
    tc = Timecode.parse_with_calculation("00:00:00:15 +2f")
    assert_equal Timecode.new(17), tc
  end
  
  def test_from_seconds
    fraction = 7.1
    tc = Timecode.from_seconds(fraction, 10)
    assert_equal "00:00:07:01", tc.to_s

    fraction = 7.5
    tc = Timecode.from_seconds(fraction, 10)
    assert_equal "00:00:07:05", tc.to_s

    fraction = 7.16
    tc = Timecode.from_seconds(fraction, 12.5)
    assert_equal "00:00:07:02", tc.to_s
  end
end
