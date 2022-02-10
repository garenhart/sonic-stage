#extra-modes.rb

  class CustomScale
    
    def initialize(tonic, name, num_octaves=1)
      if name.is_a?(Array)
        intervals = name
        name = :custom
      else
        name = name.to_sym
        intervals = SCALE[name]
      end
      raise InvalidScaleError, "Unknown scale name: #{name.inspect}" unless intervals
      intervals = intervals * num_octaves
      current = SonicPi::Note.resolve_midi_note(tonic)
      res = [current]
      intervals.each do |i|
        current += i
        res << current
      end
  
      @name = name
      @tonic = tonic
      @num_octaves = num_octaves
      @notes = res
      super(res)
    end
  
  end
