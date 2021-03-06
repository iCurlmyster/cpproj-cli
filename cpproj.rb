=begin

Create a command line interface tool to setup up a cpp project and add/create/remove class files in makefile and project with default constructors and destructors.
Be able to add/remove libraries to makefile. Be able to build project and run it.
Be able to add fields when creating class files which will also create getters and setters for them.

=end

# string for libraries added (future ability)
$libs = ""
# array for cpp files in project
$files = Array.new
# array for object files in project
$obj_files = Array.new
# project name
$proj_name = ""
# standard of C++ used
$std_cpp = "-std=c++11"
# compiler used
$comp = "clang++"
# flags used for compilation
$cflags = "-Wall -c"

# function to handle the initial arguments passed
# @param arg
def initial_argument arg
	case arg
	when "init"
		if ARGV.count > 1 then
			create_project ARGV[1]
		else
			puts "Must supply a project name as argument."
		end
	when "create_class"
		if ARGV.count > 2 then
			# implement function to add fields to class when creating it
			create_class ARGV[1], ARGV.drop(2)
		elsif ARGV.count > 1 
			create_class ARGV[1]
		else
			puts "Must supply a class name as argument."
		end
	when "remove_class"
		if ARGV.count > 1 then
			remove_class ARGV[1]
		else
			puts "Must supply a class name as argument."
		end
	when "build"
		`make clean`
		`make`
		puts "Build complete!"
	when "run"
		run_project
	when "help"
		show_help
	else
		show_help
	end
end

# Function that displays the help menu
def show_help

	puts "-------------------------------"
	puts ""
	puts "Usage: ruby cpproj.rb [command] [argument]"
	puts ""
	puts "commands:"
	puts "	init		Argument passed: name of porject. Initialize a cpp project."
	puts "			Creates project, build, and src folders. Inside project "
	puts "			folder a Makefile. Inside src folder a Main.cpp file."
	puts ""
	puts "	create_class	Argument passed: name of class. Creates a .cpp and .hpp file"
	puts "			with defualt constructor and destructor setup for you. Adds"
	puts "			file to Makefile as well."
	puts ""
	puts "	remove_class	Argument passed: name of class. Deletes .cpp and .hpp files"
	puts "			of class name passed. Removes references of class in Makefile"
	puts "			as well."
	puts ""
	puts "	build		No argument. Command will compile project and place object "
	puts "			files and executable in build directory. This command cleans"
	puts "			the build directory each time ran, to clear out previous "
	puts "			contents."
	puts ""
	puts "	run		Same as build but will also run your executable."
	puts ""
	puts "	help		Shows this menu."
	puts ""
	puts "-------------------------------"
end

# Function that creates the initial project setup
# @param name
def create_project name
	puts "creating project..."
	if !File.directory?("./"+name) then
		Dir.mkdir name, 0700
		$files<<"./src/Main"
		$obj_files << "./build/Main"
		create_makefile "./build/#{name}"
		puts "#{name}/src"
		Dir.mkdir "#{name}/src", 0700
		puts "#{name}/build"
		Dir.mkdir "#{name}/build", 0700
		puts "#{name}/src/Main.cpp"
		File.write "#{name}/src/Main.cpp", "#include <iostream>\nusing namespace std;\n\nint main(int argc, const char* argv[]) {\n\tcout<<\"Hello World!\"<<endl;\n\treturn 0;\n}" 
		puts "Done!"
	else
		puts "#{name} directory already exists"
	end
end

# Function that is used for creating and updating the Makefile for project
# @param name
def create_makefile name
str = "CC=#{$comp}
CFLAGS=#{$cflags}
TARGET=#{name}
OBJECTS="
tmp = ""
$files.each do |f|
	tmp = tmp + "#{f}.o "
end
str = str + tmp + "\n"
str = str + "COBJS="
tmp = ""
$obj_files.each do |f|
	tmp = tmp + "#{f}.o "
end
str = str + tmp + "\nLIBS=#{$libs}\n"
str = str + "all: $(TARGET)
$(TARGET): $(OBJECTS)
	$(CC) #{$std_cpp} $(COBJS) $(LIBS) -o $(TARGET)
"
$files.each do |f|
str = str + "#{f}.o: #{f}.cpp
	$(CC) $(CFLAGS) #{$std_cpp} #{f}.cpp
	mv #{f[/^.+\/(.+)$/,1]}.o ./build/#{f[/^.+\/(.+)$/,1]}.o\n"
end
str = str + "clean: 
	rm -Rf ./build/*.o $(TARGET)
"
if File.exist? "Makefile" then
	File.write "Makefile", str
	puts "Updated Makefile"
else
	File.write "#{name[/\.\/build\/(.+)/,1]}/Makefile", str
	puts "#{name[/\.\/build\/(.+)/,1]}/Makefile"
end
end

# Function that takes care of creating new classes for project.
# Will update Makefile also when ran
# @param name
def create_class name, arr=nil

	if File.exist?("Makefile") && File.directory?("./src") then
		if File.exist?("./src/#{name}.cpp") || File.exist?("./src/#{name}.hpp") then
			puts "There is already #{name}.cpp or #{name}.hpp created."
		else
			if arr == nil then
				puts "./src/#{name}.cpp"
				File.write "./src/#{name}.cpp", cpp_setup(name)
				puts "./src/#{name}.hpp"
				File.write "./src/#{name}.hpp", hpp_setup(name)
				get_objects_from_make
				$files << "./src/#{name}"
				$obj_files << "./build/#{name}"
				create_makefile $proj_name
			else
				
			end
		end
	else
		puts "src directory and Makefile are not in immediate directory. Move to top directory in project or create a project if you have not yet."
		show_help
	end

end

def remove_class name
	if File.exist?("Makefile") && File.directory?("./src") then
		if File.exist?("./src/#{name}.cpp") || File.exist?("./src/#{name}.hpp") then
			puts "removing ./src/#{name}.cpp"
			File.delete "./src/#{name}.cpp"
			puts "removing ./src/#{name}.hpp"
			File.delete "./src/#{name}.hpp"
			get_objects_from_make
			$files = $files.delete_if {|x| x == "./src/#{name}"}
			$obj_files = $obj_files.delete_if {|x| x == "./build/#{name}"}
			create_makefile $proj_name
		else
			puts "The files #{name}.cpp or #{name}.hpp do not exist."
		end
	else
		puts "src directory and Makefile are not in immediate directory. Move to top directory in project or create a project if you have not yet."
		show_help
	end

end

# Function to grab the current TARGET name and OBJECTS and COBJS from Makefile
def get_objects_from_make
	open("Makefile").each_line do |line|
		$proj_name = line[/TARGET=(.+)/,1] if line =~ /TARGET=.+/
		if line =~ /CC=.+/ then
			$comp = line[/CC=(.+)/,1]
		elsif line =~ /CFLAGS=.+/
			$cflags = line[/CFLAGS=(.+)/,1]
		elsif line =~ /OBJECTS=.+/
			tmp = line[/OBJECTS=(.+)/,1].split ".o "
			$files = tmp
		elsif line =~ /COBJS=.+/
			tmp = line[/COBJS=(.+)/,1].split ".o "
			$obj_files = tmp
		elsif line =~ /LIBS=.+/
			$libs = line[/LIBS=(.+)/,1]
		elsif line =~ /all:.+/
			break
		end
	end
end

# Function to handle running the project or to build and run the project
def run_project
	if File.exist?("Makefile") && File.directory?("./build") then
		open("Makefile").each_line do |line|
			if line =~ /TARGET=.+/ then
				ex = line[/TARGET=(.+)/,1]
				`make clean`
				`make`
				exec("#{ex}")
			end
		end
		puts "There is no TARGET set in Makefile."
	else
		puts "build directory and Makefile are not in immediate directory. Move to top directory in project or create a project if you have not yet."
	end
end

# Function to setup generic hpp file.
# @param name
def hpp_setup name

return "#ifndef #{name.upcase}_HPP
#define #{name.upcase}_HPP

class #{name} {

public:
	#{name}();
	~#{name}();

};

#endif
"
end

# Function to setup generic cpp file.
# @param name
def cpp_setup name
return "#include \"#{name}.hpp\"

#{name}::#{name}() {

}

#{name}::~#{name}() {

}
"
end

# make sure arguments or passed or show help if none.
if ARGV.count > 0 then
	initial_argument ARGV[0]
else
	show_help
end
