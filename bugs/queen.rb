#!/usr/bin/env ruby
module Hive
    class Queen
        include Bug

        def move; end

        def is_surrounded?; @sides.each{|side| return false if side.bug == false}; end
    end
end