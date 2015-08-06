require_relative 'stream.rb'
require_relative 'evaluator.rb'
require_relative 'lexer.rb'

module Rpn
  class Processor
    attr_accessor :current_context

    def initialize
      @evaluator = Evaluator.new
      @current_context = @global_context = Context.initial_context
      @input_stack = EvaluatingStack.new
    end

    def append_file file
      @input_stack.add_file file
    end

    def append_string string
      @input_stack.add_string string
    end

    def process
      internal_process(@input_stack.each_token.map { |token| @evaluator.evaluate token, @current_context })
    end

    def internal_process stack
      stack.each do |construct|
        execute_construct construct
      end
    end

    def execute_construct construct
      puts "executing " + construct.to_s
      case construct
        when Construct::Constant then @current_context.stack.push construct
        when Construct::UndefinedIdentifier then @current_context.stack.push construct
        when Construct::Block::Start then @current_context = Context.new @current_context
        when Construct::Block::End
          @current_context.parent.stack.push @current_context
          @current_context = @current_context.parent
        when Construct::SpecialFunctionCall then construct.call @current_context, self
        when Construct::FunctionCall
          if @current_context == @global_context
            construct.call @current_context, self
          else
            @current_context.stack.push construct
          end
        else raise StandardError, "Unknown construct type " + construct.inspect
      end
    end

    def state
      {
        global_context: @global_context,
        current_context: @current_context,
      }
    end
  end

  class Context
    attr_accessor :stack, :parent

    def initialize parent, functions = {}, specials = false
      @parent = parent
      @stack = EvaluatedStack.new
      @functions = functions
      @specials = specials
    end

    def find_identifier token
      @functions[token.text] || @parent && @parent.find_identifier(token)
    end

    def find_identifier token
      @functions[token] && (@specials ? Construct::SpecialFunctionCall.new(@functions[token]) : Construct::FunctionCall.new(@functions[token])) || @parent && @parent.find_identifier(token) || Construct::UndefinedIdentifier.new(token)
    end

    def inspect deep = false
      result = []
      result << 'current stack:'
      result << '    HEAD -> [ EMPTY ]' if @stack.empty?
      result << '    HEAD -> ' + @stack.first.inspect unless @stack.empty?
      result.push(*@stack[1...@stack.length].map { |value| '            ' + value.inspect }) unless @stack.empty?
      result << ''
      result << 'defined functions:'
      result.push(*@functions.map{ |name, function| "#{name}: { #{function.to_s} }" }.map { |value| '    ' + value })
      result << ''
      if deep && @parent
        result << 'parent context:'
        result.push(*@parent.inspect(true).each_line.map { |value| '    ' + value.chomp })
        result << ''
      end
      result.join("\n")
    end

    def self.initial_context
      default_functions = {
        '+' => -> context, process, first, second { first.value + second.value },
        '-' => -> context, process, first, second { first.value - second.value },
        '*' => -> context, process, first, second { first.value * second.value },
        '/' => -> context, process, first, second { first.value / second.value },
        'puts' => -> context, process, arg { puts arg.value },
        'value' => -> context, process, arg { arg.respond_to?(:stack) && process.internal_process(arg.stack) || arg },
      }

      special_functions = {
        '/?' => -> context, process { puts context.inspect true },
      }

      Context.new(
        Context.new(
          nil,
          Hash[special_functions.map { |identifier, func| [identifier, Construct::BuiltinFunctionDefinition.new(identifier, func)] }]),
        Hash[default_functions.map { |identifier, func| [identifier, Construct::BuiltinFunctionDefinition.new(identifier, func)] }])
    end
  end

  class EvaluatedStack
    include Enumerable
    def initialize; @array = [] end
    def pop count=1; @array.count < count ? nil : @array.pop(count) end
    def peek; @array.empty? ? nil : @array.last end
    def count; @array.count end
    def empty?; @array.empty?  end
    def push *values; @array.push(*values) end
    def to_s; @array.map { |value| value.inspect }.join "\n" end
    def each &block; if block_given? then @array.reverse.each(&block) else enum_for :each end end
    def each_token &block; each(&block) end
    def length; return @array.length end
    def [] *args; return @array.reverse[*args] end
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
