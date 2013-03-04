#!/usr/bin/env ruby
module Hive
    class Grasshopper
        include Bug

        def move_candidates            
            return nil if self.can_move? == false
            echo = caller[0].include? 'play'

            @candidates = Array.new
            @sides.each{|side|
                move_candidate = side.bug
                if move_candidate != false
                    until move_candidate.sides[side.id].bug == false do
                        move_candidate = move_candidate.sides[side.id].bug
                    end
                    if echo
                        puts "#{$game.turn?}, you can move " + self + " to the " + Side::name?(side.id) + " of " +move_candidate.to_s
                    else
                        @candidates << move_candidate.sides[side.id]
                    end
                end
            }
            return @candidates
        end
    end
end