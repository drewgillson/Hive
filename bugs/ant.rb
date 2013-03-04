#!/usr/bin/env ruby
module Hive
    class Ant
        include Bug

        def move_candidates            
            return nil if self.can_move? == false
            echo = caller[0].include? 'play'

            @candidates = $game.surface.walk(look_for_sides = true)
            return @candidates
        end

    end
end