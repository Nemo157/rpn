require_relative 'token.rb'

module Rpn
  class Lexer
    def initialize stream
      @stream = stream
    end

    def peek_token
      @token ||= read_token
    end

    def get_token
      if @token
        prev_token = @token
      else
        prev_token = read_token
      end

      @token = nil
      prev_token
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

    def read_token
      ignore_whitespace
      case @stream.peekc
        when nil then nil
        when /'|"/ then read_string
        when /[A-Z]/ then read_variable
        when /[0-9-]/ then read_number
        when /[\[\]{}]/ then read_bracket
        else read_identifier
      end
    end

    def read_number
      text = ""
      text += @stream.getc if '-' == @stream.peekc
      text += @stream.getc while /[0-9]/ =~ @stream.peekc

      if text == '-'
        read_identifier text
      else
        Token::Number.new text
      end
    end

    def read_string
      delimiter = @stream.getc

      text = ""
      text += @stream.getc until @stream.peekc == delimiter

      @stream.getc # discard delimiter

      Token::String.new text
    end

    def read_variable
      text = ""
      text += @stream.getc while /[^\s\[\]{}]/ =~ @stream.peekc
      Token::Variable.new text
    end

    def read_identifier existing_text=nil
      text = existing_text || ""
      text += @stream.getc while /[^\s\[\]{}]/ =~ @stream.peekc
      Token::Identifier.new text
    end

    def read_bracket
      case @stream.getc
        when '[' then Token::Square::Start.new
        when ']' then Token::Square::End.new
        when '{' then Token::Brace::Start.new
        when '}' then Token::Brace::End.new
      end
    end

    def ignore_whitespace
      @stream.getc while /\s/ =~ @stream.peekc
    end
  end
end
