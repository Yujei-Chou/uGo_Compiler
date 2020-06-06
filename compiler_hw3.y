/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    #include <string.h>
    // #define YYDEBUG 1
    // int yydebug = 1;

    FILE *fp;
    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;
    int scope_level = 0;
    int address = 0;
    char* element_type = "-";
    struct SymbolTable{
        int ScopeLev;
        int crntID;
	int Index[100];
	char* Name[100];
	char* Type[100];
	int Address[100];
	int Lineno[100];
	char* ElementType[100];
    }; 
    struct SymbolTable* ST[100];
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(char* type, char* name, int ScopeLevel);
    static void lookup_symbol(char* name, int ScopeLevel);
    static void insert_symbol_and_check_redeclared(char* type, char* name, int ScopeLevel);
    static void dump_symbol();
    static char* check_type(char* name, int ScopeLevel);
    static int check_IDENT_exist(char* LeftOp, char* RightOp);
    int HAS_ERROR = 0;
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token VAR TRUE FALSE
%token INT FLOAT BOOL STRING
%token ADD SUB MUL QUO REM INC DEC
%token GTR LSS GEQ LEQ EQL NEQ
%token ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token LAND LOR NOT
%token LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE QUOTA
%token SEMICOLON NEWLINE PRINT PRINTLN IF ELSE FOR

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <s_val> IDENT

/* Nonterminal with return, which need to sepcify type */
/* %type <type> Type TypeName ArrayType */

%type <i_val> INT
%type <f_val> FLOAT
%type <s_val> STRING
%type <s_val> BOOL
%type <s_val> TypeName ArrayType Type assign_op add_op mul_op cmp_op unary_op Land_op Lor_op Expression
%type <s_val> Literal UnaryExpr PrimaryExpr IndexExpr Operand ConversionExpr MulExpression AddExpression CmpExpression LandExpression LorExpression

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList
;

Type
    : TypeName{
	element_type = "-";
    }
    | ArrayType{
	$$ = "array";
	element_type = $1;
    }
;

TypeName
    : INT	{ $$ = "int32"; }
    | FLOAT	{ $$ = "float32"; }
    | STRING    { $$ = "string"; }
    | BOOL	{ $$ = "bool"; }
;

ArrayType
    : LBRACK Expression RBRACK Type	{ $$ = $4; }
;

StatementList
    : StatementList Statement
    | /*empty*/
;

Statement
    : DeclarationStmt NEWLINE
    | SimpleStmt NEWLINE
    | Block NEWLINE
    | IfStmt NEWLINE
    | ForStmt NEWLINE
    | PrintStmt NEWLINE
    | NEWLINE
;

Expression
    : LorExpression
;


MulExpression
    : UnaryExpr
    | MulExpression mul_op UnaryExpr{		
        char* LeftOp;
        char* RightOp;
        int flag;
        LeftOp = check_type($1,scope_level);
        RightOp = check_type($3,scope_level);
	flag = check_IDENT_exist(LeftOp, RightOp);
        if(flag == 1)
	{
		if(strcmp($2, "REM") == 0)
		{
			if(strcmp(LeftOp, "int32") != 0 || strcmp(RightOp, "int32") != 0)
			{
				if(strcmp(LeftOp, "int32") != 0)
				{
					printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno, $2, LeftOp);
				}
				else
				{
					printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno, $2, RightOp);
				}
			}
		}
		else
		{
        		if(strcmp(LeftOp, RightOp) != 0)
        		{
				printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $2, LeftOp, RightOp);
        		}
		}
	}
        printf("%s\n",$2);
    }
	
;

AddExpression
    : MulExpression
    | AddExpression add_op MulExpression{	
	char* LeftOp;
	char* RightOp;
	int flag;
	LeftOp = check_type($1,scope_level);
	RightOp = check_type($3,scope_level);
	flag = check_IDENT_exist(LeftOp, RightOp);
	if(flag == 1)
	{
		if(strcmp(LeftOp, RightOp) != 0)
		{
			printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $2, LeftOp, RightOp);
		}
	}
	fprintf(fp,"\t%c",LeftOp[0]);
	fprintf(fp,"%s\n",$2);
	/*
	if(strcmp(LeftOp,"int32") == 0)
	{
		fprintf(fp,"\ti%s\n",$2);
	}
	else if(strcmp(LeftOp,"float32") == 0)
	{
		fprintf(fp,"\tf%s\n",$2);
	}
	*/
        printf("%s\n",$2);

    }
;

CmpExpression
    : AddExpression
    | CmpExpression cmp_op AddExpression{
        char* LeftOp;
        char* RightOp;
        int flag;
        LeftOp = check_type($1,scope_level);
        RightOp = check_type($3,scope_level);
        flag = check_IDENT_exist(LeftOp, RightOp);
        if(flag == 1)
        {	
                if(strcmp(LeftOp, RightOp) != 0)
                {
                        printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $2, LeftOp, RightOp);
                }
        }
	$$ = "bool";
        printf("%s\n",$2);
    }
;

LandExpression
    : CmpExpression
    | LandExpression Land_op CmpExpression{
        char* LeftOp;
        char* RightOp;
	int flag;
        LeftOp = check_type($1,scope_level);
        RightOp = check_type($3,scope_level);
	flag = check_IDENT_exist(LeftOp, RightOp);
	if(flag == 1)
	{
        	if(strcmp(LeftOp, "bool") != 0 || strcmp(RightOp, "bool") != 0)
        	{
			if(strcmp(LeftOp, "bool") != 0)
			{
                		printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno, $2, LeftOp);
			}
			else
			{
				printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno, $2, RightOp);
			}
        	}
		else
		{
			$$ = "bool";
		}
	}
        printf("%s\n",$2);
    }
;

LorExpression
    : LandExpression
    | LorExpression Lor_op LandExpression{
        char* LeftOp;
        char* RightOp;
	int flag;
        LeftOp = check_type($1,scope_level);
        RightOp = check_type($3,scope_level);
	flag = check_IDENT_exist(LeftOp, RightOp);
	if(flag == 1)
	{
        	if(strcmp(LeftOp, "bool") != 0 || strcmp(RightOp, "bool") != 0)
        	{
                	if(strcmp(LeftOp, "bool") != 0)
                	{
                        	printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno, $2, LeftOp);
                	}
                	else
                	{
                        	printf("error:%d: invalid operation: (operator %s not defined on %s)\n",yylineno, $2, RightOp);
                	}
        	}
        	else
        	{
                	$$ = "bool";
        	}
	}
        printf("%s\n",$2);

    }
;


UnaryExpr
    : PrimaryExpr
    | unary_op UnaryExpr	{ printf("%s\n",$1); $$ = $2; }
;

PrimaryExpr
    : Operand
    | IndexExpr
    | ConversionExpr
;

Operand
    : Literal
    | IDENT{
	lookup_symbol($1, scope_level);
    }
    | LPAREN Expression RPAREN	{ $$ = $2; }
;



Literal
    : INT_LIT{
	printf("INT_LIT %d\n",$1);
	fprintf(fp,"\tldc %d\n",$1);
	$$ = "int32";
    }
    | FLOAT_LIT{
 	printf("FLOAT_LIT %f\n",$1);
	fprintf(fp,"\tldc %f\n",$1);
	$$ = "float32";
    }
    | BOOL_LIT{
	$$ = "bool";
    }
    | QUOTA STRING_LIT QUOTA{
	printf("STRING_LIT %s\n",$2);
	fprintf(fp,"\tldc \"%s\"\n",$2);
	$$ = "string";
    } 
;

BOOL_LIT
    : TRUE	{ printf("TRUE\n"); fprintf(fp,"\ticonst_1\n"); }
    | FALSE	{ printf("FALSE\n"); fprintf(fp, "\ticonst_0\n"); }
;

IndexExpr
    : PrimaryExpr LBRACK Expression RBRACK
;

ConversionExpr
    : Type LPAREN Expression RPAREN{
	if(strcmp(check_type($3,scope_level),"int32") == 0)
	{
		printf("I to ");
	}
	if(strcmp(check_type($3,scope_level),"float32") == 0)
	{
		printf("F to ");
	}
	if(strcmp($1,"int32") == 0)
	{
		printf("I\n");
	}
        if(strcmp($1,"float32") == 0)
        {
                printf("F\n");
        }

	
    }
;


DeclarationStmt
    : VAR IDENT Type{
	fprintf(fp,"\t%c",$3[0]);
	fprintf(fp,"store %d\n",address);
	insert_symbol_and_check_redeclared($3, $2, scope_level);
    }
    | VAR IDENT Type ASSIGN Expression{
        fprintf(fp,"\t%c",$3[0]);
        fprintf(fp,"store %d\n",address);
	insert_symbol_and_check_redeclared($3, $2, scope_level);
    }
;



SimpleStmt
    : AssignmentStmt
    | ExpressionStmt
    | IncDecStmt
;

AssignmentStmt
    : Expression assign_op Expression{
        char* LeftOp;
        char* RightOp;
	int flag;
        LeftOp = check_type($1,scope_level);
        RightOp = check_type($3,scope_level);
	flag = check_IDENT_exist(LeftOp, RightOp);
	if(flag == 1)
	{
		if(strcmp($1,"int32") == 0 || strcmp($1,"float32") == 0 || strcmp($1,"string") == 0 || strcmp($1,"bool") == 0)
		{
			printf("error:%d: cannot assign to %s\n",yylineno, $1);
		}
		else
		{
        		if(strcmp(LeftOp,RightOp) != 0)
        		{
                		printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $2, LeftOp, RightOp);
        		}
		}
	}
        printf("%s\n",$2);

    }
;

ExpressionStmt
    : Expression
;

IncDecStmt
    : Expression INC{
	printf("INC\n");
    }
    | Expression DEC{
	printf("DEC\n");
    }
;

Block
    : LBRACE{ create_symbol(); } StatementList RBRACE{ dump_symbol(); }
;


IfStmt
    : IF Condition Block
    | IF Condition Block ELSE IfStmt
    | IF Condition Block ELSE Block
;

Condition
    : Expression{
	if(strcmp($1,"bool") != 0)
	{
		printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1, check_type($1,scope_level));
	}
    }
;

ForStmt
    : FOR Condition Block
    | FOR ForClause Block
;

ForClause
    : InitStmt SEMICOLON  Condition SEMICOLON PostStmt
;

InitStmt
    : SimpleStmt
;

PostStmt
    : SimpleStmt
;

PrintStmt
    : PRINT LPAREN Expression RPAREN	{ printf("PRINT %s\n", check_type($3,scope_level)); }
    | PRINTLN LPAREN Expression RPAREN	{ printf("PRINTLN %s\n", check_type($3,scope_level)); }
;



assign_op
    : ASSIGN	{ $$ = "ASSIGN"; }
    | ADD_ASSIGN{ $$ = "ADD_ASSIGN"; }
    | SUB_ASSIGN{ $$ = "SUB_ASSIGN"; }
    | MUL_ASSIGN{ $$ = "MUL_ASSIGN"; }
    | QUO_ASSIGN{ $$ = "QUO_ASSIGN"; }
    | REM_ASSIGN{ $$ = "REM_ASSIGN"; }
;


Land_op
    : LAND      { $$ = "LAND"; }
;

Lor_op
    : LOR       { $$ = "LOR"; }
;

cmp_op
    : EQL	{ $$ = "EQL"; }
    | NEQ	{ $$ = "NEQ"; }
    | LSS	{ $$ = "LSS"; }
    | LEQ	{ $$ = "LEQ"; }
    | GTR	{ $$ = "GTR"; }
    | GEQ	{ $$ = "GEQ"; }
;


add_op
    : ADD	{ $$ = "add"; }
    | SUB	{ $$ = "sub"; }
;

mul_op
    : MUL	{ $$ = "mul"; }
    | QUO	{ $$ = "div"; }
    | REM	{ $$ = "rem"; }
;

unary_op
    : ADD	{ $$ = ""; }
    | SUB	{ $$ = "neg"; }
    | NOT	{ $$ = "NOT"; }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    
    fp=fopen("hw3.j","w");
    fprintf(fp, ".source hw3.j\n"
		".class public Main\n"
		".super java/lang/Object\n"
		".method public static main([Ljava/lang/String;)V\n"
		".limit stack 100\n"
		".limit locals 100\n");
    ST[scope_level] = (struct SymbolTable*)malloc(sizeof(struct SymbolTable));
    ST[scope_level]->crntID = 0;
    ST[scope_level]->ScopeLev = 0;
    yylineno = 0;
    yyparse();
    dump_symbol();
    printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    fprintf(fp, "\treturn\n"
		".end method\n");
    fclose(fp);
    
    if(HAS_ERROR == 1){
	remove("hw3.j");
    }
    
    return 0;
}

static void create_symbol() {
    scope_level++;
    ST[scope_level] = (struct SymbolTable*)malloc(sizeof(struct SymbolTable));
    ST[scope_level]->crntID = 0;
    ST[scope_level]->ScopeLev = scope_level;
}

static void insert_symbol(char* type ,char* name, int ScopeLevel) {
    printf("> Insert {%s} into symbol table (scope level: %d)\n",name ,ScopeLevel);
    int crntID = ST[ScopeLevel]->crntID;
    ST[ScopeLevel]->Index[crntID] = crntID;
    ST[ScopeLevel]->Name[crntID] = name;
    ST[ScopeLevel]->Type[crntID] = type;
    ST[ScopeLevel]->Address[crntID] = address;
    ST[ScopeLevel]->Lineno[crntID] = yylineno;
    ST[ScopeLevel]->ElementType[crntID] = element_type;
    ST[ScopeLevel]->crntID++;
    address++;
    
}

static void lookup_symbol(char* name, int ScopeLevel) {
   for(int j = ScopeLevel; j >= 0; j--)
   {
	int crntID = ST[j]->crntID;
   	for(int i = 0; i < crntID; i++)
   	{
		if(strcmp(ST[j]->Name[i],name) == 0)
		{
			printf("IDENT (name=%s, address=%d)\n",ST[j]->Name[i],ST[j]->Address[i]);
			fprintf(fp,"\t%c",ST[j]->Type[i][0]);
			fprintf(fp,"load %d\n",ST[j]->Address[i]);
			return;
		}
   	}
   }
   printf("error:%d: undefined: %s\n",yylineno+1, name);
}


static void dump_symbol() {
    printf("> Dump symbol table (scope level: %d)\n", scope_level);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
           "Index", "Name", "Type", "Address", "Lineno", "Element type");
    int crntID = ST[scope_level]->crntID;
    for(int i = 0; i < crntID; i++)
    { 
    	printf("%-10d%-10s%-10s%-10d%-10d%s\n",
		ST[scope_level]->Index[i], ST[scope_level]->Name[i], ST[scope_level]->Type[i], ST[scope_level]->Address[i], ST[scope_level]->Lineno[i], ST[scope_level]->ElementType[i]);
    }
    scope_level--;
}

static char* check_type(char* name, int ScopeLevel) {
   char* str;
   str = name;
   for(int j = ScopeLevel; j >= 0; j--)
   {
   	int crntID = ST[j]->crntID;
   	for(int i = 0; i < crntID; i++)
   	{
        	if(strcmp(ST[j]->Name[i],name) == 0)
        	{
                	str = ST[j]->Type[i];
                	if(strcmp(str,"array") == 0)
                	{
                        	str = ST[j]->ElementType[i];
                	}
                	return str;
        	}
   	}
   }
   return str;

}

static void insert_symbol_and_check_redeclared(char* type, char* name, int ScopeLevel){
   int crntID = ST[ScopeLevel]->crntID;
   for(int i = 0; i < crntID; i++)
   {
	if(strcmp(ST[ScopeLevel]->Name[i],name) == 0)
	{
		printf("error:%d: %s redeclared in this block. previous declaration at line %d\n",yylineno, name, ST[ScopeLevel]->Lineno[i]);
		return;
	}	
   }
   
   insert_symbol(type ,name, ScopeLevel);	
}

static int check_IDENT_exist(char* LeftOp, char* RightOp){
   int flag = 1;
   if(strcmp(LeftOp,"int32")!=0 && strcmp(LeftOp,"float32")!=0 && strcmp(LeftOp,"bool")!=0 && strcmp(LeftOp,"string")!=0)
   {
	flag = 0;
   }
   if(strcmp(RightOp,"int32")!=0 && strcmp(RightOp,"float32")!=0 && strcmp(RightOp,"bool")!=0 && strcmp(RightOp,"string")!=0)
   {
	flag = 0;
   }
   return flag;

}
