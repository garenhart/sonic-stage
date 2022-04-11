#######################
# lib-chord-gen.rb
# Generate chord sequence of any degrees for a tonic/mode combination
# author: Garen H.
#######################

eval_file get(:sp_path)+"lib/lib-modes.rb" #include modes patch library for extended modes/scales/chords

# chordSeq - returns chord sequence of specified degrees (degs) within mode for specified tonic
# seven - seventh chord (default = true)
# rootless - exclude tonic (default = true)
define :chord_seq do |tonic, mode, degs, seven=false, rootless=false|
    cords = []
    lookup = scale(tonic, mode, num_octaves: 2)

    degs.each {|deg|
        lu = lookup.rotate(deg-1)
        # construct triad or seventh chord based on values of "seven" and "rootless"
        theChord = rootless ? [] : [lu[0]] 
        theChord.push lu[2]
        theChord.push lu[4]
        theChord.push lu[6] if seven
        cords.append theChord
    }
    cords
end

define :mode_scale do |mode, scale|
    m = 0
    m_scale = 0
    ModeScales = Modes.mode_scales
    case mode
    when 0 #major modes
        m = :major
    when 1 # melodic minor mode
        m = :melodic_minor
    when 2 # harmonic minor mode
        m = :harmonic_minor
    when 3 # melodic minor mode
        m = :harmonic_major
    end
    m_scale = ModeScales[m][scale]
    # puts m_scale
end

