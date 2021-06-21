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



     using namespace std;

     extern int yylex();
     extern FILE* yyin;
     void yyerror(const char* s);
     int yyparse();

%}


%define parse.error verbose

%union {
     struct t {
          std::string *  _val;
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

program:                globalVars  
                        ;


globalVars:             typeSpecifier   identifier   TOKEN_ASSIGNOP   constants TOKEN_DOT   globalVars                                                                                             
                        |function 
                        ;

function:               typeSpecifier   TOKEN_MAIN TOKEN_LEFTPAREN   TOKEN_RIGHTPAREN   compoundStmt    
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

compoundStmt:           TOKEN_LS   statements   TOKEN_GR 
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

identifier:             TOKEN_ID                  
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



typeSpecifier:          TOKEN_INTTYPE 
                        |TOKEN_CHARTYPE 
                        |TOKEN_VOIDTYPE 
                        ;

constants:              TOKEN_INTCONST 
                        |TOKEN_CHARCONST 
                        ;   



%%
/*==============================================================error handling===============================================================*/


void yyerror(const char *s) {
  extern int yylineno;
  extern int columnNo;
  cout<<"[-] ERROR : LINE "<<yylineno<<" COLUMN "<<columnNo<<" : "<<s<<"\n";
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