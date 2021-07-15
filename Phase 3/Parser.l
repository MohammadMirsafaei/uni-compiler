
%{
	#include <iostream>
    #include <string> 
    #include <cstring>
    #include "Parser.h"
    using namespace std;

    int lineNO = 1;
    int columnNo=0;

    void count(void);
    
%}
%option yylineno
%option noyywrap

DIGIT              [0-9]
SLETTER            [a-z]
CLETTER            [A-Z]
IDENTIFIER         ({CLETTER}|{SLETTER}|_)({CLETTER}|{SLETTER}|{DIGIT}|_)*
KEYWORD            "int"|"char"|"if"|"else"|"elseif"|"while"|"continue"|"break"|"for"|"return"|"void"|"main"             
SINGLELINE         (\$\$.*) 
MULTILINE          (\$\*([^*]|[\r\n]|(\*+([^*\$]|[\r\n])))*\*+\$)
UNCLOSED           (\$\*([^*]|[\r\n]|(\*+([^*\$]|[\r\n])))*[^\*][^\$])
UNOPENED           "*\$"
WHITESPACE         [ \n\t]
CHARACTER          ((\')({DIGIT}|{SLETTER}|{CLETTER})(\'))|(\'(\\.|[^'\\])\')       
ARITHMETIC         "+"|"-"|"*"|"/"|"^"
SIGNS              "<"|"<="|"=="|"!="|">"|">="|"|"|"&"|"||"|"&&"|"="|")"|"("|"]"|"["|"}"|"{"|","|"."            
INTEGER            (-)*{DIGIT}+

%%

{KEYWORD}               {

    string s = string(yytext);

    if(s == "int") {
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_INTTYPE;
    }
    else if(s == "char"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_CHARTYPE;
    }
    else if(s == "if"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_IF;
    }
    else if(s == "else"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_ELSE;
    }
    else if(s == "elseif"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_ELSEIF;
    }
    else if(s == "while"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_WHILE;
    }
    else if(s == "continue"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_CONTINUE;
    }
    else if(s == "break"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_BREAK;
    }
    else if(s == "for"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_FOR;
    }
    else if(s == "return"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_RETURN;
    }
    else if(s == "void"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_VOIDTYPE;
    }
    else if(s == "main"){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_MAIN;
    }
}

{IDENTIFIER}            {
    count();
    yylval.token._val= new string(yytext);
    return TOKEN_ID;
}



{WHITESPACE}            {

    string s = string(yytext);

    if(s == " ") {
        count();
    }
    else if(s == "\t") {
        count();
    }
    else if(s == "\n") {
        columnNo=0;
        lineNO++;
    }

}

{SINGLELINE}            { 
    count();            
}

{MULTILINE}             {  
    count();  
}

{UNCLOSED}              {  
    printf("\nERROR IN LINE %d COLUMN %d :  unclosed comment section",lineNO,columnNo);
    return 1;
}   

{UNOPENED}              {
    printf("\nERROR IN LINE %d COLUMN %d :  unopened comment section",lineNO,columnNo);
    return 1;
}

{INTEGER}               {
    int upper_bound = 2147483647;
    int lower_bound = -2147483648;
    long long int x = atoll(yytext);
    if(x < upper_bound && x > lower_bound){
        count();
        yylval.token._val= new string(yytext);
        return TOKEN_INTCONST;
    }
    else{
        printf("\nERROR IN LINE %d COLUMN %d :  integer constant is out of range",yylineno,columnNo);
        return 1;
    }
}

{CHARACTER}             {  
    count();
    yylval.token._val= new string(to_string(int(yytext[1])));
    return TOKEN_CHARCONST;
}

{ARITHMETIC}            {  
    count();
    yylval.token._val = new string(yytext);
    string s = string(yytext);
    if(s == "+")
        return TOKEN_PLUS;
    else if(s == "-")
        return TOKEN_MINUS;
    else if(s == "*")
        return TOKEN_MUL;
    else if(s == "/")
        return TOKEN_DIV;
    else if(s == "^")
        return TOKEN_POW;

}

{SIGNS}                 {

    string s = string(yytext);

    if(s == "<"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LS;}
    else if(s == "<="){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LSEQ;}
    else if(s == "=="){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_EQ;}
    else if(s == "!="){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_NOTEQ;}
    else if(s == ">"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_GR;}
    else if(s == ">="){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_GREQ;}
    else if(s == "|"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_BITWISEOR;}
    else if(s == "&"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_BITWISEAND;}
    
    else if(s == "||"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LOGICOR;}
    else if(s == "&&"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LOGICAND;}

    else if(s == "!"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LOGICNOT;}
    else if(s == "<"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LS;}
    else if(s == "="){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_ASSIGNOP;}
    else if(s == ")"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_RIGHTPAREN;}
    else if(s == "("){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LEFTPAREN;}
    else if(s == "]"){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_RB;}
    else if(s == "["){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_LB;}
    else if(s == "."){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_DOT;}
    else if(s == ","){
        count();
        yylval.token._val = new string(yytext);
        return TOKEN_COMMA;}
}
%%


void count(void)
{
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n')
			columnNo = 0;
		else if (yytext[i] == '\t')
			columnNo += 8 - (columnNo % 8);
		else
			columnNo++;

}

