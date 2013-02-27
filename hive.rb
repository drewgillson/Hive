#!/usr/bin/env ruby
module Hive

    # Color constants
    White        = 0
    Black        = 1
    
    # Position constants
    TopLeft      = 0
    TopCenter    = 1
    TopRight     = 2
    BottomRight  = 3
    BottomCenter = 4
    BottomLeft   = 5
    Above        = 6
    Below        = 7

    # Error constants
    InvalidPlacement = 1
    
    class Game
        attr_accessor :trays,
                      :bugs,
                      :surface,
                      :turn,
                      :turn_number
        
        def initialize
            puts "\nWelcome to Hive!\n****************\n"

            @trays = [White,Black].collect {|tray| tray = Tray.new}
            @bugs = [White,Black].collect {|tray| tray = Tray.new}
            @surface = Surface.new
            @turn = Black
            @turn_number = 1

            2.times {
                3.times { @trays[@turn] << Hive.const_get('Ant').new(@turn, @trays[turn].count) }
                3.times { @trays[@turn] << Hive.const_get('Grasshopper').new(@turn, @trays[turn].count) }
                2.times { @trays[@turn] << Hive.const_get('Spider').new(@turn, @trays[turn].count) }
                2.times { @trays[@turn] << Hive.const_get('Beetle').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Ladybug').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Mosquito').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Queen').new(@turn, @trays[turn].count) }
                @turn = White
            }
        end

        def white; return self.trays[White]; end
        def black; return self.trays[Black]; end
        def turn?; return @turn == 0 ? 'White' : 'Black'; end
        
        def play
            $game.surface.+$game.white.get('Ant')
            $game.surface.+$game.black.get('Beetle')
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(White, 0), BottomLeft)
            #$game.surface.place_candidates($game.turn)
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Black, 8), BottomLeft)
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Black, 8), TopRight)
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(White, 1), BottomRight)
            $game.surface.+($game.black.get('Queen'), $game.surface.bug(Black, 3), TopRight)
            $game.surface.+($game.white.get('Queen'), $game.surface.bug(White, 2), BottomRight)
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Black, 12), TopRight)
            $game.surface.+($game.white.get('Spider'), $game.surface.bug(White, 0), BottomCenter)
        end

        def check_state
            [White,Black].collect{|color|
                abort("#{$game.turn?} won!") if self.trays[color].queen.is_surrounded?
            }
        end
    end

    module Bug
        attr_accessor :sides, :is_in_play, :id

        def initialize(color, id)
            @color = color
            @id = id
            @is_in_play = false
            @sides = Array.new
            6.times{@sides << Side.new}
        end

        def notify(bug, side, echo = true)
            @sides[side].bug = bug
            puts "#{$game.turn?} placed #{bug} in #{Side::name? side} of #{self}" if echo != false
        end

        def open_sides?
            open_sides = Array.new
            @sides.each{|side| open_sides << side if side.open?}
            return open_sides.count
        end

        def describe
            @sides.each_with_index{|side, index|
                puts "    " << side.bug << " is in " << Side::name?(index) if side.bug != false
                puts "    " << Side::name?(index) << " is open" if side.bug == false
            }
        end

        def top_left; return @sides[TopLeft].bug if @sides[TopLeft].bug != false; end
        def top_center; return @sides[TopCenter].bug if @sides[TopCenter].bug != false; end
        def top_right; return @sides[TopRight].bug if @sides[TopRight].bug != false; end
        def bottom_left; return @sides[BottomLeft].bug if @sides[BottomLeft].bug != false; end
        def bottom_center; return @sides[BottomCenter].bug if @sides[BottomCenter].bug != false; end
        def bottom_right; return @sides[BottomRight].bug if @sides[BottomRight].bug != false; end
        def to_s; return "#{self.color?} #{self.class.name} (ID: #{self.id})"; end
        def to_str; return "#{self.color?} #{self.class.name} (ID: #{self.id})"; end
        def color?; return @color.==(White) ? 'White' : 'Black'; end
        def is_in_play?; return @is_in_play; end

        def move; end
    end

    class Side
        attr_accessor :bug
        
        def initialize; @bug = false; end
        def open?; return true if @bug == false; end
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

    class Ant
        include Bug

        def move; end
    end

    class Beetle
        include Bug

        def move; end
    end

    class Spider
        include Bug

        def move; end
    end

    class Grasshopper
        include Bug

        def move; end
    end

    class Mosquito
        include Bug

        def move; end
    end

    class Ladybug
        include Bug

        def move; end
    end

    class Queen
        include Bug

        def move; end

        def is_surrounded?; self.sides.each{|side| return false if side.bug == false}; end
    end

    class Tray < Array
        def get(type)
            self.each{|bug| return bug if bug.class.name == "Hive::#{type}" && bug.is_in_play? == false}
            begin
                raise HiveException, "#{$game.turn?}, you have no more #{type}s in your tray"
            rescue HiveException => e
                puts e.message
            end
        end

        def queen; self.each{|bug| return bug if bug.class.name == 'Hive::Queen'}; end
    end

    class Surface < Array
        def first_bug
            $game.trays.each{|tray|
                tray.each{|bug| return bug if bug.is_in_play? }
            }
        end

        def bug(color, id)
            $game.bugs[color].each{|bug| return bug if bug.id == id }
        end

        def +(bug, next_to = false, side = false)
            error = false
            return if bug == nil
            begin
                raise HiveException, "White always starts first" if $game.turn_number == 1 && bug.color? == 'Black'
                
                if $game.turn? == bug.color?
                    
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
                            bug.notify(next_to, Side::opposite?(side), false)
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
                else
                    raise HiveException, "#{$game.turn?}, it's not your turn!", caller
                end
            rescue HiveException => e
                abort(e.message) if e.message == 'White always starts first'
                puts e.message
                next_to.describe if next_to != false && error == InvalidPlacement
            end
        end

        def place_candidates(color)
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

    class HiveException < RuntimeError; end
end

$game = Hive::Game.new
$game.play
