.source hw3.j
.class public Main
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
.limit stack 100
.limit locals 100
	ldc 0
	istore 0
	ldc 999
	istore 1
L_for_begin_0:
	ldc 1
	istore 1
L_for_condition_0:
	iload 1
	ldc 9
	isub
	ifle Label_0
	iconst_0
	goto Label_1
Label_0:
	iconst_1
Label_1:
	ifeq L_for_exit_0
	goto for_Stmt_0
for_Post_Stmt_0:
	iload 1
	ldc 1
	iadd
	istore 1
	goto L_for_condition_0
for_Stmt_0:
L_for_begin_1:
	ldc 1
	istore 0
L_for_condition_1:
	iload 0
	ldc 9
	isub
	ifle Label_2
	iconst_0
	goto Label_3
Label_2:
	iconst_1
Label_3:
	ifeq L_for_exit_1
	goto for_Stmt_1
for_Post_Stmt_1:
	iload 0
	ldc 1
	iadd
	istore 0
	goto L_for_condition_1
for_Stmt_1:
	iload 1
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(I)V
	ldc "*"
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
	iload 0
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(I)V
	ldc "="
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
	iload 1
	iload 0
	imul
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(I)V
	ldc "\t"
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
	goto for_Post_Stmt_1
L_for_exit_1:
	ldc "\n"
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V
	goto for_Post_Stmt_0
L_for_exit_0:
	return
.end method
