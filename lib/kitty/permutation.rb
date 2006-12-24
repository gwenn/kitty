# Copyright (c) 2005 El Barto.
#
# Licensed under the same terms as Ruby.

module Kitty
  # See http://permutation.rubyforge.org (Florian Frank)
  # But its factorial method does not work in $SAFE = 4 mode!
  class Permutation
    def initialize(size)
      @size = size
      @last = factorial(size) - 1
    end

    def each
        0.upto(@last) do |r|
            yield unrank_indices(r)
        end
    end

    private
    def factorial(n)
        f = 1
        for i in 2..n do f *= i end
        f
    end

    def unrank_indices(m)
        result = Array.new(@size, 0)
        for i in 0...@size
            f = factorial(i)
            x = m % (f * (i + 1))
            m -= x
            x /= f
            result[@size - i - 1] = x
            x -= 1
            for j in (@size - i)...@size
                result[j] += 1 if result[j] > x
            end
        end
        result
    end
  end
end
