#!/bin/bash

# Checks if a floating-point number is less than another.
#
# Parameters:
#   $1 -> First floating-point number
#   $2 -> Second floating-point number
#
# Returns:
#   0 if the first number is less than the second, 1 otherwise
#
# Examples:
#   is_float_less_than 3.14 4.0  => returns 0
#   is_float_less_than 5.0 2.0   => returns 1
is_float_less_than() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'
}

# Checks if a floating-point number is greater than another.
#
# Parameters:
#   $1 -> First floating-point number
#   $2 -> Second floating-point number
#
# Returns:
#   0 if the first number is greater than the second, 1 otherwise
#
# Examples:
#   is_float_greater_than 5.0 2.0  => returns 0
#   is_float_greater_than 3.14 4.0 => returns 1
is_float_greater_than() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'
}

# Checks if a floating-point number is greater than or equal to another.
#
# Parameters:
#   $1 -> First floating-point number
#   $2 -> Second floating-point number
#
# Returns:
#   0 if the first number is greater than or equal to the second, 1 otherwise
#
# Examples:
#   is_float_greater_or_equal 5.0 2.0  => returns 0
#   is_float_greater_or_equal 3.14 4.0 => returns 1
is_float_greater_or_equal() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'
}
