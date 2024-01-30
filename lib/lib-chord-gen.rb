#######################
# lib-chord-gen.rb
# Generate chord sequence of any degrees for a tonic/mode combination
# author: Garen H.
#######################

eval_file get(:sp_path)+"sonic-stage-lib/lib-modes.rb" #include modes patch library for extended modes/scales/chords

# chordSeq - returns chord sequence of specified degrees (degs) within mode for specified tonic
# seven - seventh chord (default = true)
# rootless - exclude tonic (default = true)
define :chord_seq do |tonic, mode, degs, seven=false, rootless=false|
    return degs if degs == nil
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

# Returns corresponding local octave note for the tonic
# e.g. if note=F5 (or note=F3) and tonic=C4, returns F4
define :note_to_octave do |note, tonic|
    local_note = tonic + (note - tonic) % 12
end

# True if note is in scale, otherwise false
define :note_in_scale do |note, mode, tonic|
    scale_notes = scale tonic, mode
    scale_notes.to_a.include? note_to_octave(note, tonic)
end

# True if all notes are in scale, otherwise false
define :notes_in_scale do |notes, mode, tonic|
    scale_notes = scale tonic, mode
    in_scale = true
    for note in notes
        in_scale = note_in_scale(note, mode, tonic)
        break if !in_scale
    end
    return in_scale
end

# True if all notes are in scale, otherwise false
#define :notes_in_scale do |notes, mode, tonic|
#    scale_notes = scale tonic, mode
#    puts "NOTES", notes
#    puts "SCALE", scale_notes
#    (notes - scale_notes).empty?
#end

# following two methods are converting note midi numbers to names
# based on this original idea: https://in-thread.sonic-pi.net/t/midi-number-to-note-name-debuging/3335/3
define :note_to_name do |n|
    note_info(n).to_s.split(" ")[1][1..-2]
end
  
define :notes_to_names do |list|
    list.map {|x| note_to_name(x)}
end
  