require "spec"

module PowerAssert
  Operators = [
    "!", "!=", "%", "&", "*", "**", "+", "-", "/", "<", "<<", "<=", "<=>", "==", "===",
    ">", ">=", ">>", "^", "|", "~"
  ]

  macro assert(expected, file = __FILE__, line = __LINE__)
    %result = {{ expected }}

    unless %result
      %message = ""

      {% if expected.is_a?(Call) && Operators.any? { |op| op == expected.name.stringify } %}
        %expected = {{ expected.receiver.id.stringify }}
        %expected_val = {{ expected.receiver }}
        %actual = {{ expected.args[0].id.stringify }}
        %actual_val = {{ expected.args[0].id }}
        %op = {{ expected.name.stringify }}

        %message += build_message_for_op(
          %op,
          %expected, %expected_val,
          %actual, %actual_val,
          %result
        )
      {% elsif expected.is_a?(Call) %}
        %receiver = {{ expected.receiver.id.stringify }}
        %receiver_val = {{ expected.receiver }}
        %method = {{ expected.name.stringify }}
        %found_block = {{ expected.block.is_a?(Block) }}

        {% if expected.args.length > 0 %}
          %arg_names = [
            {% for arg in expected.args %}
              {{ arg.id.stringify }},
            {% end %}
          ]

          %arg_vals = [
            {% for arg in expected.args %}
              {{ arg.id }},
            {% end %}
          ]
        {% else %}
          %arg_names = [] of String
          %arg_vals = [] of Int32
        {% end %}

        %message += build_message_for_call(
          %method,
          %receiver, %receiver_val,
          %arg_names, %arg_vals,
          %found_block, %result
        )
      {% end %}

      fail %message, {{ file }}, {{ line }}
    end

    %result
  end

  private def build_message_for_op(op, expected, expected_val, actual, actual_val, result)
    expected_length = expected.length
    op_length = op.length
    indent = " " * 2

    String.build do |message|
      message << indent
      message << expected
      message << " " + op + " "
      message << actual
      message << "\n"

      message << indent
      message << "|"
      message << " " * expected_length
      message << "|"
      message << " " * op_length
      message << "|"
      message << "\n"

      message << indent
      message << "|"
      message << " " * expected_length
      message << "|"
      message << " " * op_length
      message << actual_val.inspect
      message << "\n"

      message << indent
      message << "|"
      message << " " * expected_length
      message << result.inspect
      message << "\n"

      message << indent
      message << expected_val.inspect
      message << "\n"
    end
  end

  private def build_message_for_call(method, recv, recv_val, arg_names, arg_vals, found_block, result)
    indent = " " * 2

    String.build do |message|
      message << indent
      if recv.length > 0
        message << recv
        message << "."
      end
      message << method
      if arg_names.length > 0
        message << "("
        message << arg_names.join(", ")
        message << ")"
      end
      if found_block
        message << " { ... }"
      end
      message << "\n"

      message << indent
      if recv.length > 0
        message << "|"
        message << " " * (recv.length)
      end
      message << "|"
      message << " " * method.length
      arg_names.each do |arg|
        message << "|"
        message << " " * (arg.length + 1)
      end
      message << "\n"

      arg_vals.reverse.each_with_index do |val, idx|
        message << indent
        if recv.length > 0
          message << "|"
          message << " " * (recv.length)
        end
        message << "|"
        message << " " * method.length
        stay_args = arg_names[0 ... (arg_names.length - (idx + 1))]
        stay_args.each do |stay_arg|
          message << "|"
          message << " " * (stay_arg.length + 1)
        end
        message << val.inspect
        message << "\n"
      end

      message << indent
      if recv.length > 0
        message << "|"
        message << " " * (recv.length)
      end
      message << result.inspect
      message << "\n"

      if recv.length > 0
        message << indent
        message << recv_val.inspect
        message << "\n"
      end
    end
  end
end

include PowerAssert
