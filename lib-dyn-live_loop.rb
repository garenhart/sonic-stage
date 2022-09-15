#######################
# lib-dyn-live_loop.rb
# Library inspired by:
# https://in-thread.sonic-pi.net/t/programmatically-creating-live-loops-on-the-fly/1919/10
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

RUNSTATE_KEY = "ll_runstate_"
LIVE_LOOP_NAME_KEY = "ll_"

define :gl_runLoop do |name, fn|
  loopsym = (RUNSTATE_KEY + name).to_sym
  set loopsym, true
  live_loop (LIVE_LOOP_NAME_KEY + name).to_sym do
    fn.call()
    stop if ! get(loopsym)
  end
end

define :gl_stopLoop do |name|
  set (RUNSTATE_KEY + name).to_sym, false
end

