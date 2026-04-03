#######################
# lib-defaults.rb
# defaults library
# author: Garen H.
#######################

define :ensure_defaults do |data|
    default_adsr = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    default_fx = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]

    [['solo'], ['bass'], ['chord'],
     ['drums', 'kick'], ['drums', 'snare'], ['drums', 'cymbal']].each do |path|
        node = path.reduce(data) { |h, k| h[k] }
        node['adsr'] ||= default_adsr.dup
        node['fx'] ||= default_fx.map(&:dup)
    end
    data
end


