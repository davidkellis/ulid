require "bigdecimal"
require "bigdecimal/util"   # for Integer#to_d

ONE = 1.to_d

def p(n, k, d)
  n = n.to_d
  k = k.to_d
  d = d.to_d
  d_minus_n_times_k = d - n * k
  ONE - (1..(n+1)).map {|i| (d_minus_n_times_k - i) / d }.reduce(ONE, :*)
end

def print_report(bitspace = 80)
  puts "report for #{bitspace} bits of entropy"
  d = BigDecimal(2**bitspace)
  1.step(30, 2).each do |g|
    k = g - 1
    n = 1000 / g
    puts "g=#{g} n=#{n} k=#{k} p(n, k, d)=#{p(n, k, d).truncate(40)}"
  end
end

# this program reimplements the results from https://12ft.io/proxy?q=https%3A%2F%2Fmedium.com%2Fzendesk-engineering%2Fhow-probable-are-collisions-with-ulids-monotonic-option-d604d3ed2de
def main
  print_report(32)
  puts
  print_report(80)
end

main