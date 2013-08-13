#!/usr/bin/ruby

# 6 types of pieces
# piece parent class
# - just has position
# - team
#
#
# each subclass has its own move method
# - move_valid? based on path and position
#
# board interacts with all pieces
# - knows where all the pieces are
# - czech for czech

# require the shit out of debugger
# require 'debugger'

class Board
  attr_accessor :state, :black_king, :white_king

  def initialize
    @state = Array.new(8) {Array.new(8) {:_}}
    #@state[1].map {|square| square = Pawn.new()}
    #place pieces for white/black

    [:white, :black].each do |colour|
      place_pawns(colour)
      place_rooks(colour)
      place_knights(colour)
      place_bishops(colour)
      place_queens(colour)
      place_kings
    end

  end

  def display
    row_number = 8
    board = @state
    board.each do |row|
      print "#{row_number}|  #{row.join('   ')}\n"
      print " |\n" if row_number > 1
      row_number -= 1
    end
    puts "  --------------------------------"
    puts "    #{('a'..'h').to_a.join('   ')}"
  end

  def play
    display
    while !check_mate(@black_king) && !check_mate(@white_king)
      puts "White to move:"
      change_state(:white)
      break if check_mate(@black_king)

      puts "Black to move:"
      change_state(:black)
      break if check_mate(@white_king)
    end
    # abort
  end

  def change_state(team)
    move = false
    until move
      chess_notation_coordinates = get_input
      start, destination = map_input(chess_notation_coordinates)
      piece = find_piece(start)
      move = move_piece(team, piece, destination)
      move
    end
  end

  def get_input
    puts "Make your move eg: 'a2 a3'"
    input_move = gets.chomp.split
    start = input_move.first.split('')
    destination = input_move.last.split('')
    [start, destination]
  end

  def map_input(inputed_array)
    start, destination = inputed_array.map! do |position|
       [8 - position.last.to_i, position.first.downcase.ord - 97]
    end
  end

  def find_piece(start)
    curr_piece = @state[start.first][start.last]
    # destination_space = @state[destination.first][destination.last]
#     destination_team = destination_space.is_a?(Piece) ? destination_space.team : false
    # [curr_piece, destination_space]
    curr_piece
  end

  def move_piece(team, curr_piece, destination)
      # actually move if allowed.
    if curr_piece.move_valid?(destination, @state) && curr_piece.team == team
       curr_piece.move(@state, destination)
       display
       move = true
     else
       move = false
     end
   end

  def check?(target_space, colour, board_state)
    # get king position
    # destination = king.position
    # king_colour = king.team
    opposition = (colour == :white) ? :black : :white
    in_check = {}
    board_state.each do |row|
      row.each do |space|
        if (space.is_a? Piece) && (space.team == opposition)
          in_check[space.position] = space if (space.move_valid? target_space, board_state)
        end
      end
    end
    #puts "the #{king_colour} king is in check by #{in_check}" if in_check.any?
    in_check.any?
  end

  def check_mate(king)
    array_of_all_possible_team_moves = []
    team_pieces(king).each do |piece|
      fake_board = deep_dup_board(@state)
      fake_piece = fake_board[piece.position.first][piece.position.last]
      fake_king = fake_board[king.position.first][king.position.last]
      p "val is #{escapes?(fake_board, fake_piece, fake_king)}"
      return false if escapes?(fake_board, fake_piece, fake_king)
    end
    p "Checkmate! #{king.team} loses"
    true
  end

  def escapes?(fake_board, fake_piece, fake_king)
    fake_board.each_with_index do |fake_row, row_index|
      fake_row.each_with_index do |fake_space, col_index|
        if fake_piece.move_valid?([row_index, col_index], fake_board)
          orig_position = fake_piece.position
          fake_piece.move(fake_board, [row_index, col_index])
          #debugger
          return true unless check?(fake_king.position, fake_king.team, fake_board)
          fake_piece.move(fake_board, orig_position)
        end
      end
    end
    false # if you are always in check you will never return true
  end

  private
    def place_pawns(colour)
      row = 1
      row = 6 if colour == :white
      counter = 0
      @state[row].map! do |square|
        square = Pawn.new([row, counter], colour)
        counter += 1
        square
      end
    end

    def place_rooks(colour)
      positions = (colour == :black) ? [[0,0], [0,7]] : [[7,0], [7,7]]
      positions.each {|position| @state[position.first][position.last] = Rook.new(position, colour) }
    end

    def place_knights(colour)
      positions = (colour == :black) ? [[0,1], [0,6]] : [[7,1], [7,6]]
      positions.each {|position| @state[position.first][position.last] = Knight.new(position, colour) }
    end

    def place_bishops(colour)
      positions = (colour == :black) ? [[0,2], [0,5]] : [[7,2], [7,5]]
      positions.each {|position| @state[position.first][position.last] = Bishop.new(position, colour) }
    end

    def place_queens(colour)
      positions = (colour == :black) ? [[0,3]] : [[7,3]]
      positions.each {|position| @state[position.first][position.last] = Queen.new(position, colour) }
    end

    def place_kings
      @black_king = King.new [0,4], :black
      @white_king = King.new [7,4], :white
      [@black_king, @white_king].each {|king| @state[king.position.first][king.position.last] = king }
    end

    def deep_dup_board(board)
      board.map do |row|
        row.map do |space|
          space.is_a?(Piece) ? space.dup : :_
        end
      end
    end

    def team_pieces(king)
      my_team = king.team
      array_of_every_piece_on_team = []

      @state.each do |row|
        row.each do |space|
          #p "space is a piece? #{space.is_a? Piece}"
          array_of_every_piece_on_team << space if (space.is_a? Piece) && (space.team == my_team)
          #p "space.team is #{space.team}"
        end
      end
      array_of_every_piece_on_team
    end

end

class Piece
  attr_accessor :position, :team
  attr_reader :movement_deltas

  def initialize(start_position, team, movement_deltas = [])
    @team = team
    @position = start_position
    @movement_deltas = movement_deltas
  end

  def move(board_state, destination)
    board_state[@position.first][@position.last] = :_
    @position = destination
    board_state[@position.first][@position.last] = self
  end

  def move_valid?(destination, board_state)
    valid_moves = expand_perimeter(@movement_deltas, ([@position] * @movement_deltas.length))
    return true if can_move_to_now?(board_state, valid_moves, destination)

    if [Bishop, Rook, Queen].include? self.class
      6.times do |num| # number-check
        current_free_paths = free_paths(valid_moves, board_state)
        valid_moves = expand_perimeter(@movement_deltas, current_free_paths)
        return true if can_move_to_now?(board_state,valid_moves, destination)
      end
    end
    false
  end

  def expand_perimeter(movement_deltas, current_free_paths)
    movement_deltas.map {|delta| add_arrays([delta, current_free_paths.shift])}
  end

  def can_move_to_now?(board, perhaps_possible_moves, destination)
    if perhaps_possible_moves.include? destination

      return true if board[destination.first][destination.last] == :_  #empty
      return true if board[destination.first][destination.last].team != @team
    end

    false
  end

  def add_arrays(arr)
    # takes a big meta-array, adds the contents of the sub-arrays
    arr.transpose.map do |x|
      return [false,false] if x.include? false
      return [true,true] if x.include? true
      x.reduce(:+)
    end
  end

  def free_paths (valid_moves, board_state)
    valid_moves.map do |curr_move|
      curr_move = (space_open?(curr_move, board_state)) ? (curr_move) : ([false,false])
    end
  end

  def space_open? (position, board_state)
    return true unless (position == [false, false]) || #|| (position == [true, true])
                    (position.any? { |index| not index.between?(0,7) } )||
                    (board_state[position.first][position.last] != :_ )
  end

  def inspect
    return '*' if self.is_a? King
    return self.class.to_s[0]
  end

  def to_s
    return '*' if self.is_a? King
    return self.class.to_s[0]
  end

end

class Pawn < Piece
  def initialize(start_position, team)
    super(start_position, team)
    @movement_deltas = [
      [-1, -1],
      [-1, 0],
      [-1, 1]
    ] if team == :white
    @movement_deltas = [
      [1, -1],
      [1,  0],
      [1,  1]
    ] if team == :black
  end
end


class Rook < Piece
  def initialize(start_position, team)
    super(start_position, team)
    @movement_deltas = [
      [-1,  0],
      [ 1,  0],
      [ 0,  1],
      [ 0, -1]
    ]
  end
end

class Knight < Piece
  def initialize(start_position, team)
    super(start_position, team)
    @movement_deltas = [
      [-2, 1],
      [-2, -1],
      [2, 1],
      [2, -1],
      [-1, 2],
      [-1, -2],
      [1, 2],
      [1, -2]
    ]
  end
end

class Bishop < Piece
  def initialize(start_position, team)
    super(start_position, team)
    @movement_deltas = [
      [-1,  1],
      [ 1,  1],
      [-1, -1],
      [ 1, -1]
    ]
  end
end

class Queen < Piece
  def initialize(start_position, team)
    super(start_position, team)
    @movement_deltas = [
      [-1,  1],
      [ 1,  1],
      [-1, -1],
      [ 1, -1],
      [-1,  0],
      [ 1,  0],
      [ 0,  1],
      [ 0, -1]
    ]
  end
end

class King < Piece

  attr_reader :check_deltas_q, :check_deltas_k

  def initialize(start_position, team)
    super(start_position, team)
    @threats = {}
    @movement_deltas = [
      [-1,  1],
      [ 1,  1],
      [-1, -1],
      [ 1, -1],
      [-1,  0],
      [ 1,  0],
      [ 0,  1],
      [ 0, -1]
    ]
  end

end
