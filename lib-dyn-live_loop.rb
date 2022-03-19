#######################
# lib-dyn-live_loop.rb
# author: Garen H.
# Library inspired by:
# https://in-thread.sonic-pi.net/t/programmatically-creating-live-loops-on-the-fly/1919/10
#######################

RUNSTATE_KEY = "ll_runstate_"
LIVE_LOOP_NAME_KEY = "ll_"

define :runLoop do |name, fn|
  loopsym = (RUNSTATE_KEY + name).to_sym
  set loopsym, true
  live_loop (LIVE_LOOP_NAME_KEY + name).to_sym do
    fn.call()
    stop if ! get(loopsym)
  end
end

define :stopLoop do |name|
  set (RUNSTATE_KEY + name).to_sym, false
end

