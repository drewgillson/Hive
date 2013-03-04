#!/usr/bin/env ruby
module Hive
    class Queen
        include Bug

        def move; end

        # If the queen is surrounded, the game is over.
        def is_surrounded?; @sides.each{|side| return false if side.bug == false}; end
    end
end