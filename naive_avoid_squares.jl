#Default board size if no argument given
#This also makes it convenient to run inside an IDE
N = 5

if length(ARGS) >= 1
  N = parse(Int64,ARGS[1])
end

function displaysquarebits(board)
  board_size = size(board,1)
  for i = 1:board_size
    for j = 1:board_size
      if board[i,j]
        print("1")
      else
        print("0")
      end
    end
    println()
  end
end

# Create all the square sizes
function create_square_indexes(n)
  if n < 1
    error("The board must have at least one square")
  end
  if n == 1
    return Array{NTuple{4,Int64},1}()
  end

  square_indexes = Array{NTuple{4,NTuple{2,Int64}},1}()
  # Generate "flat" square bitmasks
  for square_size::UInt64=1:n-1
    for y=1:n-square_size
      for x=1:n-square_size
        push!(square_indexes,((x,y),
                              (x+square_size,y),
                              (x,y+square_size),
                              (x+square_size,y+square_size)))
      end
    end
  end

  #Generate "diamond" square bitmasks
  for square_size::UInt64=1:n÷2
    for y=1:n-square_size*2
      for x=square_size+1:n-square_size
        push!(square_indexes,((x,y),
                              (x+square_size,y+square_size),
                              (x-square_size,y+square_size),
                              (x,y+2*square_size)))
      end
    end
  end

  return square_indexes
end

#=
#Display square_indexes
square_indexes = create_square_indexes(N)
for square_index in square_indexes
  board = zeros(Bool, N, N)
  for index in square_index
    board[index[1],index[2]] = true
  end
  displaysquarebits(board)
  println()
end
=#

function has_square(board, square_indexes)
  for square_index in square_indexes
    first_corner::Bool = board[square_index[1][1],square_index[1][2]]
    if board[square_index[2][1],square_index[2][2]] == first_corner &&
       board[square_index[3][1],square_index[3][2]] == first_corner &&
       board[square_index[4][1],square_index[4][2]] == first_corner
       return true
     end
  end
  return false
end

println("START")
println()

#iterate_valid_boards(N)





function has_square_20_million_times(board, square_indexes)
  x = false
  for i=1:20000000
    x = has_square(board, square_indexes)
  end
  return x
end

function time_has_square(board, n)
  square_indexes = create_square_indexes(n)
  @timev has_square(board, square_indexes)
  @timev has_square(board, square_indexes)
  @timev has_square(board, square_indexes)
  @timev has_square(board, square_indexes)
  @timev has_square(board, square_indexes)
  @timev has_square_20_million_times(board, square_indexes)
  #@code_native has_square(board, square_indexes)
end

time_has_square([false false false false false;
                 false true  false true  true;
                 false true  true  true  false;
                 true  true  false false true;
                 true  false true  true  true],5)
time_has_square([true  true  true  true  false true  true;
                 false true  false false false false false;
                 false false false true  true  false true;
                 true  true  false false true  true  false;
                 false false true  true  true  false false;
                 true  false true  false true  false true;
                 false true  true  false false true  true],7)
