#!/usr/bin/env ruby
module Hive
    class Surface < Array
        attr_accessor :walkable_bugs

        def first_bug
            $game.trays.each{|tray|
                tray.each{|bug| return bug if bug.is_in_play? && bug.not_hidden? }
            }
        end

        def bug(color, id)
            $game.bugs[color].each{|bug| return bug if bug.id == id }
        end

        def walk
            # Walk the game surface to see if there are any islands
            @walkable_bugs = Array.new
            walkable_bugs << self.first_bug
            self.first_bug.walk
            return @walkable_bugs
        end

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
                    self.first_bug.notify(bug, TopCenter) 
                    bug.notify(first_bug, Side::opposite?(TopCenter), false)
                elsif $game.turn_number >= 3
                    if next_to.respond_to?('sides') == false
                        error = true
                        raise HiveException, "#{$game.turn?}, you specified a next_to bug that isn't on the surface yet"
                    elsif self.place_candidates($game.turn).include? next_to.sides[side]
                        next_to.notify(bug, side)
                        bug.look_around
                    else
                        error = InvalidPlacement
                        raise HiveException, "#{$game.turn?}, you can't place #{bug} in the " + Side::name?(side) + " of #{next_to}"
                    end
                end
                
                if error == false
                    bug.is_in_play = true
                    $game.bugs[$game.turn] << bug
                    $game.check_state
                    $game.turn = bug.color? == 'White' ? Black : White
                    $game.turn_number = $game.turn_number + 1
                end
            rescue HiveException => e
                abort(e.message) if e.message == 'White always starts first'
                puts e.message
                next_to.describe if next_to != false && error == InvalidPlacement
            end
        end

        def move_candidates(color)
            return if $game.not_my_turn?(color)
            puts "\n#{$game.turn?}, these are your possible moves:\n"
            moveable_bugs = Array.new
            $game.bugs[color].each{|bug|
                moveable_bugs << bug if bug.can_move?
            }
            return moveable_bugs
        end

        def place_candidates(color)
            return if $game.not_my_turn?(color)
            echo = caller[0].include? 'play'
            open_sides = Array.new
            $game.bugs[color].each{|bug|
                bug.sides.each_with_index{|side, name|
                    if name == TopLeft
                        if side.open? && ((bug.sides[TopCenter].bug && bug.sides[TopCenter].bug.color? == bug.color?) || bug.sides[TopCenter].bug == false) && ((bug.sides[BottomLeft].bug && bug.sides[BottomLeft].bug.color? == bug.color?) || bug.sides[BottomLeft].bug == false)
                            puts "You can place in the TopLeft of #{bug}" if echo
                            open_sides << side
                        end
                    elsif name == TopCenter 
                        if side.open? && ((bug.sides[TopLeft].bug && bug.sides[TopLeft].bug.color? == bug.color?) || bug.sides[TopLeft].bug == false) && ((bug.sides[TopRight].bug && bug.sides[TopRight].bug.color? == bug.color?) || bug.sides[TopRight].bug == false)
                            puts "You can place in the TopCenter of #{bug}" if echo
                            open_sides << side
                        end
                    elsif name == TopRight 
                        if side.open? && ((bug.sides[TopCenter].bug && bug.sides[TopCenter].bug.color? == bug.color?) || bug.sides[TopCenter].bug == false) && ((bug.sides[BottomRight].bug && bug.sides[BottomRight].bug.color? == bug.color?) || bug.sides[BottomRight].bug == false)
                            puts "You can place in the TopRight of #{bug}" if echo
                            open_sides << side
                        end
                    elsif name == BottomRight 
                        if side.open? && ((bug.sides[TopRight].bug && bug.sides[TopRight].bug.color? == bug.color?) || bug.sides[TopRight].bug == false) && ((bug.sides[BottomCenter].bug && bug.sides[BottomCenter].bug.color? == bug.color?) || bug.sides[BottomCenter].bug == false)
                            puts "You can place in the BottomRight of #{bug}" if echo
                            open_sides << side
                        end
                    elsif name == BottomCenter 
                        if side.open? && ((bug.sides[BottomRight].bug && bug.sides[BottomRight].bug.color? == bug.color?) || bug.sides[BottomRight].bug == false) && ((bug.sides[BottomLeft].bug && bug.sides[BottomLeft].bug.color? == bug.color?) || bug.sides[BottomLeft].bug == false)
                            puts "You can place in the BottomCenter of #{bug}" if echo
                            open_sides << side
                        end
                    elsif name == BottomLeft 
                        if side.open? && ((bug.sides[BottomCenter].bug && bug.sides[BottomCenter].bug.color? == bug.color?) || bug.sides[BottomCenter].bug == false) && ((bug.sides[TopLeft].bug && bug.sides[TopLeft].bug.color? == bug.color?) || bug.sides[TopLeft].bug == false)
                            puts "You can place in the BottomLeft of #{bug}" if echo
                            open_sides << side
                        end
                    end
                }
            }
            return open_sides
        end
    end

    class Side
        attr_accessor :bug
        
        def initialize; @bug = false; end
        def open?; return @bug == false; end
        def bug; return @bug; end

        def self.name?(side)
            return case side when TopLeft then "TopLeft"
                             when TopCenter then "TopCenter"
                             when TopRight then "TopRight"
                             when BottomRight then "BottomRight"
                             when BottomCenter then "BottomCenter"
                             when BottomLeft then "BottomLeft" end
        end

        def self.opposite?(side)
            return case side when TopLeft then BottomRight
                             when TopCenter then BottomCenter
                             when TopRight then BottomLeft
                             when BottomRight then TopLeft
                             when BottomCenter then TopCenter
                             when BottomLeft then TopRight end
        end
    end
end