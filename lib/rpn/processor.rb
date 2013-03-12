require_relative 'stream.rb'
require_relative 'evaluator.rb'
require_relative 'lexer.rb'

module Rpn
  class Processor
    attr_accessor :result_stack

    def initialize
      @evaluator = Evaluator.new
      @current_context = @global_context = GlobalContext.new
      @result_stack = EvaluatedStack.new
      @input_stack = EvaluatingStack.new
    end

    def append_file file
      @input_stack.add_file file
    end

    def append_string string
      @input_stack.add_string string
    end

    def process
      @input_stack.each_token do |token|
        construct = @evaluator.evaluate token, @current_context
        execute_construct construct
      end
    end

    def execute_construct construct
      case construct
        when Construct::Constant then @result_stack.push construct.value
        when Construct::UndefinedIdentifier then @result_stack.push construct
        when Construct::FunctionCall then call_function construct
        else raise StandardError, "Unknown construct type " + construct.inspect
      end
    end

    def call_function function
      arguments = @result_stack.pop function.arity
      case function
        when Construct::BuiltinFunctionCall then @result_stack.push function.func[*arguments]
        else raise StandardError, "Unknown construct type " + construct.inspect
      end
    end

    def state
      {
        result_stack: @result_stack,
        global_context: @global_context,
        current_context: @current_context,
      }
    end
  end

  class Context
    def initialize parent
      @parent = parent
    end

    def find_identifier token
      @functions[token.text] || @parent && @parent.find_identifier(token)
    end

    def to_s
      'defined functions: {' + @functions.map { |name, function| name }.join(', ') + '}'
    end
  end

  class GlobalContext < Context
    def initialize
      @functions = {
        '+' => Construct::BuiltinFunctionCall.new('+', -> first, second { first + second }),
        '-' => Construct::BuiltinFunctionCall.new('-', -> first, second { first - second }),
        '*' => Construct::BuiltinFunctionCall.new('*', -> first, second { first * second }),
        '/' => Construct::BuiltinFunctionCall.new('/', -> first, second { first / second }),
      }
    end

    def find_identifier token
      @functions[token.text] || Construct::UndefinedIdentifier.new(token.text)
    end
  end

  class EvaluatedStack
    def initialize; @array = [] end
    def pop count=1; @array.count < count ? nil : @array.pop(count) end
    def peek; @array.empty? ? nil : @array.last end
    def count; @array.count end
    def empty?; @array.empty?  end
    def push value; @array.push value end
    def to_s; @array.to_s end
  end

  class EvaluatingStack
    def initialize
      @sources = []
    end

    def get_token
      get_source && get_source.get_token
    end

    def each_token
      if block_given?
        while token = get_token
          yield token
        end
      else
        enum_for :each_token
      end
    end

    def get_source
      if @current_source && @current_source.peek_token
        @current_source
      else
        @current_source = @sources.pop
      end
    end

    def add_file
    end

    def add_string string
      @sources.push Lexer.new Stream::String.new string
    end
  end
end
