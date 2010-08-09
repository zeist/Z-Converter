#!/usr/bin/env ruby

system("git submodule init")
system("git submodule update")

Dir.chdir("external")

Dir.foreach(".") { |file|\
if file != "." && file != ".."
  puts file
  Dir.chdir(file)
  puts Dir.getwd()
  system("./externals.rb")
  Dir.chdir("..")
end
}
