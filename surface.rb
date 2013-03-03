#!/usr/bin/env ruby
module Hive
    class Surface < Array
        attr_accessor :walkable_bugs

        def first_bug; $game.white.each{|bug| return bug if bug.is_in_play? && bug.not_hidden? }; end
        def bug(color, id); $game.bugs[color].each{|bug| return bug if bug.id == id }; end

        def bugs_in_play?; self.list_bugs(true); end
        def bugs_not_in_play?; self.list_bugs(false); end
        def list_bugs(in_play)
            bugs = Array.new
            [White,Black].collect{|color|
                bugs[color] = $game.trays[color].map{|bug| bug = (bug.is_in_play? == in_play ? bug : nil)}
            }
            puts "\nBugs #{in_play ? '' : 'not'} in play: "
            bugs.flatten.compact.each{|bug| puts bug}
        end

        # Walk the game surface to see if there are any islands
        def walk
            @walkable_bugs = Array.new
            @walkable_bugs << self.first_bug
            self.first_bug.walk
            return @walkable_bugs
        end

        # Place a new bug on the board
        def +(bug, next_to = false, side = false)
            error = false
            return if bug == nil || $game.not_my_turn?(bug.color)
            begin
                raise HiveException, "White always starts first" if $game.turn_number == 1 && bug.color? == 'Black'
                    
                [White,Black].collect{|color|
                    if $game.bugs[color].count == 3 && $game.trays[color].queen.is_in_play? == false && bug.class.name != "Hive::Queen"
                        error = true
                        raise HiveException, "#{$game.turn?}, you have to place your queen by the 4th turn"
                    end
                }

                if $game.turn_number == 1
                    puts "#{$game.turn?} placed first #{bug}"
                elsif $game.turn_number == 2
                    puts self.first_bug.+(bug, TopCenter)
                elsif $game.turn_number >= 3
                    if next_to.respond_to?('sides') == false
                        error = true
                        raise HiveException, "#{$game.turn?}, you specified a next_to bug that isn't on the surface yet"
                    elsif self.place_candidates($game.turn).include?(next_to.sides[side])
                        puts next_to.+(bug, side)
                        Bug::announce(next_to, bug, side)
                    else
                        error = InvalidPlacement
                        raise HiveException, "#{$game.turn?}, you can't place #{bug} in the " + Side::name?(side) + " of #{next_to}"
                    end
                end
                
                if error == false
                    bug.is_in_play = true
                    $game.bugs[$game.turn] << bug
                    $game.next_turn
                end
            rescue HiveException => e
                abort(e.message) if e.message == 'White always starts first'
                puts e.message
                next_to.describe if next_to != false && error == InvalidPlacement
            end
        end

        # Get possible moves for bugs already on the surface
        def move_candidates(color)
            return if $game.not_my_turn?(color)
            puts "\n#{$game.turn?}, these are your possible moves:\n"
            moveable_bugs = Array.new
            $game.bugs[color].each{|bug|
                moveable_bugs << bug if bug.can_move?
            }
            puts moveable_bugs
            return moveable_bugs
        end

        # Get possible places to put new bugs on the surface
        def place_candidates(color)
            return if $game.not_my_turn?(color)
            echo = caller[0].include? 'play'
            open_sides = Array.new
            $game.bugs[color].each{|bug|
                bug.sides.each_with_index{|side, name|
                    if side.open?
                        test_bug = Hive::Tester.new(color)
                        Bug::announce(bug, test_bug, name)
                        open_sides << side if test_bug.legal_placement? || $game.turn_number == 2

                        def remove_test_bugs
                            [White,Black].collect.each{|color|
                                $game.bugs[color].each{|bug| 
                                    bug.sides.each{|side|
                                        side.bug = false if side.bug.class.name == 'Hive::Tester'
                                    }
                                    bug = false if bug.class.name == 'Hive::Tester'
                                }
                            }
                        end

                        self.remove_test_bugs
                    end
                }
            }
            return open_sides
        end
    end
end