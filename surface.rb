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
                    puts self.first_bug.+(bug, TopCenter)
                elsif $game.turn_number >= 3
                    if next_to.respond_to?('sides') == false
                        error = true
                        raise HiveException, "#{$game.turn?}, you specified a next_to bug that isn't on the surface yet"
                    elsif self.place_candidates($game.turn).include?(next_to.sides[side])
                        puts next_to.+(bug, side)
                        self.announce(next_to, bug, side)
                    else
                        error = InvalidPlacement
                        raise HiveException, "#{$game.turn?}, you can't place #{bug} in the " + Side::name?(side) + " of #{next_to}"
                    end
                end
                
                if error == false
                    bug.is_in_play = true
                    $game.bugs[$game.turn] << bug
                    $game.next_turn(bug.color? == 'White' ? Black : White)
                end
            rescue HiveException => e
                abort(e.message) if e.message == 'White always starts first'
                puts e.message
                next_to.describe if next_to != false && error == InvalidPlacement
            end
        end

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

        def place_candidates(color)
            return if $game.not_my_turn?(color)
            echo = caller[0].include? 'play'
            open_sides = Array.new
            $game.bugs[color].each{|bug|
                bug.sides.each_with_index{|side, name|
                    if side.open?
                        test_bug = Hive::Tester.new(color)
                        self.announce(bug, test_bug, name)
                        open_sides << side if test_bug.legal_placement? || $game.turn_number == 2
                        self.remove_test_bugs
                    end
                }
            }
            return open_sides
        end

        def announce(bug, test_bug, name)
            if name == TopLeft
                bug.bottom_left.+(test_bug, TopCenter) 
                bug.top_center.+(test_bug, BottomLeft)
                bug.bottom_left.top_left.+(test_bug, TopRight)
                bug.top_center.top_left.+(test_bug, BottomCenter)
                bug.bottom_left.top_left.top_center.+(test_bug, BottomRight)
                bug.top_center.top_left.bottom_left.+(test_bug, BottomRight)
            elsif name == TopCenter
                bug.top_left.+(test_bug, BottomLeft)
                bug.top_right.+(test_bug, BottomRight)
                bug.top_right.top_center.+(test_bug, BottomLeft)
                bug.top_left.top_center.+(test_bug, BottomRight)
                bug.top_left.top_center.top_right.+(test_bug, BottomCenter)
                bug.top_right.top_center.top_left.+(test_bug, BottomCenter)
            elsif name == TopRight
                bug.top_center.+(test_bug, BottomRight)
                bug.bottom_right.+(test_bug, TopCenter)
                bug.top_center.top_right.+(test_bug, BottomCenter)
                bug.bottom_right.top_right.+(test_bug, TopLeft)
                bug.top_center.top_right.bottom_right.+(test_bug, BottomLeft)
                bug.bottom_right.top_right.top_center.+(test_bug, BottomLeft)
            elsif name == BottomRight
                bug.top_right.+(test_bug, BottomCenter)
                bug.bottom_center.+(test_bug, TopRight)
                bug.top_right.bottom_right.+(test_bug, BottomLeft)
                bug.bottom_center.bottom_right.+(test_bug, TopCenter)
                bug.top_right.bottom_right.bottom_center.+(test_bug, TopLeft)
                bug.bottom_center.bottom_right.top_right.+(test_bug, TopLeft)
            elsif name == BottomCenter
                bug.bottom_left.+(test_bug, BottomRight)
                bug.bottom_right.+(test_bug, BottomLeft)
                bug.bottom_left.bottom_center.+(test_bug, TopRight)
                bug.bottom_right.bottom_center.+(test_bug, TopLeft)
                bug.bottom_left.bottom_center.bottom_right.+(test_bug, TopCenter)
                bug.bottom_right.bottom_center.bottom_left.+(test_bug, TopCenter)
            elsif name == BottomLeft
                bug.top_left.+(test_bug, BottomCenter)
                bug.bottom_center.+(test_bug, TopLeft)
                bug.top_left.bottom_left.+(test_bug, BottomRight)
                bug.bottom_center.bottom_left.+(test_bug, TopCenter)
                bug.top_left.bottom_left.bottom_center.+(test_bug, TopRight)
                bug.bottom_center.bottom_left.top_left.+(test_bug, TopRight)
            end   
        end
    end

    class Side
        attr_accessor :bug, :id
        
        def initialize(id, owner)
            @owner = owner#owner.color? << " " << owner.class.name << " (ID: " << (owner.id != false ? owner.id : false).to_s << ")"
            @bug = false
            @id = id
            @name = Side::name?(id)
        end

        def open?; return @bug == false; end
        def bug; return @bug; end

        def to_s
            return "#{Side::name?(@id)} of #{@owner}"
        end

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