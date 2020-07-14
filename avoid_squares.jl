#TODO: Compare performance to a naive implementation
#TODO: Skip over huge number of invalid boards at beginning (or better yet do a real search)

#Default board size if no argument given
#This also makes it convenient to run inside an IDE
N = 5

if length(ARGS) >= 1
  N = parse(Int64,ARGS[1])
end

function displaysquarebits(square, size)
  for i = 1:size
    for j = 1:size
      print(square & 1)
      square = square >> 1
    end
    println()
  end
end

# Create all the square sizes
function create_bitmasks(n)
  if n < 1
    error("The board must have at least one square")
  end
  if n == 1
    return Array{UInt64,1}()
  end
  if n > 8
    error("Only board sizes of up to 8 are supported due to bitfield size limitations")
  end

  bitmasks = Array{UInt64,1}()
  # Generate "flat" square bitmasks
  for square_size::UInt64=1:n-1
    offset::UInt64 = square_size * n
    for y=0:n-square_size-1
      for x=0:n-square_size-1
        initial_position::UInt64 = x + y*n
        push!(bitmasks,UInt64(2)^initial_position+
                       UInt64(2)^(initial_position+square_size)+
                       UInt64(2)^(initial_position+offset)+
                       UInt64(2)^(initial_position+offset+square_size))
      end
    end
  end

  #Generate "diamond" square bitmasks
  for square_size::UInt64=1:n÷2
    for y=0:n-(square_size*2+1)
      for x=square_size:n-square_size-1
        initial_position::UInt64 = x + y*n
        middle_offset::UInt64 = initial_position + square_size * n
        push!(bitmasks,UInt64(2)^initial_position+
                       UInt64(2)^(UInt64(2)*square_size*n+initial_position)+
                       UInt64(2)^(middle_offset+square_size)+
                       UInt64(2)^(middle_offset-square_size))
      end
    end
  end

  return bitmasks
end

function create_single_bit_boards(n)
  if n < 1
    error("The board must have at least one square")
  end
  if n > 8
    error("Only board sizes of up to 8 are supported due to bitfield size limitations")
  end

  bit_boards = Array{UInt64,1}(undef,n^2)
  for i::UInt64=1:n^2
    bit_boards[i] = UInt64(2)^(i-UInt64(1))
  end
  return bit_boards
end

function has_square(board, bitmasks, inverter)
  board_inverse = board ⊻ inverter
  for bitmask in bitmasks
    if board & bitmask == bitmask
      return true
    end
    if board_inverse & bitmask == bitmask
      return true
    end
  end
  return false
end

function find_last_one(board, start, single_bit_boards)
  index = start-1
  while index > 0
    if board & single_bit_boards[index] == single_bit_boards[index]
      return index
    end
    index -= 1
  end
  return -1
end

function iterate_valid_boards(n)
  n_squared::UInt64 = UInt64(n)^UInt64(2)
  max_board::UInt64 = UInt64(2)^n_squared-UInt64(1)
  min_half_board::UInt64 = UInt64(2)^ceil(UInt64,n_squared/2)-UInt64(1)

  bitmasks = create_bitmasks(n)
  inverter::UInt64 = max_board
  single_bit_boards = create_single_bit_boards(n)

  board::UInt64 = min_half_board
  while true
    if !has_square(board, bitmasks, inverter)
      displaysquarebits(board,N)
      println()
    end

    if board & single_bit_boards[n_squared] == single_bit_boards[n_squared]
      board_inverse = board ⊻ inverter
      scan_from = find_last_one(board_inverse, n_squared, single_bit_boards)
      num_ones = n_squared - scan_from
      for i=1:num_ones
        board = board - single_bit_boards[scan_from+i]
      end

      index = find_last_one(board, scan_from, single_bit_boards)
      if index == -1
        return
      end
      board = board - single_bit_boards[index]
      for i=1:num_ones+1
        board = board + single_bit_boards[index+i]
      end
    else
      index = find_last_one(board, n_squared, single_bit_boards)
      board = board - single_bit_boards[index]
      board = board + single_bit_boards[index+1]
    end
  end
end

println("START")
println()

iterate_valid_boards(N)





function has_square_20_million_times(board, bitmasks, inverter)
  x = false
  for i=1:20000000
    x = has_square(board, bitmasks, inverter)
  end
  return x
end

function time_has_square(board, n)
  inverter::UInt64 = UInt64(2)^(UInt64(n)^UInt64(2))-UInt64(1)
  bitmasks = create_bitmasks(n)
  @timev has_square(board, bitmasks, inverter)
  @timev has_square(board, bitmasks, inverter)
  @timev has_square(board, bitmasks, inverter)
  @timev has_square(board, bitmasks, inverter)
  @timev has_square(board, bitmasks, inverter)
  @timev has_square_20_million_times(board, bitmasks, inverter)
  #@code_native has_square(board, bitmasks, inverter)
end

#Checking one board reportedly takes around 45-90ns, but this is below the
#minimum time resolution so it's actually taking less time
#On one core of my Intel Core i7-5820K CPU @ 3.30GHz
#it can process approximately 40 million 5x5 boards per second (with no matches)
#or 12.5 million 7x7 boards per second
#This implies that it's actually taking 25ns for 5x5 and 80ns for 7x7

#time_has_square(UInt64(0b0000001011011101100110111), 5)
#time_has_square(UInt64(0b1111011010000000011011100110001110010101010110011), 7)
