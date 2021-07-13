%code requires{
#include <string>
using namespace std;

}
%{
          
    #include <stdio.h>
    #include <iostream>
    #include <stdlib.h>
    #include <string>
    #include <cstring>
    #include <fstream>
    #include <map>


    using namespace std;


    struct varialbe_s {
        string value;
        int type; // 0:int 1:char 2:void
        int scope;
        int place;
    };


    map<pair<string, int>, struct varialbe_s> variables;
    map<int,int> scopes;

    int current_dtype;
    int is_declaration = 0;
    int is_loop = 0;
    int is_func = 0;
    int func_type;
    int out = 0;
    int rhs = 0;
    int scopeNo=0;
    int prevscopeNo=0;
    int clacStart=0;
    int conditionNo=0;
    int loopNo=0;


    extern int yylex();
    extern FILE* yyin;
    void yyerror(const char* s);
    int yyparse();
    void add_var(string value,string name, int type, int scope);
    int get_last_var_pos(int scope);
    int add_scope(int parent);

    string code_gen_init_func(int scope);
    string code_gen_end_func(int scope);


    ofstream code_file("code.asm");

%}


%define parse.error verbose

%union {
     struct t {
          std::string *  _val;
          int _type; // 0:int 1:char 2:void
          int _scope;
          std::string * _asm;
     }token;
}


/*==============================================================types===============================================================*/

%token <token>   TOKEN_ID TOKEN_RETURN TOKEN_MAIN TOKEN_FOR TOKEN_WHILE TOKEN_ELSEIF TOKEN_ELSE TOKEN_IF TOKEN_CONTINUE TOKEN_BREAK TOKEN_INTTYPE TOKEN_CHARTYPE TOKEN_VOIDTYPE;
%token <token>   TOKEN_CHARCONST;
%token <token>   TOKEN_ASSIGNOP TOKEN_LEFTPAREN TOKEN_RIGHTPAREN TOKEN_LS TOKEN_GR TOKEN_DOT TOKEN_COMMA TOKEN_LB TOKEN_RB;
%token <token>   TOKEN_INTCONST;
%token <token>   TOKEN_PLUS TOKEN_MINUS TOKEN_MUL TOKEN_DIV TOKEN_POW;
%token <token>   TOKEN_LOGICAND TOKEN_LOGICOR TOKEN_LOGICNOT TOKEN_BITWISEAND TOKEN_BITWISEOR;
%token <token>   TOKEN_EQ TOKEN_NOTEQ TOKEN_LSEQ TOKEN_GREQ



%type <token> constants typeSpecifier  identifier   declaration_list sub_decl elseif  conditionStmtElseIf 
%type <token> sub_expr program globalVars loopStmt conditionStmt 
%type <token> arithmetic_expr stmt
%type <token> assignment_expr
%type <token> functionCall arg argumentList arguments
%type <token> array_access expression singleStmt statements  array_init array_init_vars
%type <token> lhs compoundStmt  function declaration parameter parameter_list


/*==============================================================precedances===============================================================*/

%left TOKEN_COMMA
%right TOKEN_ASSIGNOP
%left TOKEN_LOGICOR
%left TOKEN_LOGICAND
%left TOKEN_BITWISEOR TOKEN_BITWISEAND
%left TOKEN_EQ TOKEN_NOTEQ
%left TOKEN_GR TOKEN_LS TOKEN_LSEQ TOKEN_GREQ
%left TOKEN_PLUS TOKEN_MINUS
%left TOKEN_MUL TOKEN_DIV
%left TOKEN_POW
%right TOKEN_LOGICNOT

%nonassoc UMINUS



/*==============================================================grammar===============================================================*/

%start program

%%

program:                globalVars  {
    $$._asm = new string(*($1._asm));

    code_file << *($$._asm);

}
                        ;


globalVars:             typeSpecifier   identifier   TOKEN_ASSIGNOP   constants TOKEN_DOT   globalVars {
    
    
    add_var(*($4._val),*($2._val), $4._type, 0);
    
    string tmp;

    tmp = string("\n") + string(*($2._val)) + string(":") + string("\n\t.word\t") + string(*($4._val));
    $$._asm = new string(tmp + *$6._asm);

}                                                                                       
                        |function {$$._asm = new string(*$1._asm);}
                        ;

function:               typeSpecifier   TOKEN_MAIN {func_type = current_dtype;is_declaration = 0;} TOKEN_LEFTPAREN {scopeNo = add_scope(scopeNo);}  TOKEN_RIGHTPAREN {is_declaration = 0;is_func = 1;}  compoundStmt {
    is_func = 0;
    if ($1._type != 0 )
        yyerror("main function must be of type INT");
    
    
    $$._asm = new string(string("\nmain") + string(":") + code_gen_init_func(scopeNo) + *($8._asm) + code_gen_end_func(scopeNo));


}   
                        |typeSpecifier   identifier   TOKEN_LEFTPAREN   argumentList   TOKEN_RIGHTPAREN   compoundStmt   function 
                        ;

argumentList:           arguments 
                        | {}
                        ;

arguments:              arguments   TOKEN_COMMA   arg 
                        |arg
                        ;

arg:                    typeSpecifier   identifier       
                        ;


statements:             statements   stmt 
                        | {}
                        ;

stmt:                   compoundStmt 
                        |singleStmt 
                        ;

compoundStmt:           TOKEN_LS   statements   TOKEN_GR {$$._asm = new string("\n\tnop");} 
                        ;



singleStmt:             conditionStmt 
                        |loopStmt 
                        |declaration 
                        |functionCall   TOKEN_DOT 
	                    |TOKEN_RETURN   TOKEN_DOT 
                        |TOKEN_CONTINUE   TOKEN_DOT 
                        |TOKEN_BREAK   TOKEN_DOT 
                        |TOKEN_RETURN   sub_expr   TOKEN_DOT 
                        ;         

conditionStmt:          TOKEN_IF  TOKEN_LEFTPAREN   expression   TOKEN_RIGHTPAREN   compoundStmt 
                        |TOKEN_IF  TOKEN_LEFTPAREN  expression    TOKEN_RIGHTPAREN   compoundStmt   TOKEN_ELSE   compoundStmt 
                        |TOKEN_IF  TOKEN_LEFTPAREN  expression    TOKEN_RIGHTPAREN   compoundStmt   conditionStmtElseIf
                        |TOKEN_IF  TOKEN_LEFTPAREN  expression    TOKEN_RIGHTPAREN   compoundStmt   conditionStmtElseIf TOKEN_ELSE   compoundStmt 
                        ;

conditionStmtElseIf:    elseif TOKEN_ELSEIF   TOKEN_LEFTPAREN  expression    TOKEN_RIGHTPAREN   compoundStmt
                        ;

elseif:                 elseif TOKEN_ELSEIF   TOKEN_LEFTPAREN  expression    TOKEN_RIGHTPAREN   compoundStmt
                        | {}
                        ;

loopStmt:               TOKEN_FOR   TOKEN_LEFTPAREN   typeSpecifier   sub_decl   TOKEN_DOT   expression TOKEN_DOT  expression   TOKEN_RIGHTPAREN   compoundStmt 
                        |TOKEN_WHILE   TOKEN_LEFTPAREN   expression   TOKEN_RIGHTPAREN   compoundStmt 
                        ;


functionCall:           identifier   TOKEN_LEFTPAREN   parameter_list   TOKEN_RIGHTPAREN 
                        |identifier TOKEN_LEFTPAREN TOKEN_RIGHTPAREN 
                        ;

parameter_list:         parameter_list   TOKEN_COMMA   parameter 
                        |parameter 
                        ;

parameter:              sub_expr            
                        ;

declaration:            typeSpecifier   declaration_list   TOKEN_DOT 
			            |declaration_list   TOKEN_DOT 
                        ;

declaration_list:       declaration_list   TOKEN_COMMA   sub_decl 
		                |sub_decl 
                        ;

sub_decl:               assignment_expr 
                        |identifier           
                        |array_access 
                        ;

expression:             sub_expr 	                                    
		                ;

sub_expr:               sub_expr   TOKEN_GR   sub_expr 
                        |sub_expr   TOKEN_LS   sub_expr 
                        |sub_expr   TOKEN_EQ   sub_expr 
                        |sub_expr   TOKEN_NOTEQ   sub_expr              
                        |sub_expr TOKEN_LSEQ sub_expr               
                        |sub_expr TOKEN_GREQ sub_expr               
                        |sub_expr TOKEN_LOGICAND sub_expr           
                        |sub_expr TOKEN_LOGICOR sub_expr            
                        |TOKEN_LOGICNOT sub_expr                    
                        |arithmetic_expr				        
                        |assignment_expr                            
                        ;

assgn :                 TOKEN_ASSIGNOP
                        ;

assignment_expr :       lhs assgn  arithmetic_expr         
                        |lhs assgn  functionCall            
                        |lhs assgn array_init     
                        ;



lhs:                    identifier                
                        |array_access              
                        ;

identifier:             TOKEN_ID {
    $$._val = new string(*($1._val));
}                 
                        ;

arithmetic_expr:        arithmetic_expr   TOKEN_PLUS   arithmetic_expr        
                        |arithmetic_expr   TOKEN_MINUS   arithmetic_expr       
                        |arithmetic_expr   TOKEN_MUL   arithmetic_expr         
                        |arithmetic_expr   TOKEN_DIV   arithmetic_expr         
                        |arithmetic_expr   TOKEN_POW   arithmetic_expr         
                        |arithmetic_expr   TOKEN_BITWISEAND   arithmetic_expr         
                        |arithmetic_expr   TOKEN_BITWISEOR   arithmetic_expr         
                        |TOKEN_LEFTPAREN   arithmetic_expr   TOKEN_RIGHTPAREN   
                        |TOKEN_MINUS   arithmetic_expr   %prec UMINUS           
                        |identifier                                         
                        |constants 
                        |array_access 
                        ;

array_init_vars:        array_init_vars TOKEN_COMMA constants 
                        |constants
                        ;

array_init:             TOKEN_LS array_init_vars TOKEN_GR  
                        ;

array_access:           identifier TOKEN_LB constants TOKEN_RB                            
                        ;



typeSpecifier:          TOKEN_INTTYPE {$$._type = 0;is_declaration = 1;}
                        |TOKEN_CHARTYPE {$$._type = 1;is_declaration = 1;}
                        |TOKEN_VOIDTYPE {$$._type = 2;is_declaration = 1;}
                        ;

constants:              TOKEN_INTCONST {$$._val = new string(*($1._val)); $$._type = 0;  }
                        |TOKEN_CHARCONST {$$._val = new string(*($1._val)); $$._type = 1;}
                        ;   



%%
/*==============================================================error handling===============================================================*/


void yyerror(const char *s) {
  extern int yylineno;
  extern int columnNo;
  cout<<"[-] ERROR : LINE "<<yylineno<<" COLUMN "<<columnNo<<" : "<<s<<"\n";
}
int get_last_var_pos(int scope) {
    int max_pos = -1;
    for (auto const& x : variables)
    {
        if(x.first.second == scope) {
            if(x.second.place > max_pos) {
                max_pos = x.second.place;        
            }
        }
    }
    return max_pos;
}

void add_var(string value,string name, int type, int scope) {
    struct varialbe_s tmp;
    if(variables.find(pair<string, int>(name,scope)) != variables.end()) {
        yyerror("Redeclaration of variable");
    }
    tmp.place = get_last_var_pos(scope) + 1;
    tmp.scope = scope;
    tmp.value = value;
    tmp.type = type;

    variables[pair<string,int>(name,scope)] = tmp;

}
int add_scope(int parent) {
    int max_scope = 0;
    for (auto const& x : scopes)
    {
        if(x.first > max_scope) {
            max_scope = x.first;
        }
    }
    scopes[max_scope+1] = parent;
    return max_scope+1;
}

string code_gen_init_func(int scope) {
    int var_num = get_last_var_pos(scope)+1;
    return string("\n\taddiu\t$sp,$sp,-")
                 + to_string(8+4*var_num) 
                 + string("\n\tsw\t$fp,") 
                 + to_string(8+4*var_num-4)
                 + string("($sp)")
                 + string("\n\tmove\t$fp,$sp");

}
string code_gen_end_func(int scope) {
    int var_num = get_last_var_pos(scope)+1;
    return string("\n\tmove\t$sp,$fp")
                 + string("\n\tlw\t$fp,")
                 + to_string(8+4*var_num-4) 
                 + string("($sp)") 
                 + string("\n\tmove\t$fp,$sp") 
                 + string("\n\taddiu\t$sp,$sp,") 
                 + to_string(8+4*var_num) 
                 + string("\n\tj\t$31") 
                 + string("\n\tnop");


}
/*==============================================================main function===============================================================*/

int main(int argc , char* argv[]) {
    FILE *fp;
    char filename[100];

    
    strcpy(filename,argv[1]);
    fp = fopen(filename, "r");
    yyin = fp;

    yyparse();
    

    fclose(fp);
}