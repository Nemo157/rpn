module Rpn
  module Token
    class Variable
      attr_accessor :text

      def initialize text
        @text = text
      end
    end

    class Identifier
      attr_accessor :text

      def initialize text
        @text = text
      end
    end

    class Number
      attr_accessor :text, :value

      def initialize text
        @text = text
        @value = text.to_i
      end
    end

    module Brace
      class Start
      end

      class End
      end
    end

    module Square
      class Start
      end

      class End
      end
    end
  end
end
