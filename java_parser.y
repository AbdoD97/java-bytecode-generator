%{
  #include <cstdio>
  #include <iostream>
  #include "semantic_actions_utils.h"
  #include <string.h>

  using namespace semantic_actions_util;

  extern int yylex();
  extern int yyparse();
  extern FILE *yyin;
  extern int line_num;
  void yyerror(const char *s);
%}

%start method_body
%error-verbose

%token<id> IDENTIFIER
%token INT_NUM
%token FLOAT_NUM
%token<smallString> ARITH_OP
%token <smallString>BOOL_OP
%token <smallString>REL_OP
%token IF
%token ELSE
%token WHILE
%token TRUE
%token FALSE
%token INT
%token FLOAT

%type<varType> primitive_type 
%type<expressionType> expression;
%type<booleanExpressionType> boolean_expression;

%code requires{
    #include <unordered_set>
}

%union{
    char smallString[20];
	  char id[30];
    int varType;
    struct ExpressionType{
      int varType;
      std::unordered_set<int> trueList;
      std::unordered_set<int> falseList;
    }expressionType;
    struct BooleanExpressionType{
    	std::unordered_set<int> trueList;
      std::unordered_set<int> falseList;
    }booleanExpressionType;
}

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

declaration: primitive_type IDENTIFIER ';' {
  if(checkIfVariableExists($2)) {
    yyerror(string{"variable "+string{$2}+" is already declared"}.data());
  } else {
    declareVariable($2, $1);
  }
};

primitive_type: 
                INT { $$ = VarType::INT_TYPE; }
                |FLOAT {$$ = VarType::FLOAT_TYPE; }
                ;

if: 
    IF '(' boolean_expression ')'
    '{' statement_list '}' 
    ELSE '{' statement_list '}'
    ;

while: 
        WHILE '(' boolean_expression ')'
        '{' statement_list '}'
        ;

assignment: IDENTIFIER '=' expression ';'{
  cout<<"asg: "<<$1<<" "<<" "<<$3.varType<<endl;
  if(checkIfVariableExists($1)) {
    //Check if the two sides have the same type
    if(varToVarIndexAndType[$1].second == $3.varType) {
      if(varToVarIndexAndType[$1].second == VarType::INT_TYPE) {
        appendToCode("istore_"+varToVarIndexAndType[$1].first);
      } else {//Only int and float are supported
        appendToCode("fstore_"+varToVarIndexAndType[$1].first);
      }
    } else { // case when the two types aren't the same
      //TODO Cast the two variables
    }
  } else {
    yyerror(string{"variable "+string{$1}+" not declared"}.data());
  }
};

expression:
            INT_NUM {$$.varType = VarType::INT_TYPE;  } 
            |FLOAT_NUM {$$.varType = VarType::FLOAT_TYPE ; }
            |IDENTIFIER {
            // check if the identifier already exist to load or not
            	if(checkIfVariableExists($1)) {
            		$$.varType = varToVarIndexAndType[$1].second;
            		if($$.varType == VarType::INT_TYPE ) {
            		  //write iload + identifier
					        appendToCode("iload_" + to_string(varToVarIndexAndType[$1].first));
            		}
            		else {
            		  //float 
						      //write fload + identifier
					        appendToCode("fload_" + to_string(varToVarIndexAndType[$1].first));
            		}
            	}
            	else {//it's not declared at all
			                string err = "identifier: "+string{$1}+" isn't declared in this scope";
                      yyerror(err.c_str());
            	}
            }
            |expression ARITH_OP expression { 
                if ($1.varType == $3.varType ) {
                  if ($1.varType == VarType::INT_TYPE)  
                    appendToCode("i" + getOperationCode($2));
                  else //it's float          
                    appendToCode("f" + getOperationCode($2));
                }
			        }
            |'(' expression ')' {$$.varType = $2.varType;}
            ;

boolean_expression: 
                    TRUE {
                    // $$.trueList = new vector<int> ();
                    $$.trueList.insert(static_cast<int>(outputCode.size()));
                    // $$.falseList = new vector<int>();
                    // write code goto line #
					          appendToCode("goto ");
                    }
                    |FALSE {
                    // $$.trueList = new vector<int> ();
                    // $$.falseList= new vector<int>();
                    $$.falseList.insert(static_cast<int>(outputCode.size()));
                    // write code goto line #
					          appendToCode("goto ");
                    }
                    |expression BOOL_OP expression {
                    if(!strcmp($2, "&&")) {
                        $$.trueList = $3.trueList;
                        // $$.falseList = merge($1.falseList,$3.falseList);
                      }
                    else if (!strcmp($2,"||")) {
                        // $$.trueList = merge($1.trueList, $3.trueList);
                        $$.falseList = $3.falseList;
                      }
                    }
                    |expression REL_OP expression {
                    // $$.trueList = new vector<int>();
                    $$.trueList.insert(static_cast<int>(outputCode.size()));
                    // $$.falseList = new vector<int>();
                    $$.falseList.insert(static_cast<int>(outputCode.size()+1));
                    appendToCode(getOperationCode($2)+ " ");
                    appendToCode("goto ");
                    }
                    ;
%%

string genLabel()
{
	return "L_"+to_string(labelsCount++);
}


int main(int argc, char** argv) {
  // Open a file handle to a particular file:
  if (argc == 1){
    std::cout << "No file's specified to open ! Please provide a valid file name" << std::endl;
    return -1;
  }
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
  std::cout<<"Yay ! Parser completed working successfully."<<std::endl;
}

void yyerror(const char *s) {
  std::cout << "Ouch, I found a parse error on line "<< line_num <<" ! Error Message: " << s << std::endl;
  std::exit(-1);
}
