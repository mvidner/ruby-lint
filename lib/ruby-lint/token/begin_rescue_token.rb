module Rlint
  module Token
    ##
    # Token class used for storing information about begin/rescue/ensure
    # statements.
    #
    class BeginRescueToken < Token
      ##
      # Array of rescue statements. Each item is an instance of
      # {Rlint::Token::StatementToken}.
      #
      # @return [Array]
      #
      attr_accessor :rescue

      ##
      # Attribute containing details about the ensure statement.
      #
      # @return [Rlint::Token::StatementToken]
      #
      attr_accessor :ensure

      ##
      # Attribute containing details about the else statement.
      #
      # @return [Rlint::Token::StatementToken]
      #
      attr_accessor :else

      ##
      # @see Rlint::Token#initialize
      #
      def initialize(*args)
        @type = :begin_rescue

        super
      end

      ##
      # @see Rlint::Token::Token#child_nodes
      #
      def child_nodes
        nodes = [@rescue]

        if @ensure
          nodes << [@ensure]
        end

        if @else
          nodes << [@else]
        end

        return super + nodes
      end
    end # BeginRescueToken
  end # Token
end # Rlint