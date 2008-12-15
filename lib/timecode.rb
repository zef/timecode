# Timecode is a convenience object for calculating SMPTE timecode natively. It is used in
# various StoryTool models and templates, offers string output and is immutable.
#
# The promise is that you only have to store two values to know the timecode - the amount
# of frames and the framerate. An additional perk might be to save the dropframeness,
# but we avoid that at this point.
#
# You can calculate in timecode objects ass well as with conventional integers and floats.
# Timecode is immutable and can be used as a value object. Timecode objects are sortable.
#
# Here's how to use it with ActiveRecord (your column names will be source_tc_frames_total and tape_fps)
#
#   composed_of :source_tc, :class_name => 'Timecode',
#     :mapping => [%w(source_tc_frames total), %w(tape_fps fps)]

class Timecode
  VERSION = '0.1.0'

  include Comparable
  DEFAULT_FPS = 25
  COMPLETE_TC_RE = /^(\d{1,2}):(\d{1,2}):(\d{1,2}):(\d{1,2})$/
  
  # All Timecode lib errors inherit from this
  class Error < RuntimeError; end
  
  # Will be raised for functions that are not supported
  class TimecodeLibError < Error; end

  # Gets raised if timecode is out of range (like 100 hours long)
  class RangeError < Error; end

  # Self-explanatory
  class NonPositiveFps < RangeError; end

  # Gets raised when float frame count is passed
  class FrameIsWhole < RangeError; end

  # Gets raised when you divide by zero
  class TcIsZero < ZeroDivisionError; end

  # Gets raised when a timecode cannot be parsed
  class CannotParse < Error; end

  # Gets raised when you try to compute two timecodes with different framerates together
  class WrongFramerate < ArgumentError; end

  # Well well...
  class MethodRequiresTimecode < ArgumentError; end
  
  # Initialize a new Timecode. If a string is passed, it will be parsed, an integer
  # will be interpreted as the total number of frames
  def self.new(total_or_string = 0, fps = DEFAULT_FPS)
    if total_or_string.nil?
      new(0, fps)
    elsif total_or_string.is_a?(String)
      parse(total_or_string, fps)
    else
      super(total_or_string, fps)
    end
  end
  
  def initialize(total = 0, fps = DEFAULT_FPS) # :nodoc:
    if total.is_a?(Float)
      raise FrameIsWhole, "the number of frames cannot be partial (Integer value needed)"
    end
    
    raise RangeError, "Timecode cannot be negative" if total.to_f < 0
    raise WrongFramerate, "FPS cannot be zero" if fps.zero?
    @total, @fps = total, fps 
    @value = validate!
    freeze
  end
  
  def inspect # :nodoc:
    super.gsub(/@fps/, self.to_s + ' @fps').gsub(/ @value=\[(.+)\],/, '')
  end
  
  class << self
    
    # Parse timecode and return zero if none matched
    def soft_parse(input, with_fps = DEFAULT_FPS)
      parse(input) rescue new(0, with_fps)
    end
      
    # Parse timecode entered by the user. Will raise if the string cannot be parsed.
    def parse(input, with_fps = DEFAULT_FPS)
      # Drop frame goodbye
      raise TimecodeLibError, "We do not support drop frame" if (input =~ /\;/)
      
      hrs, mins, secs, frames = 0,0,0,0
      atoms = []
      
      # 10h 20m 10s 1f
      if input =~ /\s/
        return input.split.map{|part|  parse(part, with_fps) }.inject { |sum, p| sum + p.total }
      # 10s
      elsif input =~ /^(\d+)s$/
        return new(input.to_i * with_fps, with_fps)
      # 10h
      elsif input =~ /^(\d+)h$/i
        return new(input.to_i * 60 * 60 * with_fps, with_fps)
      # 20m
      elsif input =~ /^(\d+)m$/i
        return new(input.to_i * 60 * with_fps, with_fps)
      # 60f - 60 frames, or 2 seconds and 10 frames
      elsif input =~ /^(\d+)f$/i
        return new(input.to_i, with_fps)
      # A bunch of integers
      elsif (input =~ /^(\d+)$/)
        ints = input.split(//)
        atoms.unshift [ints.pop, ints.pop].reverse.join.to_i
        atoms.unshift [ints.pop, ints.pop].reverse.join.to_i
        atoms.unshift [ints.pop, ints.pop].reverse.join.to_i
        atoms.unshift [ints.pop, ints.pop].reverse.join.to_i
      elsif (input =~ COMPLETE_TC_RE)
        atoms = input.scan(COMPLETE_TC_RE).to_a.flatten
      else
        raise CannotParse, "Cannot parse #{input} into timecode, no match"
      end
      
      if atoms.any?
        hrs, mins, secs, frames = atoms.map{|e| e.to_i}
      else
        raise CannotParse, "Cannot parse #{input} into timecode, atoms were empty"
      end
      
      at(hrs, mins, secs, frames, with_fps)
    end
    
    # Initialize a Timecode object at this specfic timecode
    def at(hrs, mins, secs, frames, with_fps = DEFAULT_FPS)
      case true
        when hrs > 99
          raise RangeError, "There can be no more than 99 hours, got #{hrs}"
        when mins > 59
          raise RangeError, "There can be no more than 59 minutes, got #{mins}"
        when secs > 59
          raise RangeError, "There can be no more than 59 seconds, got #{secs}"
        when frames > (with_fps -1)
          raise RangeError, "There can be no more than #{with_fps -1} frames @#{with_fps}, got #{frames}"
      end
    
      total = (hrs*(60*60*with_fps) +  mins*(60*with_fps) + secs*with_fps + frames).round
      new(total, with_fps)
    end
    
    def parse_with_fractional_seconds(tc_with_fractions_of_second, fps = DEFAULT_FPS)
      fraction_expr = /\.(\d+)$/
      fraction_part = ('.' + tc_with_fractions_of_second.scan(fraction_expr)[0][0]).to_f

      seconds_per_frame = 1.0 / fps.to_f
      frame_idx = (fraction_part / seconds_per_frame).floor

      tc_with_frameno = tc_with_fractions_of_second.gsub(fraction_expr, ":#{frame_idx}")

      parse(tc_with_frameno, fps)
    end
  
    # create a timecode from seconds. Seconds can be float (this is how current time is supplied by
    # QuickTime and other systems which have non-frame-based timescales)
    def from_seconds(seconds_float, the_fps = DEFAULT_FPS)
      total_frames = (seconds_float.to_f * the_fps.to_f).ceil
      new(total_frames, the_fps)
    end
  end
  
  # is the timecode at 00:00:00:00
  def zero?
    @total.zero?
  end
  
  # get total frame count
  def total
    to_f
  end
  
  #get FPS
  def fps
    @fps
  end
    
  # get the number of frames
  def frames
    value_parts[3]
  end
  
  # get the number of seconds
  def seconds
    value_parts[2]
  end
  
  # get the number of minutes
  def minutes
    value_parts[1]
  end
  
  # get the number of hours
  def hours
    value_parts[0]
  end
  
  # get frame interval in fractions of a second
  def frame_interval
    1.0/@fps
  end
  
  # Convert to different framerate based on the total frames. Therefore,
  # 1 second of PAL video will convert to 25 frames of NTSC (this 
  # is suitable for PAL to film TC conversions and back).
  # It does not account for pulldown or anything in that sense, because
  # then you need to think about cadences and such
  def convert(new_fps)
    raise NonPositiveFps, "FPS cannot be less than 0" if new_fps < 1
    self.class.new((total/fps)*new_fps, new_fps)
  end
  
  # get formatted SMPTE timecode
  def to_s
    "%02d:%02d:%02d:%02d" % value_parts
  end
  
  # get total frames as float
  def to_f
    @total
  end

  # get total frames as integer
  def to_i
    @total
  end
  
  # add number of frames (or another timecode) to this one
  def +(arg)
    if (arg.is_a?(Timecode) && arg.fps == @fps)
      Timecode.new(@total+arg.total, @fps)
    elsif (arg.is_a?(Timecode))
      raise WrongFramerate, "You are calculating timecodes with different framerates"
    else
      Timecode.new(@total + arg, @fps)
    end
  end
  
  # Subtract a number of frames
  def -(arg)
    if (arg.is_a?(Timecode) &&  arg.fps == @fps)
      Timecode.new(@total-arg.total, @fps)
    elsif (arg.is_a?(Timecode))
      raise WrongFramerate, "You are calculating timecodes with different framerates"
    else
      Timecode.new(@total-arg, @fps)
    end
  end
  
  # Multiply the timecode by a number
  def *(arg)
    raise RangeError, "Timecode multiplier cannot be negative" if (arg < 0)
    Timecode.new(@total*arg.to_i, @fps)
  end
  
  # Get the next frame
  def succ
    self.class.new(@total + 1)
  end
  
  # Slice the timespan in pieces
  def /(arg)
    Timecode.new(@total/arg, @fps)
  end
  
  # Timecodes can be compared to each other
  def <=>(other_tc)
    if other_tc.is_a?(Timecode)
      self.total <=> other_tc.class.new(other_tc.total, self.fps).total
    else
      self.total <=> other_tc
    end
  end

  private
  
  # Formats the actual timecode output from the number of frames
  def validate!
    frames = @total
    secs = (@total.to_f/@fps).floor
    frames-=(secs*@fps)
    mins = (secs/60).floor
    secs -= (mins*60)
    hrs = (mins/60).floor
    mins-= (hrs*60)
  
    raise RangeError, "Timecode cannot be longer that 99 hrs" if hrs > 99 
    raise RangeError, "More than 59 minutes" if mins > 59 
    raise RangeError, "More than 59 seconds" if secs > 59
    raise TimecodeLibError, "More than #{@fps.to_s} frames (#{frames}) in the last second" if frames >= @fps
  
    [hrs, mins, secs, frames]
  end
  
  def value_parts
    @value ||= validate!
  end
  
end