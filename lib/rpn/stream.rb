module Rpn
  module Stream
    class String
      def initialize text
        @text = text
        @position = 0
      end

      def peekc
        @text[@position]
      end

      def getc
        @position += 1
        @text[@position - 1]
      end
    end
  end
end

