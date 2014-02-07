require 'sinatra' # load sinatra
require 'sinatra/partial' 
require 'rack-flash'

require_relative './lib/sudoku'
require_relative './lib/cell'

enable :sessions
set :partial_template_engine, :erb
use Rack::Flash

set :session_secret, "I'm the secret key to sign the cookie"


def random_sudoku
    seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
    sudoku = Sudoku.new(seed.join)
    sudoku.solve!
    sudoku.to_s.chars
end

# this method removes some digits from the solution to create a puzzle
def puzzle(sudoku)
    random = [*0..81].sample(20)
    random.each {|i| sudoku[i] = " "}
    sudoku
end

get '/' do
  prepare_to_check_solution
  generate_new_puzzle_if_necessary
  @current_solution = session[:current_solution] || session[:puzzle]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end

get '/restart' do
  session[:current_solution]= nil
  redirect to '/'
end

def generate_new_puzzle_if_necessary
  return if session[:current_solution]
  sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku)
  session[:current_solution] = session[:puzzle]    
end

def prepare_to_check_solution
   @check_solution = session[:check_solution]
    if @check_solution
      flash[:notice] = "Incorrect values are highlighted in yellow"
    end
    session[:check_solution] = nil
end

get '/solution' do
  @current_solution = session[:solution]
  @puzzle = session[:puzzle]
  @solution = session[:solution]
  erb :index
end

  post '/' do 
    # the cells in HTML are ordered box by box
    # (first box1, then box2, etc),
    # so the form data (params['cells']) is sent using this order
    # However, our code expect it to be row by row,
    # so we need to transform it.
    cells = params["cell"]
    session[:current_solution] = cells.map{|value|value.to_i}.join
    session[:check_solution] = true
    redirect to ("/")
  end

  def box_order_to_row_order(cell)
    # first, we break down 81 cells into 9 arrays of 9 cells,
    # each representing one box
      boxes = cells.each_slice(9).to_a
      (0..8).to_a.inject([]) {|memo, i|}
      first_box_index = i / 3 * 3
      three_boxes = boxes[first_box_index, 3]
      three_rows_of_three = three_boxes.map do |box| 
      row_number_in_a_box = i % 3
      first_cell_in_the_row_index = row_number_in_a_box * 3
      box[first_cell_in_the_row_index, 3]
    end
      memo += three_rows_of_three.flatten
    end

  helpers do
    def colour_class(solution_to_check, puzzle_value, current_solution_value, solution_value)
      must_be_guessed = puzzle_value.to_i == 0
      # I needed to change this 0 to "0" otherwise all the cells show up as value provided
      tried_to_guess = current_solution_value.to_i != 0
      guessed_incorrectly = current_solution_value != solution_value

      if solution_to_check && 
          must_be_guessed && 
          tried_to_guess && 
          guessed_incorrectly
        'incorrect'
      elsif !must_be_guessed
        'value-provided'
      end
    end
  end

  helpers do
    def cell_value(value)
      value.to_i == 0 ? '' : value
    end 
  end   







