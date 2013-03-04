#!/usr/bin/env ruby
module Hive
    class Surface < Array
        attr_accessor :walkable_bugs, :open_sides

        # Every time a bug wants to move, it has to check to see if its move would break the game surface. This method 'walks' the game surface to see if there would be any stranded pieces or islands if the bug that wants to move disappeared. If look_for_sides is passed as true, this method will also return the open sides of the game surface, so the Hive::Ant or other bug classes can determine potential moves.
        def walk(look_for_sides = false)
            
            # This is a really funky way of doing variable assignment in Ruby. You can do something like this: a, b, c = 1, 2, 3  and have a = 1, b = 2, and c = 3
            @walkable_bugs, @open_sides = Array.new, Array.new

            @walkable_bugs << self.first_bug
            @open_sides << self.first_bug.sides if look_for_sides
            
            # This is a great example of recursion. Each bug walks and gets triggered by the bug before it. See the walk method of the Bug class. That's what is getting called below. We start with the first bug and expect to touch every bug on the board. If the count of bugs we touched doesn't match the count of pieces that are in play, we have an island.
            self.first_bug.walk(look_for_sides)

            # Either return the available sides, or the bug objects, depending on the caller.
            return look_for_sides ? @open_sides : @walkable_bugs
        end

        # The + method places a new bug on the game surface. This is the messiest method in the game so far and I'd like to refactor it. Do you see why? It's hard to understand, it tries to do too many things, and it's hard to read.
        def +(bug, next_to = false, side = false)
            
            error = false
            return if bug == nil || $game.not_my_turn?(bug.color)
            
            begin
                raise HiveException, "White always starts first" if $game.turn_number == 1 && bug.color? == 'Black'
                    
                # Throw an error if the queens aren't out by the fourth turn
                [Hive::Color[:white],Hive::Color[:black]].collect{|color|
                    if $game.bugs[color].count == 3 && $game.trays[color].queen.is_in_play? == false && bug.class.name != "Hive::Queen"
                        error = true
                        raise HiveException, "#{$game.turn?}, you have to place your queen by the 4th turn"
                    end
                }

                if $game.turn_number == 1
                    puts "#{$game.turn?} placed first #{bug}"

                elsif $game.turn_number == 2
                    # Force the second black bug placed to be in the top center of the white bug. This was easiest.
                    puts self.first_bug.+(bug, Side::Face[:top_center])

                elsif $game.turn_number >= 3

                    # Throw an error if you're trying to put a new bug next to a non-existent bug.
                    if next_to.respond_to?('sides') == false
                        error = true
                        raise HiveException, "#{$game.turn?}, you specified a next_to bug that isn't on the surface yet"
                    
                    # This is a really important one-liner. I get the available spots to put a new bug - the "place candidates" - and if the specific side of the bug we specified we wanted to put the new bug next to is included in that list, then continue.
                    elsif self.place_candidates($game.turn).include?(next_to.sides[side])
                        # Notify the next_to variable (which is a Bug object of some kind) that there is a new bug on it's side
                        puts next_to.+(bug, side)
                        # And also announce to all next_to's neighbors that there's a new bug in the hizzy:
                        Bug::announce(next_to, bug, side)
                        # Notice this is a "static method" or "class method" because I've used :: instead of . to separate the name of the class and the name of the method. I chose to use a static method because it's more of a helper - it's a utility. The real important parts are the next_to and the bug variables. I could have written next_to.announce(next_to, bug, side), but I think the first way is easier to understand.
                    
                    else
                        error = Hive::HiveException[:InvalidPlacement]
                        raise HiveException, "#{$game.turn?}, you can't place #{bug} in the " + Side::name?(side) + " of #{next_to}"
                    end
                end
                
                if error == false
                    # If there were no errors put this bug into the $game.bugs array that holds bugs that are on the game surface, and advance the turn.
                    bug.is_in_play = true
                    $game.bugs[$game.turn] << bug
                    $game.next_turn
                end
            rescue HiveException => e
                abort(e.message) if e.message == 'White always starts first'
                puts e.message
                next_to.describe if next_to != false && error == Hive::HiveException[:InvalidPlacement]
            end
        end

        # Get all possible moves for bugs already on the game surface by iterating through each bug and seeing if its can_move? method returns true. The neat thing here is that can_move? will differ depending on the rules for the bug, so Hive really is a great game to illustrate object-oriented programming concepts like polymorphism.
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

        # Get all possible places that we can put new bugs on the game surface for a given color. What we do is create a "tester bug" that we put next to every single open side, and then we use the legal_placement? method of the Hive::Tester class to tell us if it is touching a color other than its own.
        def place_candidates(color)
            return if $game.not_my_turn?(color)

            open_sides = Array.new

            $game.bugs[color].each{|bug|
                bug.sides.each{|side|

                    if side.open? # There's not another bug here already                        
                        test_bug = Hive::Tester.new(color)
                        Bug::announce(bug, test_bug, side.id)
                        
                        # If the instance of the Hive::Tester class passes the test, stuff the Hive::Side object into the open_sides array.
                        open_sides << side if test_bug.legal_placement? || $game.turn_number == 2

                        # This is a nested method - Ruby is the first language I've ever used that allows you to do this, but it is neat and tidy and makes sense here.
                        def remove_test_bugs
                            [Hive::Color[:white],Hive::Color[:black]].collect.each{|color|
                                $game.bugs[color].each{|bug| 
                                    bug.sides.each{|side|
                                        # Make any bugs that touched the Hive::Tester forget it ever existed.
                                        side.bug = false if side.bug.class.name == 'Hive::Tester'
                                    }
                                    # Delete the Hive::Tester bug itself.
                                    bug = false if bug.class.name == 'Hive::Tester'
                                }
                            }
                        end
                        self.remove_test_bugs # Call the method above. We have to clean up the test bugs we made!
                    end
                }
            }
            return open_sides
        end

        # This is a handle to the first white piece that is played
        def first_bug; $game.white.each{|bug| return bug if bug.is_in_play? && bug.not_hidden? }; end
        
        # Fetch a given bug from the game surface given it's color and Hive::Type ID
        def bug(color, id); $game.bugs[color].each{|bug| return bug if bug.id == id }; end

        # Notice how these top two methods leverage the list_bugs one below? This is good example of DRY - Don't Repeat Yourself!
        def bugs_in_play?; self.list_bugs(true); end
        def bugs_not_in_play?; self.list_bugs(false); end
        def list_bugs(in_play, verbose = false)
            bugs = Array.new
            [Hive::Color[:white],Hive::Color[:black]].collect{|color|
                bugs[color] = $game.trays[color].map{|bug| bug = (bug.is_in_play? == in_play ? bug : nil)}
            }
            puts "\nBugs #{in_play ? '' : 'not'} in play: " if verbose == true
            return bugs.flatten.compact
        end

    end
end