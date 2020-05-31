%{
  #include <cstdio>
  #include <iostream>

  extern int yylex();
  extern int yyparse();
  extern FILE *yyin;
  void yyerror(const char *s);
%}

%start method_body

%token IDENTIFIER
%token INT_NUM
%token FLOAT_NUM
%token ARITH_OP
%token BOOL_OP
%token REL_OP
%token IF
%token ELSE
%token WHILE
%token TRUE
%token FALSE
%token INT
%token FLOAT
%token EQUAL
%token COMMA
%token SEMICOLON
%token LEFT_BRACKET
%token RIGHT_BRACKET
%token LEFT_BRACE
%token RIGHT_BRACE

%%
method_body: 
            %empty
            |statement_list
            ;

statement_list: 
                statement
                |statement_list statement
                ;

statement:  
        declaration 
        |if 
        |while 
        |assignment
        ;

declaration: primitive_type IDENTIFIER SEMICOLON;

primitive_type: 
                INT 
                |FLOAT
                ;

if: 
    IF LEFT_BRACKET 
    boolean_expression RIGHT_BRACKET
    LEFT_BRACE statement_list 
    RIGHT_BRACE ELSE LEFT_BRACE 
    statement_list RIGHT_BRACE
    ;

while: 
        WHILE LEFT_BRACKET
        boolean_expression RIGHT_BRACKET
        LEFT_BRACE statement_list RIGHT_BRACE
        ;

assignment: IDENTIFIER EQUAL expression SEMICOLON;

expression:
            INT_NUM
            |FLOAT_NUM
            |IDENTIFIER
            |expression ARITH_OP expression
            |LEFT_BRACKET expression RIGHT_BRACKET
            ;

boolean_expression: 
                    TRUE 
                    |FALSE
                    |expression BOOL_OP expression
                    |expression REL_OP expression


%%

int main(int argc, char** argv) {
  // Open a file handle to a particular file:
  FILE *myfile = fopen(argv[1], "r");
  // Make sure it is valid:
  if (!myfile) {
    std::cout << "I can't open file!" << std::endl;
    return -1;
  }
  // Set Flex to read from it instead of defaulting to STDIN:
  yyin = myfile;
  
  // Parse through the input:
  yyparse();
  
}

void yyerror(const char *s) {
  std::cout << "EEK, parse error!  Message: " << s << std::endl;
  std::exit(-1);
}