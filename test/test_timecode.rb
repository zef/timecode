require 'test/unit'
require File.dirname(__FILE__) + '/../lib/timecode'


class TimecodeTest < Test::Unit::TestCase
  
  def test_timecode_with_nil_gives_zero
    assert_equal Timecode.new(0), Timecode.new(nil)
  end
  
  def test_fps_always_coerced_to_float
    t = Timecode.new(10, 25)
    assert_kind_of Float, t.fps

    t = Timecode.new(10, 25.0)
    assert_kind_of Float, t.fps
  end
  
  def test_framerate_in_delta
    tc = Timecode.new(1)
    assert tc.framerate_in_delta(25.0000000000000001, 25.0000000000000003)
  end

  def test_equality_validated_based_on_deltas
    t1, t2 = Timecode.new(10, 25.0000000000000000000000000001), Timecode.new(10, 25.0000000000000000000000000002)
    assert t1 == t2
  end
  
  def test_to_i_is_total
    assert_equal 10, Timecode.new(10).to_i
  end
  
  def test_inspect
    tc = Timecode.new(10, 25)
    assert_equal "#<Timecode:00:00:00:10 (10F@25.00)>", tc.inspect
  end
  
  def test_equality_on_succ
    assert_equal Timecode.parse("05:43:02:01"), Timecode.parse("05:43:02:00").succ 
  end
  
  def test_basics
    five_seconds_of_pal = 5 * 25

    tc = Timecode.new(five_seconds_of_pal, 25)
    assert_equal 0, tc.hours
    assert_equal 0, tc.minutes
    assert_equal 5, tc.seconds
    assert_equal 0, tc.frames
    assert_equal five_seconds_of_pal, tc.total
    assert_equal "00:00:05:00", tc.to_s
    
    one_and_a_half_hour_of_hollywood = (90 * 60) * 24

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
    
    two_seconds_and_five_frames_of_pal = ((2 * 25) + 5)
    pal_tc = Timecode.new(two_seconds_and_five_frames_of_pal, 25)
    assert_nothing_raised do
      added_tc = pal_tc + tc
      assert_equal "00:00:07:05", added_tc.to_s
    end

  end
  
  def test_succ
    assert_equal Timecode.new(23), Timecode.new(22).succ
  end
  
  def test_zero
    assert Timecode.new(0).zero?
    assert Timecode.parse("00:00:00:00").zero?
    assert !Timecode.new(1).zero?
    assert !Timecode.new(1000).zero?
  end
  
  def test_timecode_rangeable
    r = Timecode.new(10)...Timecode.new(20)
    assert_equal 10, r.to_a.length
    assert_equal Timecode.new(14), r.to_a[4]
  end
  
  def test_frame_interval
    tc = Timecode.new(10)
    assert_in_delta tc.frame_interval, 0.04, 0.0001

    tc = Timecode.new(10, 30)
    assert_in_delta tc.frame_interval, 0.03333, 0.0001
  end
end

class ConversionTest < Test::Unit::TestCase
  def test_convert_25_at_24
    tc = Timecode.new(40, 25)
    at24 = tc.convert(24)
    assert_equal tc.total, at24.total
  end
end

class CalculationsTest < Test::Unit::TestCase
  def test_plus
    a, b = Timecode.new(24, 25.000000000000001), Timecode.new(22, 25.000000000000002)
    assert_equal Timecode.new(24 + 22, 25.000000000000001), (a + b)
  end
  
  def test_plus_with_different_framerates_should_raise
    assert_raise(Timecode::WrongFramerate) { Timecode.new(10, 25) + Timecode.new(10, 30) }
  end

  def test_plus_with_int_gives_a_timecode
    assert_equal Timecode.new(10), Timecode.new(5) + 5
  end
  
  def test_min
    a, b = Timecode.new(10), Timecode.new(4)
    assert_equal Timecode.new(6), a - b
  end

  def test_min_with_int_gives_a_timecode
    assert_equal Timecode.new(10), Timecode.new(15) - 5
  end

  def test_min_with_different_framerates_should_raise
    assert_raise(Timecode::WrongFramerate) { Timecode.new(10, 25) - Timecode.new(10, 30) }
  end
  
  def test_mult
    assert_equal Timecode.new(100), Timecode.new(10) * 10
  end
  
  def test_mult_by_neg_number_should_raise
    assert_raise(Timecode::RangeError) { Timecode.new(10) * -200 }
  end
  
  def test_div_by_int_gives_a_timecode
    v = Timecode.new(200) / 20
    assert_kind_of Timecode, v
    assert_equal Timecode.new(10), v
  end

  def test_div_by_timecode_gives_an_int
    v = Timecode.new(200) / Timecode.new(20)
    assert_kind_of Numeric, v
    assert_equal 10, v
  end
  
  def test_tc_with_frames_as_fraction
    tc = Timecode.new(100 -1, fps = 25)
    assert_equal 24, tc.frames
    assert_equal "00:00:03.96", tc.with_frames_as_fraction
    assert_equal "00:00:03.96", tc.with_fractional_seconds
  end
  
  def test_float_framerate
    tc = Timecode.new(25, 12.5)
    assert_equal "00:00:02:00", tc.to_s
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

class TestAt < Test::Unit::TestCase
  
  def test_at_disallows_more_than_99_hrs
    assert_nothing_raised { Timecode.at(99,0,0,0) }
    assert_raise(Timecode::RangeError) { Timecode.at(100,0,0,0) }
  end

  def test_at_disallows_more_than_59_mins
    assert_raise(Timecode::RangeError) { Timecode.at(1,60,0,0) }
  end

  def test_at_disallows_more_than_59_secs
    assert_raise(Timecode::RangeError) { Timecode.at(1,0,60,0) }
  end

  def test_at_disallows_more_frames_than_framerate
    assert_raise(Timecode::RangeError) { Timecode.at(1,0,60,25, 25) }
    assert_raise(Timecode::RangeError) { Timecode.at(1,0,60,32, 30) }
  end

end

class TestParsing < Test::Unit::TestCase

  def test_parse_simple
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
  
  def test_parse_from_numbers
    assert_equal Timecode.new(10), Timecode.parse("10")
    assert_equal Timecode.new(60), Timecode.parse("210")
    assert_equal "10:10:10:10", Timecode.parse("10101010").to_s
  end
  
  def test_parse_with_f
    assert_equal Timecode.new(60), Timecode.parse("60f")
  end
  
  def test_parse_s
    assert_equal Timecode.new(50, 25), Timecode.parse("2s", 25)
    assert_equal Timecode.new(60, 30), Timecode.parse("2s", 30)
    assert_not_equal Timecode.new(60, 25), Timecode.parse("2s", 30)
  end

  def test_parse_m
    assert_equal Timecode.new(25 * 60 * 3), Timecode.parse("3m")
  end

  def test_parse_h
    assert_equal Timecode.new(25 * 60 * 60 * 3), Timecode.parse("3h")
  end
  
  def test_parse_from_elements
    assert_equal '01:00:00:04', Timecode.parse("1h 4f").to_s
    assert_equal '01:00:00:04', Timecode.parse("4f 1h").to_s
    assert_equal '01:00:01:04', Timecode.parse("29f 1h").to_s
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
  
# def test_parse_with_calculation
#   tc = Timecode.parse_with_calculation("00:00:00:15 +2f")
#   assert_equal Timecode.new(17), tc
# end
  
  def test_soft_parse_does_not_raise_and_createz_zeroed_tc
    assert_nothing_raised do 
      tc = Timecode.soft_parse("Meaningless nonsense", 25)
      assert tc.zero?
    end
  end
  
  def test_parse_raoses_on_improper_format
    assert_raise(Timecode::CannotParse) { Timecode.parse("Meaningless nonsense", 25) }
    assert_raise(Timecode::CannotParse) { Timecode.parse("", 25) }
  end
end

class TestUintConversion < Test::Unit::TestCase
  def test_from_uint
    uint, tc = 87310853, Timecode.at(5,34,42,5)
    assert_equal tc, Timecode.from_uint(uint)
  end
  
  def test_to_uint
    uint, tc = 87310853, Timecode.at(5,34,42,5)
    assert_equal uint, tc.to_uint
  end
end