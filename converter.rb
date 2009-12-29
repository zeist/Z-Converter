#!/usr/bin/env ruby
#ENV['RUBYDIR']
load File.dirname(__FILE__)+"/vars.rb"
load $configPath+"/config.rb"
load $tagReaderPath+"/tagreader.rb"
class Converter
	def initialize()
		@outpath = "./"
		@delete = "no"
		@config = Config.new
		@oconf = Config.new
		@iconf = Config.new
	end

	#
	# Input Codec
	# 
	def setInput(i_input)
		#Write out input codec name
		if @config.getOption("Verbose") == "yes"
			puts "Input: " + i_input
		end

		#Load Input Config File
		@iconf.Load($configdir+"/"+i_input+".conf")
	end

	#
	# Output Codec
	#
	def setOutput(i_output)
		#Write out output codec name
		if @config.getOption("Verbose") == "yes"
			puts "Output: " + i_output
		end

		#Load Output Config File
		@oconf.Load($configdir+"/"+i_output+".conf")
	end

	#
	# Read Config
	#
	def readConfig(i_path)
		#Load Config File
		@config.Load(i_path)

		#Input
		setInput(@config.getOption("input"))

		#Output
		setOutput(@config.getOption("output"))
	end

	#
	# Read Tags From File
	#
	def readTags(i_file)
		
		tr = Tagreader.new
		tr.readTags(i_file, @config.getOption("input"))
		
		@artist = tr.artist
		@title = tr.title
		@album = tr.album
		@date = tr.date
		@genre = tr.genre
		@tracknumber = tr.tracknumber

		#Output Information
		if @config.getOption("Verbose") == "yes"
			puts "Artist: "+@artist
			puts "Album: "+@album
			puts "Title: "+@title
			puts "Tracknumber: "+@tracknumber	
			puts "Date: "+@date
			puts "Genre: "+@genre
		end
	end

	#
	# Create Command Line
	#
	def makeCommandLine(file)
		#Initial part of each tag writing
		initial = @oconf.getOption("initial")
		puts initial

		#Tagwrite = The part of the command line that is for writing tags
		tagwrite = initial +  " \""+@oconf.getOption("title")+ "="+@title+"\" "
		tagwrite += initial + " \""+@oconf.getOption("tracknumber")+"="+@tracknumber+"\" "
		tagwrite += initial + " \""+@oconf.getOption("genre")+"="+@genre+"\" "
		tagwrite += initial + " \""+@oconf.getOption("date")+"="+@date+"\" "
		tagwrite += initial + " \""+@oconf.getOption("artist")+"="+@artist+"\" "
		tagwrite += initial + " \""+@oconf.getOption("album")+"="+@album+"\" "

		#Temporary wavfile
		wavfile = file[0..file.size-6]+".wav"

		#Output File
		outfile = @folder + "/"+@tracknumber + " - " +@title

		#Command line
		command = @oconf.getOption("command")+" " +tagwrite+ @oconf.getOption("options")+" \"" + wavfile + "\" -o \""+outfile+"\""
		if @config.getOption("Verbose") == "yes"
			puts command
		end

		return command

	end

	#
	# Process File
	#
	def ProcessFile(i_file)

		#Read file tags to variables
		readTags(i_file)

		#Setup output folder
		@folder= "["+@date+"] "+@album

		if @config.getOption("Verbose") == "yes"
			puts @folder
		end

		#If it's on the first flac file - create output folder
		if @cnt == 0 && @config.getOption("simulate") == "no"
			system("mkdir \""+@folder+"\"")
		end
		
		#Setup decompression command line
		decompress = @iconf.getOption("unpack") + " \""+i_file+"\"";

		if @config.getOption("Verbose") == "yes"
			puts decompress
		end

		#Decompress
		if @config.getOption("simulate") == "no"
			system(decompress)
		end

		#Setup compression command line
		command = makeCommandLine(i_file)

		#Compress
		if @config.getOption("simulate") == "no"
			system(command)
		end

		#Remove temporary wav file
		if @config.getOption("simulate") == "no"
			wavfile = i_file[0..i_file.size-6]+".wav"
			system("rm \""+wavfile+"\"")
		end

	end

	#
	# Execute
	#
	def Execute
		@cnt = 0
		Dir.foreach(".") { |file|\
		if file != "." && file != ".."
			#Only process flac files
			if(file[file.size-@iconf.getOption("extension").size..file.size-1].downcase==@iconf.getOption("extension").strip)
				ProcessFile(file)
				@cnt+=1
			end
		end
		}
 		puts "Files Processed: " + @cnt.to_s
		if @cnt > 0
			if @config.getOption("Verbose") == "yes"
				puts "wvgain -a \""+@folder+"/*.wv\""
			end
			system("wvgain -a \""+@folder+"/\"*.wv")
		end
	end
end
rarm = Converter.new
rarm.readConfig($configdir+"/am.conf")
rarm.Execute
