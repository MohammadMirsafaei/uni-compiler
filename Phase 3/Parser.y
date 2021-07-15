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

    map<int,int> regs;

    

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
    string code_gen_lw(string reg, int place);
    string code_gen_sw(string reg, int place);
    string code_gen_li(string reg, int num);
    string code_gen_addu(string reg1, string reg2, string reg_res);
    string code_gen_addiu(string reg1, int num, string reg_res);  
    string code_gen_mult(string reg1, string reg2, string reg_res);
    string code_gen_subu(string reg1, string reg2, string reg_res);


    string alloc_reg();
    void free_regs();
    void free_reg(string reg);
    void init_regs();

    int is_var_declared(string name, int scope);
    void type_check(int left, int right, int flag);
    struct varialbe_s get_var(string name, int scope);


    ofstream code_file("code.asm");

%}


%define parse.error verbose

%union {
     struct t {
          std::string *  _val;
          int _type; // 0:int 1:char 2:void
          int _scope;
          std::string * _asm;
          std::string * _reg;
          int _value;
          int _is_num;
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



%type <token> constants typeSpecifier  identifier    sub_decl elseif  conditionStmtElseIf 
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
                        |function {
                            $$._asm = new string(*$1._asm);
                        }
                        ;

function:               typeSpecifier   TOKEN_MAIN {func_type = current_dtype;is_declaration = 0;} TOKEN_LEFTPAREN {scopeNo = add_scope(0);}  TOKEN_RIGHTPAREN {is_declaration = 0;is_func = 1;}  compoundStmt {
                            is_func = 0;
                            
                            if ($1._type != 0 )
                                yyerror("main function must be of type INT");
                            
                            
                            $$._asm = new string(string("\nmain") + string(":") + code_gen_init_func($8._scope) + *($8._asm) + code_gen_end_func($8._scope));


                        }   
                        |typeSpecifier   identifier { 
                            func_type = current_dtype;
                            is_declaration = 0;
                            $2._type=$1._type;
                        }   TOKEN_LEFTPAREN {scopeNo = add_scope(0);is_func=1;}  argumentList   TOKEN_RIGHTPAREN   compoundStmt {is_func=0;}   function {
                            
                            
                            $$._asm = new string(string("\n") + string(*$2._val) + string(":") + code_gen_init_func($8._scope) + *($8._asm) + code_gen_end_func($8._scope));
                            
                            $$._asm = new string(string(*$$._asm) + string(*$10._asm));
                        }
                        ;

argumentList:           arguments 
                        | {}
                        ;

arguments:              arguments   TOKEN_COMMA   arg 
                        |arg
                        ;

arg:                    typeSpecifier   identifier       
                        ;


statements:             statements   stmt {
    if($$._asm == nullptr)
        $$._asm = new string("");
    $$._asm = new string( string(*$$._asm) + string(*$2._asm) );
}
                        | {}
                        ;

stmt:                   compoundStmt 
                        |singleStmt {$$._asm = new string(*$1._asm);}
                        ;

compoundStmt:           TOKEN_LS   statements   TOKEN_GR {
                            $$._scope = scopeNo;
                            // $$._asm = new string("\n\taaaa");
                            $$._asm = new string(*$2._asm);
                        } 
                        ;



singleStmt:             conditionStmt 
                        |loopStmt 
                        |declaration {$$._asm = new string(*$1._asm);}
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

declaration:            typeSpecifier  sub_decl  TOKEN_DOT {
                            is_declaration = 0;
                            
                            $$._asm = new string(*$2._asm);
                            
                        }
                        ;

sub_decl:               assignment_expr {
                            $$._asm = new string(*$1._asm);
                        }
                        |identifier {
                            add_var(string("0"),string(*$1._val), current_dtype, scopeNo);
                        }       
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

assgn :                 TOKEN_ASSIGNOP {rhs=1;}
                        ;

assignment_expr :       lhs assgn  arithmetic_expr  {
                            type_check($1._type,$3._type,1);
                            rhs=0;
                            add_var(string(*$3._val),string(*$1._val), current_dtype, scopeNo);

                            string tmp = "";
                            tmp += string(*$3._asm);
                            tmp += code_gen_sw("t0", get_var(string(*$1._val),scopeNo).place);
                            
                            $$._asm = new string(tmp);
                            free_regs();
                        }     
                        |lhs assgn  functionCall            
                        |lhs assgn array_init     
                        ;



lhs:                    identifier {
                            if(!is_declaration && !is_var_declared(string(*$1._val), scopeNo)) {
                                yyerror("Variable not declared, but is used in assigment");
                            }
                            $$._type = $1._type;
                        }          
                        |array_access              
                        ;

identifier:             TOKEN_ID {
                            $$._val = new string(*($1._val));
                            $$._type = current_dtype;
                        }                 
                        ;

arithmetic_expr:        arithmetic_expr   TOKEN_PLUS   arithmetic_expr {
                            type_check($1._type,$3._type,0);

                            if($1._is_num && $3._is_num) {
                                int val = $1._value + $3._value;
                                string tmp = code_gen_li("t0", val);
                                $$._asm = new string(tmp);
                                $$._is_num = 1;
                                $$._value = val;
                                free_reg(string(*$1._reg));
                                free_reg(string(*$3._reg));
                            } else if (!$1._is_num && !$3._is_num) {
                                string tmp = "";
                                tmp += string(*$1._asm);
                                tmp += string(*$3._asm);
                                tmp += code_gen_addu(string(*$1._reg), string(*$3._reg), "t0");
                                $$._asm = new string(tmp);
                                $$._is_num = 0;
                            } else if ($1._is_num) {
                                string tmp = "";
                                tmp += string(*$3._asm);
                                tmp += code_gen_addiu(string(*$3._reg), $1._value, "t0");
                                $$._asm = new string(tmp);
                                free_reg(string(*$1._reg));
                            } else {
                                string tmp = "";
                                tmp += string(*$1._asm);
                                tmp += code_gen_addiu(string(*$1._reg), $3._value, "t0");
                                $$._asm = new string(tmp);
                                free_reg(string(*$3._reg));
                            }
                            

                        }       
                        |arithmetic_expr   TOKEN_MINUS   arithmetic_expr {
                            type_check($1._type,$3._type,0);

                            if($1._is_num && $3._is_num) {
                                int val = $1._value - $3._value;
                                string tmp = code_gen_li("t0", val);
                                $$._asm = new string(tmp);
                                $$._is_num = 1;
                                $$._value = val;
                                free_reg(string(*$1._reg));
                                free_reg(string(*$3._reg));
                            } else if (!$1._is_num && !$3._is_num) {
                                string tmp = "";
                                tmp += string(*$1._asm);
                                tmp += string(*$3._asm);
                                tmp += code_gen_subu(string(*$1._reg), string(*$3._reg), "t0");
                                $$._asm = new string(tmp);
                                $$._is_num = 0;
                            } else if ($1._is_num) {
                                string tmp = "";
                                tmp += string(*$3._asm);
                                tmp += code_gen_addiu(string(*$3._reg), $1._value*-1, "t0");
                                $$._asm = new string(tmp);
                                free_reg(string(*$1._reg));
                            } else {
                                string tmp = "";
                                tmp += string(*$1._asm);
                                tmp += code_gen_addiu(string(*$1._reg), $3._value*-1, "t0");
                                $$._asm = new string(tmp);
                                free_reg(string(*$3._reg));
                            }
                        }      
                        |arithmetic_expr   TOKEN_MUL   arithmetic_expr {
                            type_check($1._type,$3._type,0);

                            if($1._is_num && $3._is_num) {
                                int val = $1._value * $3._value;
                                string tmp = code_gen_li("t0", val);
                                $$._asm = new string(tmp);
                                $$._is_num = 1;
                                $$._value = val;
                                free_reg(string(*$1._reg));
                                free_reg(string(*$3._reg));
                            } else {
                                string tmp = "";
                                tmp += string(*$1._asm);
                                tmp += string(*$3._asm);
                                tmp += code_gen_mult(string(*$1._reg), string(*$3._reg), "t0");
                                $$._asm = new string(tmp);
                                $$._is_num = 0;
                            } 
                            
                        }        
                        |arithmetic_expr   TOKEN_DIV   arithmetic_expr         
                        |arithmetic_expr   TOKEN_POW   arithmetic_expr         
                        |arithmetic_expr   TOKEN_BITWISEAND   arithmetic_expr         
                        |arithmetic_expr   TOKEN_BITWISEOR   arithmetic_expr         
                        |TOKEN_LEFTPAREN   arithmetic_expr   TOKEN_RIGHTPAREN   
                        |TOKEN_MINUS   arithmetic_expr   %prec UMINUS           
                        |identifier {
                            string reg = alloc_reg();
                            string tmp = code_gen_lw(reg, get_var(string(*$1._val),scopeNo).place);
                            $$._asm = new string(tmp);
                            $$._type = $1._type;
                            $$._is_num = 0;
                            $$._reg = new string(reg);
                        }                                        
                        |constants {
                            string reg = alloc_reg();
                            string tmp = code_gen_li(reg, $1._value);
                            $$._asm = new string(tmp);
                            $$._val = $1._val;
                            $$._type = $1._type;
                            $$._is_num = 1;
                            $$._reg = new string(reg);
                        }
                        |array_access 
                        ;

array_init_vars:        array_init_vars TOKEN_COMMA constants 
                        |constants
                        ;

array_init:             TOKEN_LS array_init_vars TOKEN_GR  
                        ;

array_access:           identifier TOKEN_LB constants TOKEN_RB                            
                        ;



typeSpecifier:          TOKEN_INTTYPE {$$._type = 0;is_declaration = 1;current_dtype=0;}
                        |TOKEN_CHARTYPE {$$._type = 1;is_declaration = 1;current_dtype=1;}
                        |TOKEN_VOIDTYPE {$$._type = 2;is_declaration = 1;current_dtype=2;}
                        ;

constants:              TOKEN_INTCONST {$$._val = new string(*($1._val)); $$._type = 0;$$._value=stoi(*$1._val);}
                        |TOKEN_CHARCONST {$$._val = new string(*($1._val)); $$._type = 1;$$._value=stoi(*$1._val);}
                        ;   



%%
/*==============================================================error handling===============================================================*/
void type_check(int left, int right, int flag)
{
	if(left != right)
	{
		switch(flag)
		{
			case 0: yyerror("Type mismatch in arithmetic expression"); exit(0); break;
			case 1: yyerror("Type mismatch in assignment expression"); exit(0); break;
			case 2: yyerror("Type mismatch in logical expression"); exit(0); break;
		}
	}
}

struct varialbe_s get_var(string name, int scope) {
    return variables[pair<string,int>(name,scope)];
}

string alloc_reg() {
    for(int i=0;i<8;i++) {
        if(regs[i] == 0) {
            regs[i] = 1;
            return string("t") + to_string(i);
        }
    }
    return string("t8");
}
void free_regs() {
    for(int i=0;i<8;i++) {
        regs[i] = 0;
    }
}

void free_reg(string reg) {
    int num;
    char c;
    sscanf(reg.c_str(), "%c%d", &c, &num);
    regs[num] = 0;
}
void init_regs() {
    for(int i=0;i<8;i++) {
        regs[i] = 0;
    }
}


void yyerror(const char *s) {
  extern int yylineno;
  extern int columnNo;
  cout<<"[-] ERROR : LINE "<<yylineno<<" COLUMN "<<columnNo<<" : "<<s<<"\n";
  exit(0);
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

int is_var_declared(string name, int scope) {
    if(variables.find(pair<string, int>(name,scope)) != variables.end()) {
        return 1;
    }
    return 0;
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
                 + to_string(8+4*(var_num+1)) 
                 + string("\n\tsw\t$fp,") 
                 + to_string(8+4*(var_num+1)-4)
                 + string("($sp)")
                 + string("\n\tmove\t$fp,$sp");

}
string code_gen_end_func(int scope) {
    int var_num = get_last_var_pos(scope)+1;
    return string("\n\tmove\t$sp,$fp")
                 + string("\n\tlw\t$fp,")
                 + to_string(8+4*(var_num+1)-4) 
                 + string("($sp)") 
                 + string("\n\tmove\t$fp,$sp") 
                 + string("\n\taddiu\t$sp,$sp,") 
                 + to_string(8+4*(var_num+1)) 
                 + string("\n\tj\t$31") 
                 + string("\n\tnop");


}

string code_gen_lw(string reg, int place) {
    return string("\n\tlw\t$") + reg + "," + to_string(8 + 4*place) + string("($fp)");
}

string code_gen_sw(string reg, int place) {
    return string("\n\tsw\t$") + reg + "," + to_string(8 + 4*place) + string("($fp)");
}

string code_gen_li(string reg, int num) {
    return string("\n\tli\t$") + reg + "," + to_string(num);
}

string code_gen_addu(string reg1, string reg2, string reg_res) {
    return string("\n\taddu\t$") + reg_res + string(",$") + reg1 + string(",$") + reg2;
}

string code_gen_addiu(string reg1, int num, string reg_res) {
    return string("\n\taddiu\t$") + reg_res + string(",$") + reg1 + string(",") + to_string(num);
}

string code_gen_mult(string reg1, string reg2, string reg_res) {
    return string("\n\tmult\t$") + reg1 + string(",$") + reg2
            + string("\n\tmflo\t$") + reg_res;
}

string code_gen_subu(string reg1, string reg2, string reg_res) {
    return string("\n\tsubu\t$") + reg_res + string(",$") + reg1 + string(",$") + reg2;
}
/*==============================================================main function===============================================================*/

int main(int argc , char* argv[]) {

    init_regs();

    FILE *fp;
    char filename[100];

    
    strcpy(filename,argv[1]);
    fp = fopen(filename, "r");
    yyin = fp;

    yyparse();
    

    fclose(fp);

    // for (auto const& x : variables)
    // {
    //     cout << "name:" << x.first.first 
    //         << ", scope:" << x.first.second
    //         << ", func:" << get_last_var_pos(x.first.second)
    //         << endl;
    // }

    // for (auto const& x : scopes)
    // {
    //     cout << "self:" << x.first 
    //         << ", parent:" << x.second
    //         << endl;
    // }
}