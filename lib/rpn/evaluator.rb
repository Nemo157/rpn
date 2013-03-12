module Rpn
  module Construct
    class FunctionCall
      attr_accessor :name, :arity

      def initialize name, arity
        raise StandardError, "Only known arity functions are allowed" if arity < 0
        @name = name
        @arity = arity
      end
    end

    class BuiltinFunctionCall < FunctionCall
      attr_accessor :func

      def initialize name, func
        super name, func.arity
        @func = func
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
  end

  class Evaluator
    def initialize
    end

    def evaluate token, context
      case token
        when Token::Number then Construct::Constant.new token.value
        when Token::Identifier then context.find_identifier token
        else raise StandardError, "Unknown token type " + token.inspect
      end
    end
  end
end
