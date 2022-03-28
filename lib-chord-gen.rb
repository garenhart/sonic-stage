#######################
# lib-chord-gen.rb
# Generate chord sequence of any degrees for a tonic/mode combination
# author: Garen H.
#######################

eval_file get(:sp_path)+"lib/lib-modes.rb" #include modes patch library for extended modes/scales/chords

# chordSeq - returns chord sequence of specified degrees (degs) within mode for specified tonic
# seven - seventh chord (default = true)
# rootless - exclude tonic (default = true)
define :chordSeq do |tonic, mode, degs, seven=true, rootless=true|
    cords = []
    lookup = scale(tonic, mode, num_octaves: 2)

    degs.each {|deg|
        lu = lookup.rotate(deg-1)
        # construct triad or seventh chord based on values of "seven" and "rootless"
        theChord = rootless ? [] : [lu[0]] 
        theChord.push lu[2]
        theChord.push lu[4]
        theChord.push lu[6] if seven
        #theChord = seven ? [lu[0], lu[2], lu[4], lu[6]] : [lu[0], lu[2], lu[4]]
        cords.append theChord
    }
    cords
  end
