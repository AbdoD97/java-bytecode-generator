build_flex:
	@flex -o lexical_analyzer.yy.c java_lexical_analyzer.l

build_bison:
	@bison -b parser -d java_parser.y

build_exec:
	@g++ parser.tab.c lexical_analyzer.yy.c -o java_compiler.out

build_jasmin: 
	@java -jar jasmin.jar java_bytecode.j

build_all:
	@bison -b parser -d java_parser.y
	@flex -o lexical_analyzer.yy.c java_lexical_analyzer.l 
	@g++ parser.tab.c lexical_analyzer.yy.c -o java_compiler.out
	@java -jar jasmin.jar java_bytecode.j
	@java java_class
