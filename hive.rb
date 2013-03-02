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

    # Bug constants
    Ant1         = 0
    Ant2         = 1
    Ant3         = 2
    Grasshopper1 = 3
    Grasshopper2 = 4
    Grasshopper3 = 5
    Spider1      = 6
    Spider2      = 7
    Beetle1      = 8
    Beetle2      = 9
    Ladybug1     = 10
    Mosquito1    = 11
    Queen1       = 12
    
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

        def not_my_turn?(color)
            begin
                if self.turn == color
                    return false
                else
                    raise HiveException, "#{color == White ? "White" : "Black"}, it's not your turn!", caller
                end
            rescue HiveException => e
                puts e.message
            end
            return true
        end
        
        def play
            $game.surface.+$game.white.get('Ant')
            $game.surface.+$game.black.get('Beetle')
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(White, Ant1), BottomLeft)
            #$game.surface.place_candidates($game.turn)
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Black, Beetle1), BottomLeft)
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Black, Beetle1), TopRight)
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(White, Ant2), BottomRight)
            $game.surface.+($game.black.get('Queen'), $game.surface.bug(Black, Grasshopper1), TopRight)
            $game.surface.+($game.white.get('Queen'), $game.surface.bug(White, Ant3), BottomRight)
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Black, Queen1), TopRight)
            $game.surface.+($game.white.get('Spider'), $game.surface.bug(White, Ant1), BottomCenter)

            puts $game.surface.move_candidates(White)
        end

        def check_state
            [White,Black].collect{|color|
                abort("#{$game.turn?} won!") if self.trays[color].queen.is_surrounded?
            }
        end
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

    class HiveException < RuntimeError; end
end

require 'bug'
require 'surface'

$game = Hive::Game.new
$game.play
