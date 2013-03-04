#!/usr/bin/env ruby
module Hive
    class Grasshopper
        include Bug

        # The grasshopper is the only bug who has a functional move_candidates method yet. Each bug has to have their own set of rules so they know whether a move they're told to do (whether it's from a person or from an AI player) is legal.
        def move_candidates            
            return nil if self.can_move? == false
            echo = caller[0].include? 'play'

            # Create an array to store move candidates
            @candidates = Array.new
            @sides.each{|side|
                # Iterate through all of our sides and pick a bug
                move_candidate = side.bug
                if move_candidate != false
                    # Here's an elegant way to model the grasshopper: UNTIL we no longer find another bug in this direction (for instance, top left, top left, top left, etc.) we keep going. The last bug in the chain is the move candidate.
                    until move_candidate.sides[side.id].bug == false do
                        move_candidate = move_candidate.sides[side.id].bug
                    end
                    # The echo variable is set if this method gets called from Hive::play, which probably means there is a person around who wants some feedback on the screen.
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