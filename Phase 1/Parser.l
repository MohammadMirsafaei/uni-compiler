
%{
	#include <iostream>
    #include <string> 
    #include <cstring>
    using namespace std;

    int lineNO = 1;
    int columnNo=0;

    void count(void);
    FILE * outfp = fopen("./tokens.txt", "w");

    
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
INTEGER            (\+|-)*{DIGIT}+

%%

{KEYWORD}               {

    string s = string(yytext);

    if(s == "int") {
        count();
        
        fprintf(outfp, "TOKEN_INTTYPE\n");
    }
    else if(s == "char"){
        count();
        
        fprintf(outfp, "TOKEN_CHARTYPE\n");
    }
    else if(s == "if"){
        count();
        
        fprintf(outfp, "TOKEN_IF\n");
    }
    else if(s == "else"){
        count();
        
        fprintf(outfp, "TOKEN_ELSE\n");
    }
    else if(s == "elseif"){
        count();
        
        fprintf(outfp, "TOKEN_ELSEIF\n");
    }
    else if(s == "while"){
        count();
        
        fprintf(outfp, "TOKEN_WHILE\n");
    }
    else if(s == "continue"){
        count();
        
        fprintf(outfp, "TOKEN_CONTINU\n");
    }
    else if(s == "break"){
        count();
        
        fprintf(outfp, "TOKEN_BREAK\n");
    }
    else if(s == "for"){
        count();
        
        fprintf(outfp, "TOKEN_FOR\n");
    }
    else if(s == "return"){
        count();
        
        fprintf(outfp, "TOKEN_RETURN\n");
    }
    else if(s == "void"){
        count();
        
        fprintf(outfp, "TOKEN_VOID\n");
    }
    else if(s == "main"){
        count();
        
        fprintf(outfp, "TOKEN_MAIN\n");
    }
}

{IDENTIFIER}            {
    count();
    
    fprintf(outfp, "TOKEN_ID\n");
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
        
        fprintf(outfp, "TOKEN_INTCONST\n");
    }
    else{
        printf("\nERROR IN LINE %d COLUMN %d :  integer constant is out of range",yylineno,columnNo);
        return 1;
    }
}

{CHARACTER}             {  
    count();
    
    fprintf(outfp, "TOKEN_CHARCONST\n");
}

{ARITHMETIC}            {  
    count();
    string s = string(yytext);

    if(s == "+")
        fprintf(outfp, "TOKEN_PLUS\n");
    else if(s == "-")
        fprintf(outfp, "TOKEN_MINUS\n");
    else if(s == "*")
        fprintf(outfp, "TOKEN_MUL\n");
    else if(s == "/")
        fprintf(outfp, "TOKEN_DIV\n");
    else if(s == "^")
        fprintf(outfp, "TOKEN_POW\n");

}

{SIGNS}                 {
    string s = string(yytext);

    if(s == "<"){
        count();
        
        fprintf(outfp, "TOKEN_LS\n");}
    else if(s == "<="){
        count();
        
        fprintf(outfp, "TOKEN_LSEQ\n");}
    else if(s == "=="){
        count();
        
        fprintf(outfp, "TOKEN_EQ\n");}
    else if(s == "!="){
        count();
        
        fprintf(outfp, "TOKEN_NOTEQ\n");}
    else if(s == ">"){
        count();
        
        fprintf(outfp, "TOKEN_GR\n");}
    else if(s == ">="){
        count();
        
        fprintf(outfp, "TOKEN_GREQ\n");}
    else if(s == "|"){
        count();
        
        fprintf(outfp, "TOKEN_BITWISEOR\n");}
    else if(s == "&"){
        count();
        
        fprintf(outfp, "TOKEN_BITWISEAND\n");}
    
    else if(s == "||"){
        count();
        
        fprintf(outfp, "TOKEN_LOGICOR\n");}
    else if(s == "&&"){
        count();
        
        fprintf(outfp, "TOKEN_LOGICAND\n");}

    else if(s == "!"){
        count();
        
        fprintf(outfp, "TOKEN_LOGICNOT\n");}
    else if(s == "<"){
        count();
        
        fprintf(outfp, "TOKEN_LS\n");}
    else if(s == "="){
        count();
        
        fprintf(outfp, "TOKEN_ASSIGNOP\n");}
    else if(s == ")"){
        count();
        
        fprintf(outfp, "TOKEN_RIGHTPAREN\n");}
    else if(s == "("){
        count();
        
        fprintf(outfp, "TOKEN_LEFTPAREN\n");}
    else if(s == "]"){
        count();
        
        fprintf(outfp, "TOKEN_RB\n");}
    else if(s == "["){
        count();
        
        fprintf(outfp, "TOKEN_LB\n");}
    else if(s == "}"){
        count();
        
        fprintf(outfp, "TOKEN_RCB\n");}
    else if(s == "{"){
        count();
        
        fprintf(outfp, "TOKEN_LCB\n");}
    else if(s == "."){
        count();
        
        fprintf(outfp, "TOKEN_DOT\n");}
    else if(s == ","){
        count();
        
        fprintf(outfp, "TOKEN_COMMA\n");}
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


int main(int argc, char **argv) 
{
    FILE *fp;
    char filename[100];

    
    strcpy(filename,argv[1]);
    fp = fopen(filename, "r");
    yyin = fp;

    yylex();

    fclose(outfp);
    
}
