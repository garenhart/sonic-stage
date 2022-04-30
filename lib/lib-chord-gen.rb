#######################
# lib-chord-gen.rb
# Generate chord sequence of any degrees for a tonic/mode combination
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

eval_file get(:sp_path)+"lib/lib-modes.rb" #include modes patch library for extended modes/scales/chords

# chordSeq - returns chord sequence of specified degrees (degs) within mode for specified tonic
# seven - seventh chord (default = true)
# rootless - exclude tonic (default = true)
define :gl_chord_seq do |tonic, mode, degs, seven=false, rootless=false|
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

define :gl_notes_in_scale do |notes, mode, key|
    scale_notes = scale key, mode
    puts "NOTES", notes
    puts "SCALE", scale_notes
    (notes-scale_notes).empty?
end

# following two methods are converting note midi numbers to names
# based on this original idea: https://in-thread.sonic-pi.net/t/midi-number-to-note-name-debuging/3335/3
define :gl_note_to_name do |n|
    note_info(n).to_s.split(" ")[1][1..-2]
end
  
define :gl_notes_to_names do |list|
    list.map {|x| gl_note_to_name(x)}
end
  