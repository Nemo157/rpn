module Rpn
  module Construct
    class FunctionCall
      attr_accessor :definition

      def initialize definition
        @definition = definition
      end

      def call context, process
        arguments = context.stack.pop definition.arity
        raise StandardError, "Not enough arguments available" unless arguments
        case definition
          when Construct::BuiltinFunctionDefinition then context.stack.push(*definition.func[context, process, *arguments])
          else raise StandardError, "Unknown function definition type " + construct.inspect
        end
      end
    end

    class SpecialFunctionCall < FunctionCall
    end

    class FunctionDefinition
      attr_accessor :name, :arity

      def initialize name, arity
        raise StandardError, "Only known arity functions are allowed" if arity < 0
        @name = name
        @arity = arity
      end
    end

    class BuiltinFunctionDefinition < FunctionDefinition
      attr_accessor :func

      def initialize name, func
        super name, func.arity - 2
        @func = func
      end

      def to_s
        return '[builtin]'
      end
    end

    class UndefinedIdentifier
      attr_accessor :name

      def initialize name
        @name = name
      end
    end

    class Constant
      attr_accessor :value

      def initialize value
        @value = value
      end
    end

    module Block
      class Start
      end
      class End
      end
    end
  end

  class Evaluator
    def initialize
    end

    def evaluate token, context
      case token
        when Token::Number, Token::String then Construct::Constant.new token.value
        when Token::Identifier then context.find_identifier token.text
        when Token::Brace::Start then Construct::Block::Start.new
        when Token::Brace::End then Construct::Block::End.new
        else raise StandardError, "Unknown token type " + token.inspect
      end
    end
  end
end
