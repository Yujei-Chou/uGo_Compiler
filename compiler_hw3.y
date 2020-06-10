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
    struct ScanSymDetail{
	char* ScanType;
	int ScanPos;
	char* ScanElementType;
    };
    typedef struct ScanSymDetail Struct;
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(char* type, char* name, int ScopeLevel);
    static Struct lookup_symbol(char* name, int ScopeLevel);
    static void insert_symbol_and_check_redeclared(char* type, char* name, int ScopeLevel);
    static void dump_symbol();
    static char* check_type(char* name, int ScopeLevel);
    static int check_IDENT_exist(char* LeftOp, char* RightOp);
    static void load(int LoadPos,char* LoadType, char* LoadElementType);
    static void store(int StorePos,char* StoreType, char* StoreElementType);	
    int HAS_ERROR = 0;
    int LoadPos = 0;
    char *LoadType;
    int LabelNo = 0;
    int PrintNum = 1;
    char* LHS="";
    int IfAssign = 0;
    int ConvertType=0;
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
%type <s_val> Literal UnaryExpr PrimaryExpr IndexExpr Operand ConversionExpr MulExpression AddExpression CmpExpression LandExpression LorExpression Expression_test

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
	flag = check_IDENT_exist($1, $3);
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

        fprintf(fp,"\t%c",LeftOp[0]);
        fprintf(fp,"%s\n",$2);
        printf("%s\n",$2);
	PrintNum=2;
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
	flag = check_IDENT_exist($1, $3);
	if(flag == 1)
	{
		if(strcmp(LeftOp, RightOp) != 0)
		{
			printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $2, LeftOp, RightOp);
		}
	}

	fprintf(fp,"\t%c",LeftOp[0]);
	fprintf(fp,"%s\n",$2);
        printf("%s\n",$2);
	PrintNum=2;
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
        flag = check_IDENT_exist($1, $3);
        if(flag == 1)
        {	
                if(strcmp(LeftOp, RightOp) != 0)
                {
                        printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $2, LeftOp, RightOp);
                }
        }
	$$ = "bool";

	int i = LabelNo;
	int j = LabelNo+1;
	if(strcmp(LeftOp,"int32") == 0)
	{
		fprintf(fp,"\tisub\n");
	}
	else if(strcmp(LeftOp,"float32") == 0)
	{
		fprintf(fp,"\tfcmpl\n");
	}
	fprintf(fp,"\t%s Label_%d\n",$2,i);
	fprintf(fp,"\ticonst_0\n"
		   "\tgoto Label_%d\n"
		   "Label_%d:\n"
		   "\ticonst_1\n"
		   "Label_%d:\n",j,i,j);
	LabelNo+=2;
        printf("%s\n",$2);
	PrintNum=2;
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
	flag = check_IDENT_exist($1, $3);
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

	fprintf(fp,"\t%s\n",$2);
        printf("%s\n",$2);
	PrintNum=2;
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
	flag = check_IDENT_exist($1, $3);
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

        fprintf(fp,"\t%s\n",$2);
        printf("%s\n",$2);
	PrintNum=2;

    }
;


UnaryExpr
    : PrimaryExpr
    | unary_op UnaryExpr{ 
	printf("%s\n",$1); 
	$$ = $2;
	if(strcmp($1,"neg") == 0)
	{
		fprintf(fp,"\t%c%s\n",$2[0],$1);
	}
	if(strcmp($1,"ixor") == 0)
	{
		fprintf(fp,"\t%s\n",$1);	
	}
    }
;

PrimaryExpr
    : Operand
    | IndexExpr
    | ConversionExpr
;

Operand
    : Literal
    | IDENT{
	Struct IDENT_Detail = lookup_symbol($1,scope_level);
	load(IDENT_Detail.ScanPos,IDENT_Detail.ScanType,IDENT_Detail.ScanElementType);
	if(strcmp(IDENT_Detail.ScanType,"array") == 0)
	{
		fprintf(fp,"\taload %d\n",IDENT_Detail.ScanPos);
	}
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
    : PrimaryExpr LBRACK Expression RBRACK{
	printf("IfAssign:*%d********\n",IfAssign);
	if(IfAssign == 1)
	{
		Struct IndexExpr_Detail = lookup_symbol($1,scope_level);
		fprintf(fp,"\t%caload\n",IndexExpr_Detail.ScanElementType[0]);
		IfAssign = 0;
	}	
    }
;

ConversionExpr
    : Type LPAREN Expression RPAREN{
	if(strcmp(check_type($3,scope_level),"int32") == 0)
	{
		fprintf(fp,"\ti2");
	}
	if(strcmp(check_type($3,scope_level),"float32") == 0)
	{
		fprintf(fp,"\tf2");
	}
	if(strcmp($1,"int32") == 0)
	{
		fprintf(fp,"i\n");
	}
        if(strcmp($1,"float32") == 0)
        {
                fprintf(fp,"f\n");
        }
	
    }
;


DeclarationStmt
    : VAR IDENT Type{
	if(strcmp($3,"string") == 0)
	{
		fprintf(fp,"\tldc \"\"\n");
		fprintf(fp,"\t%c",'a');
	}
	else if(strcmp($3,"bool") == 0)
	{
		fprintf(fp,"\t%c",'i');
	}
	else if(strcmp($3,"array") == 0)
	{
		fprintf(fp,"\tnewarray");
		if(strcmp(element_type,"int32") == 0)
		{
			fprintf(fp," int\n");
		}
		else
		{
			fprintf(fp," float\n");
		}
		fprintf(fp,"\t%c",'a');
	}
        else
        {
		if(strcmp($3,"int32") == 0)
		{
			fprintf(fp,"\tldc 0\n");
		}
		else
		{
                        fprintf(fp,"\tldc 0.0\n");
		}
                fprintf(fp,"\t%c",$3[0]);
        }
	fprintf(fp,"store %d\n",address);
	insert_symbol_and_check_redeclared($3, $2, scope_level);
    }
    | VAR IDENT Type ASSIGN Expression{
        if(strcmp($3,"string") == 0)
        {
                fprintf(fp,"\t%c",'a');
        }
        else if(strcmp($3,"bool") == 0)
	{
        	fprintf(fp,"\t%c",'i');
	}
	else if(strcmp($3,"array") == 0)
	{
                fprintf(fp,"\tnewarray\n");
                fprintf(fp,"\t%c",'a');
	}
	else
	{
                fprintf(fp,"\t%c",$3[0]);
	}
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
    : Expression_test assign_op Expression{
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
	Struct IDENT_Detail = lookup_symbol($1,scope_level);
	if(strcmp($2,"ASSIGN") != 0)
	{
		load(IDENT_Detail.ScanPos,IDENT_Detail.ScanType,IDENT_Detail.ScanElementType);
		fprintf(fp,"\tswap\n");
		fprintf(fp,"\t%c%s\n",IDENT_Detail.ScanType[0],$2);
	}	
	store(IDENT_Detail.ScanPos,IDENT_Detail.ScanType,IDENT_Detail.ScanElementType);

        printf("%s\n",$2);
	PrintNum=1;

    }
;

Expression_test
    : IDENT{
	LHS = $1;
        $$ = $1;
	printf("IDENT:%s\n",$1);
    }
    | IndexExpr{
	LHS = $1;
	$$ = $1;
	IfAssign = 1;
	printf("Index Expr:%s\n",$1);
    }
;



ExpressionStmt
    : Expression
;

IncDecStmt
    : Expression INC{
	printf("INC\n");
	Struct RHS_Detail = lookup_symbol($1,scope_level);
        if(RHS_Detail.ScanType[0] == 'i')
        {
                fprintf(fp,"\tldc 1\n");
        }
        else
        {
                fprintf(fp,"\tldc 1.0\n");
        }
	fprintf(fp,"\t%cadd\n",RHS_Detail.ScanType[0]);
	store(RHS_Detail.ScanPos,RHS_Detail.ScanType,RHS_Detail.ScanElementType);

    }
    | Expression DEC{
	printf("DEC\n");
	Struct RHS_Detail = lookup_symbol($1,scope_level);
	if(RHS_Detail.ScanType[0] == 'i')
        {
		fprintf(fp,"\tldc 1\n");
	}
	else
	{
		fprintf(fp,"\tldc 1.0\n");
	}
        fprintf(fp,"\t%csub\n",RHS_Detail.ScanType[0]);
	store(RHS_Detail.ScanPos,RHS_Detail.ScanType,RHS_Detail.ScanElementType);
    }
;

Block
    : LBRACE{ create_symbol(); } StatementList RBRACE{ dump_symbol(); }
;


IfStmt
    : IF Condition Block
    | IF Condition Block ELSE IfStmt
    | IF Condition Block ELSE{ fprintf(fp,"\tgoto L_if_exit\n"); fprintf(fp,"L_if_false:\n"); } Block{
	fprintf(fp,"L_if_exit:\n");	
    }
;


Condition
    : Expression{
	if(strcmp($1,"bool") != 0)
	{
		printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1, check_type($1,scope_level));
	}
	//fprintf(fp,"\tifeq L_for_exit\n");
    }
;

ForStmt
    : FOR{ fprintf(fp,"L_for_begin :\n"); } For_test
;

For_test
    : Condition{ fprintf(fp,"\tifeq L_for_exit\n"); } Block{ fprintf(fp,"\tgoto L_for_begin\n"); fprintf(fp,"L_for_exit:\n"); }
    | ForClause Block
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
    : PRINT LPAREN Expression RPAREN{
	char *type_printed;
	type_printed = check_type($3,scope_level);
	printf("PRINT %s\n", type_printed);
        if(strcmp(type_printed,"bool") == 0)
        {
		int i = LabelNo;
		int j = LabelNo+1;
                fprintf(fp,"\tifne Label_%d\n"
                           "\tldc \"false\"\n"
                           "\tgoto Label_%d\n"
                           "Label_%d:\n",i,j,i);

                fprintf(fp,"\tldc \"true\"\n"
                           "Label_%d:\n",j);
		LabelNo+=2;
        }

	fprintf(fp,"\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n"
		   "\tswap\n");
	if(strcmp(type_printed,"int32") == 0)
	{
		fprintf(fp,"\tinvokevirtual java/io/PrintStream/print(I)V\n");
	}
	else if(strcmp(type_printed,"float32") == 0)
	{
		fprintf(fp,"\tinvokevirtual java/io/PrintStream/print(F)V\n");
	}
	else if(strcmp(type_printed,"string") == 0)
	{
		fprintf(fp,"\tinvokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
	}
        else if(strcmp(type_printed,"bool") == 0)
        {
                fprintf(fp,"\tinvokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }

    }
    | PRINTLN LPAREN Expression RPAREN{
        char *type_printed;
        type_printed = check_type($3,scope_level);
        printf("PRINT %s\n", type_printed);
        if(strcmp(type_printed,"bool") == 0)
        {
		int i = LabelNo;
		int j = LabelNo+1;
                fprintf(fp,"\tifne Label_%d\n"
                           "\tldc \"false\"\n"
                           "\tgoto Label_%d\n"
                           "Label_%d:\n",i,j,i);

                fprintf(fp,"\tldc \"true\"\n"
                           "Label_%d:\n",j);
		LabelNo+=2;
        }

        fprintf(fp,"\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n"
                   "\tswap\n");
        if(strcmp(type_printed,"int32") == 0)
        {
                fprintf(fp,"\tinvokevirtual java/io/PrintStream/println(I)V\n");
        }
        else if(strcmp(type_printed,"float32") == 0)
        {
                fprintf(fp,"\tinvokevirtual java/io/PrintStream/println(F)V\n");
        }
        else if(strcmp(type_printed,"string") == 0)
        {
                fprintf(fp,"\tinvokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }
	else if(strcmp(type_printed,"bool") == 0)
	{
                fprintf(fp,"\tinvokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
	}
    }
;



assign_op
    : ASSIGN	{ $$ = "ASSIGN"; }
    | ADD_ASSIGN{ $$ = "add"; }
    | SUB_ASSIGN{ $$ = "sub"; }
    | MUL_ASSIGN{ $$ = "mul"; }
    | QUO_ASSIGN{ $$ = "div"; }
    | REM_ASSIGN{ $$ = "rem"; }
;


Land_op
    : LAND      { $$ = "iand"; }
;

Lor_op
    : LOR       { $$ = "ior"; }
;

cmp_op
    : EQL	{ $$ = "ifeq"; }
    | NEQ	{ $$ = "ifne"; }
    | LSS	{ $$ = "iflt"; }
    | LEQ	{ $$ = "ifle"; }
    | GTR	{ $$ = "ifgt"; }
    | GEQ	{ $$ = "ifge"; }
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
    : ADD	{ $$ = "pos"; }
    | SUB	{ $$ = "neg"; }
    | NOT	{ $$ = "ixor"; fprintf(fp,"\ticonst_1\n"); }
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

static Struct lookup_symbol(char* name, int ScopeLevel) {
   Struct s;
   for(int j = ScopeLevel; j >= 0; j--)
   {
	int crntID = ST[j]->crntID;
   	for(int i = 0; i < crntID; i++)
   	{
		if(strcmp(ST[j]->Name[i],name) == 0)
		{
			//printf("IDENT (name=%s, address=%d)\n",ST[j]->Name[i],ST[j]->Address[i]);

			s.ScanPos = ST[j]->Address[i];
			s.ScanType = ST[j]->Type[i];
			s.ScanElementType = ST[j]->ElementType[i];
			return s;
		}
   	}
   }
   //printf("error:%d: undefined: %s\n",yylineno+1, name);
}


static void load(int LoadPos,char* LoadType, char* LoadElementType)
{

        if(strcmp(LoadType,"array") == 0)
        {
/*
                if(strcmp(LoadElementType,"int32") == 0 || strcmp(LoadElementType,"float32") == 0)
                {
                        fprintf(fp,"\t%c",LoadElementType[0]);
                }
                fprintf(fp,"aload\n");
*/
        }
	else if(strcmp(LoadType,"string") == 0)
	{
		fprintf(fp,"\taload %d\n",LoadPos);
	}
        else if(strcmp(LoadType,"bool") == 0)
        {
                fprintf(fp,"\tiload %d\n",LoadPos);
        }
        else
        {
                fprintf(fp,"\t%cload %d\n",LoadType[0],LoadPos);
        }

}

static void store(int StorePos,char* StoreType,char* StoreElementType)
{

	if(strcmp(StoreType,"array") == 0)
	{
		if(strcmp(StoreElementType,"int32") == 0 || strcmp(StoreElementType,"float32") == 0)
		{
			fprintf(fp,"\t%c",StoreElementType[0]);
		}
		fprintf(fp,"astore\n");
		
	}
	else if(strcmp(StoreType,"string") == 0)
	{
		fprintf(fp,"\tastore %d\n",StorePos);
	}
        else if(strcmp(StoreType,"bool") == 0)
        {
                fprintf(fp,"\t%cstore %d\n",'i',StorePos);
        }				
	else
	{
		fprintf(fp,"\t%cstore %d\n",StoreType[0],StorePos);
	}
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
