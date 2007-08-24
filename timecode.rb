# Timecode is a convenience object for calculating SMPTE timecode natively. It is used in
# various StoryTool models and templates, offers string output and is immutable.
# You can calculate in timecode objects ass well as with conventional integers and floats 
class Timecode
  include Comparable
  DEFAULT_FPS = 25
  
  def initialize(total = 0, fps = DEFAULT_FPS)
    if total.is_a?(String)
      parse(total)
    else
      raise WrongFramerate, "FPS cannot be zero" if fps == 0
      @fps = fps.to_f
      if (total.is_a?(String))
        parse(total)
      else
        raise RangeError, "Timecode cannot be negative" if total.to_f < 0
        @total = total.round 
      end
    end
    freeze
  end
    
  #parse timecode entered by the user
  def self.parse(aString, with_fps = 25)
    hrs, mins, secs, frames = 0,0,0,0
    m = []
    #try strictest parsing - 4 values after each other
    if (aString.length == 8)
      m = aString.scan /(\d{1,2})(\d{1,2})(\d{1,2})(\d{1,2})/   
    elsif (aString.scan /:/)
      m = aString.scan /(\d{1,2}):(\d{1,2}):(\d{1,2}):(\d{1,2})/
    end
    
    if m.length && m[0].is_a?(Array)
      hrs, mins, secs, frames = m[0].compact.collect! { |item| item.to_f}
    end
    
    if hrs > 99
      raise RangeError, "There can be no more than 99 hours, got #{hrs}"
    elsif mins > 59
      raise RangeError, "There can be no more than 59 minutes, got #{mins}"
    elsif secs > 59
      raise RangeError, "There can be no more than 59 seconds, got #{secs}"
    elsif frames > (with_fps -1)
      raise RangeError, "There can be no more than #{with_fps} frames @#{with_fps}, got #{frames}"
    end
    
    total = (hrs*(60*60*with_fps) +  mins*(60*with_fps) + secs*with_fps + frames).round
    new(total, with_fps)
  end
  
  def self.parse_with_fractional_seconds(tc_with_fractions_of_second, fps = DEFAULT_FPS)
    fraction_expr = /\.(\d+)$/
    fraction_part = ('.' + tc_with_fractions_of_second.scan(fraction_expr)[0][0]).to_f

    seconds_per_frame = 1.0 / fps.to_f
    frame_idx = (fraction_part / seconds_per_frame).floor

    tc_with_frameno = tc_with_fractions_of_second.gsub(fraction_expr, ":#{frame_idx}")

    parse(tc_with_frameno, fps)
  end
  
  def self.from_seconds(seconds_float, fps = DEFAULT_FPS)
    total_frames = (seconds_float.to_f * fps.to_f)
    new(total_frames, fps)
  end
  
  #convert TC to fixnum
  def to_f
    @total
  end
  
  #get total frame count
  def total
    to_f
  end
  
  #get FPS
  def fps
    @fps
  end
    
  #get the number of frames
  def frames
    _nudge[3]
  end
  
  #get the number of seconds
  def seconds
    _nudge[2]
  end
  
  #get the number of minutes
  def minutes
    _nudge[1]
  end
  
  #get the number of hours
  def hours
    _nudge[0]
  end
  
  #get frame interval in fractions of a second
  def frame_interval
    1.0/@fps
  end
  
  #convert to different FPS
  def convert(new_fps)
    raise NonPositiveFps, "FPS cannot be less than 0" if new_fps < 1
    Timecode.new((total/fps)*new_fps, new_fps)
  end
  
  #get formatted SMPTE timecode
  def to_s
    hours, mins, seconds, frames = _nudge
    sprintf("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
  end
  
  #get countable total frames
  def to_f
    @total
  end
  
  #add number of frames (or another timecode) to this one
  def +(arg)
    if (arg.is_a?(Timecode) && arg.fps == @fps)
      Timecode.new(@total+arg.total, @fps)
    elsif (arg.is_a?(Timecode))
      raise WrongFramerate, "You are calculating timecodes with different framerates"
    else
      Timecode.new(@total+arg, @fps)
    end
  end
  
  def -(arg)
    if (arg.is_a?(Timecode) &&  arg.fps == @fps)
      Timecode.new(@total-arg.total(), @fps)
    elsif (arg.is_a?(Timecode))
      raise WrongFramerate, "You are calculating timecodes with different framerates"
    else
      Timecode.new(@total-arg, @fps)
    end
  end
  
  def *(arg)
    raise RangeError, "Timecode multiplier cannot be negative" if (arg < 0)
    Timecode.new(@total*arg.to_f, @fps)
  end
  
  def /(arg)
    Timecode.new(@total/arg, @fps)
  end
    
  def <=>(other_tc)
    raise MethodRequiresTimecode, "You can compare timecodes with each other" if (!other_tc.is_a?(Timecode))
    other_tc = other_tc.convert(@fps) if (other_tc.fps != @fps)
    # reciever ON THE LEFT
    total <=> other_tc.total
  end

  private
  
  #dynamically splits TC
  #TC is traditionally a struct but it has no FPS information and needs 4 regs, wehreas TC is actually just 2 
  def _nudge
    frames = @total
    secs = (@total.to_f/@fps).floor
    frames-=(secs*@fps)
    mins = (secs/60).floor
    secs -= (mins*60)
    hrs = (mins/60).floor
    mins-= (hrs*60)
    
    raise RangeError, "More than 59 minutes" if mins > 59 
    raise RangeError, "More than 59 seconds" if secs > 59
    raise TimecodeLibError, "More than #{@fps.to_s} frames at #{@fps.to_s}" if frames > (@fps -1)
    raise RangeError, "Timecode cannot be longer that 99 hrs" if hrs > 99 
    
    [hrs, mins, secs, frames]
  end
  
  class TimecodeLibError < RangeError
  end
  
  class RangeError < RangeError
  end
  
  class NonPositiveFps < RangeError
  end
  
  class WrongFramerate < ArgumentError
  end
  
  class TcIsZero < ZeroDivisionError
  end
  
  class MethodRequiresTimecode < ArgumentError
  end
end

if $0 == __FILE__
  require 'timecode_test'
end

