require "spec"

module PowerAssert
  VERSION = "0.2.3"

  Operators = [
    "!", "!=", "%", "&", "*", "**", "+", "-", "/", "<", "<<", "<=", "<=>", "==", "===",
    ">", ">=", ">>", "^", "|", "~"
  ]

  class Config
    def initialize(@global_indent = 2, @sort_by = :default, @expand_block = false)
    end

    def global_indent
      @global_indent
    end

    def global_indent=(global_indent)
      @global_indent = global_indent
    end

    def sort_by
      @sort_by
    end

    def sort_by=(sort_by)
      @sort_by = sort_by
    end

    def expand_block
      @expand_block
    end

    def expand_block=(expand_block)
      @expand_block = expand_block
    end
  end

  def self.config
    @@config ||= Config.new
  end

  class Breakdowns < Array(Breakdown)
    def self.display(io : IO, breakdowns, only_bars = true)
      io << " " * PowerAssert.config.global_indent

      main_value = breakdowns.first
      main_range = main_value.indent ... (main_value.indent + main_value.value.bytesize)

      if only_bars
        main_value = nil
        main_range = -1 .. -1
      end

      overlap = false

      breakdowns.sort_by(&.indent).reduce(0) do |wrote, breakdown|
        point = breakdown.indent - wrote
        wrote += point
        if !main_range.includes?(breakdown.indent) && breakdown != main_value
          io << " " * point
          io << "|"
          wrote += 1
        elsif breakdown == main_value && main_value
          io << " " * point
          io << main_value.value
          wrote += main_value.value.bytesize
        else
          wrote -= point
          overlap = true
        end
        wrote
      end

      if only_bars
        io << "\n"
        return display(io, breakdowns, false)
      end

      if breakdowns.size > 1
        io << "\n"
        display(io, breakdowns[1, breakdowns.size], overlap)
      end
    end

    def to_s(io : IO)
      breakdowns = self
      case PowerAssert.config.sort_by
      when :reverse
        breakdowns = self.reverse
      when :left
        breakdowns = breakdowns.sort_by(&.indent)
      when :right
        breakdowns = breakdowns.sort_by(&.indent).reverse
      end

      self.class.display(io, breakdowns)
    end
  end

  class Breakdown
    def initialize(@value, @indent)
    end

    def value
      @value
    end

    def indent
      @indent
    end

    def to_s(io : IO)
      io << " " * @indent  << @value
    end
  end

  class Node
    def initialize(@ident : String, @value : T)
    end

    def ident : String
      return @ident
    end

    def inspectable?
      @ident != @value.inspect
    end

    def to_s(io : IO)
      io << ident
    end

    def breakdowns
      breakdowns(0)
    end

    def indent_size : Int32
      return ident.bytesize
    end

    def breakdowns(indent : Int32)
      if inspectable?
        Breakdowns.new(1, Breakdown.new(@value.inspect, indent))
      else
        Breakdowns.new(0)
      end
    end

    def nop?
      false
    end
  end

  class NopNode < Node
    def initialize(@ident = "", @value = nil)
    end

    def inspectable?
      false
    end

    def nop?
      true
    end
  end

  class MethodCall < Node
    def initialize(
      @ident : String, @value : T, @recv : PowerAssert::Node,
      @args : Array(PowerAssert::Node), @named_args : Array(PowerAssert::NamedArg),
      @block)
    end

    def inspectable?
      true
    end

    def to_s(io : IO)
      unless @recv.nop?
        @recv.to_s(io)
        io << (operator? ? " " : ".")
      end
      io << @ident
      io << "(" if with_parenthesis?
      io << " " if !with_parenthesis? && has_args?
      @args.each_with_index do |arg, idx|
        arg.to_s(io)
        io << ", " if idx < (@args.size - 1)
      end
      @named_args.each_with_index do |named_arg, idx|
        io << ", " if idx > 0 || @args.size > 0
        io << "#{named_arg.name}: "
        named_arg.value.to_s(io)
      end
      io << ")" if with_parenthesis?
      io << " " if operator? || with_block?
      if with_block?
        io << "{ "
        io << block_string
        io << " }"
      end
    end

    def indent_size : Int32
      indents = left_indent_size
      if has_args?
        indents += 2
        if @args.size > 0
          aindents = @args.map(&.indent_size)
          indents += aindents.sum + (2 * (aindents.size - 1))
        end

        if @named_args.size > 0
          nindents = 0
          @named_args.each do |narg|
            nindents += (narg.name.inspect.bytesize + 1 + narg.value.indent_size + 2)
          end
          indents += nindents
        end
      end
      if with_block?
        indents += 5
        indents += block_string.bytesize
      end

      return indents
    end

    def left_indent_size
      @recv.indent_size +  @ident.bytesize + (@recv.nop? ? 0 : 1)
    end

    def operator?
      Operators.any? { |op| op == @ident }
    end

    def with_parenthesis?
      !operator? && has_args?
    end

    def has_args?
      @args.size > 0 || @named_args.size > 0
    end

    def with_block?
      @block.bytesize > 0
    end

    def block_string
      if PowerAssert.config.expand_block
        @block.gsub(/\Ado/, "").gsub(/end\Z/, "").gsub(/\|\n\s/, "|").strip
      else
        "..."
      end
    end

    def breakdowns(indent : Int32)
      bdowns = Breakdowns.new(0)

      call_indent = indent + @recv.indent_size
      call_indent += (@recv.nop? ? 0 : 1)
      bdowns << Breakdown.new(@value.inspect, call_indent)

      @args.each_with_index do |arg, idx|
        aindents = @args[0 ... idx].map(&.indent_size)

        bdowns.concat(arg.breakdowns(indent + left_indent_size + 1 + aindents.sum + (aindents.size * 2)))
      end

      args_indent = @args.map(&.indent_size).sum + (@args.size * 2)
      @named_args.each_with_index do |arg, idx|
        before_nindents = 0
        @named_args[0 ... idx].each do |narg|
          before_nindents += (narg.name.inspect.bytesize + 1 + narg.value.indent_size + 2)
        end
        nindent = indent + left_indent_size + 1 + args_indent + arg.name.inspect.bytesize + 1 + before_nindents
        bdowns.concat(arg.value.breakdowns(nindent))
      end

      bdowns.concat(@recv.breakdowns(indent)) unless @recv.nop?

      bdowns
    end
  end

  struct NamedArg
    property name
    property value

    def initialize(@name : Symbol, @value : PowerAssert::Node)
    end
  end

  macro assert(expression, file = __FILE__, line = __LINE__)
    %result = {{ expression }}

    unless %result
      %ast = get_ast({{ expression }})
      %breakdowns = %ast.breakdowns

      %message = String.build do |io|
        io << " " * PowerAssert.config.global_indent
        %ast.to_s(io)
        io << "\n"
        %breakdowns.to_s(io)
      end

      fail %message, {{ file }}, {{ line }}
    end

    %result
  end

  macro get_ast(expression)
    {% if expression.is_a?(Call) %}
      {% if expression.receiver.is_a?(Nop) %}
        %receiver = PowerAssert::NopNode.new
      {% else %}
        %receiver = get_ast({{ expression.receiver }})
      {% end %}
      %args = [] of PowerAssert::Node
      {% for arg in expression.args %}
        %args.push(get_ast({{ arg }}))
      {% end %}

      %named_args = [] of PowerAssert::NamedArg
      {% if expression.named_args.is_a?(ArrayLiteral) %}
        {% for key, idx in expression.named_args %}
          %named_args.push PowerAssert::NamedArg.new(:{{ key.name.id }}, get_ast({{ expression.named_args[idx].value }}))
        {% end %}
      {% end %}

      %block = {{ expression.block.stringify }}

      PowerAssert::MethodCall.new(
        {{ expression.name.stringify }}, {{ expression }},
        %receiver, %args, %named_args, %block
      )
    {% elsif expression.is_a?(Nop) %}
      PowerAssert::NopNode.new
    {% elsif expression.is_a?(StringLiteral) %}
      PowerAssert::Node.new({{ expression.id.stringify }}.inspect, {{ expression }})
    {% elsif expression.is_a?(SymbolLiteral) %}
      PowerAssert::Node.new({{ expression }}.inspect, {{ expression }})
    {% elsif expression.is_a?(RangeLiteral) %}
      PowerAssert::Node.new({{ expression }}.inspect, {{ expression }})
    {% else %}
      PowerAssert::Node.new({{ expression.id.stringify }}, {{ expression }})
    {% end %}
  end
end

include PowerAssert
