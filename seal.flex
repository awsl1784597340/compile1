 /*
  *  The scanner definition for seal.
  */

 /*
  *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
  *  output, so headers and global definitions are placed here to be visible
  * to the code in the file.  Don't remove anything that was here initially
  */
%{

#include <seal-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdint.h>
#include <stdlib.h>

/* The compiler assumes these identifiers. */
#define yylval seal_yylval
#define yylex  seal_yylex

/* Max size of string constants */
#define MAX_STR_CONST 256
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the seal compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE seal_yylval;

/*
 *  Add Your own definitions here
 */


%}


%option noyywrap

 /*
  * Define names for regular expressions here.
  */

endline "\n"
notation ("/*")[^"*/"]*("*/")
var "var"
int "Int"
float "Float"
string "String"
bool "Bool"
void "Void"


IF             "if"           
ELSE           "else"         
WHILE          "while"        
FOR            "for"          
BREAK          "break"        
CONTINUE       "continue"     
FUNC           "func"         
RETURN         "return"       
empty          [" "\t\b\f]

CONST_BOOL     true|false
CONST_FLOAT    [-+]?[0-9]*\.[0-9]+
CONST_INT10    [-+]?[1-9][0-9]*|0
CONST_INT16    [-+]?0[xX][0-9a-fA-F]*

OBJECTIVE      [a-z][a-zA-Z0-9_]*

Doubleflag     "&&"|"\|\|"|"=="|"!="|">="|"<="
Singleflag     "\+"|"/"|"-"|"\*"|"="|"<"|"~"|","|";"|":"|"("|")"|"{"|"}"|"%"|">"|"&"|"!"|"\^"|"\|"

CONST_STRING1  "\`"
CONST_STRING2  "\""
CONST_STRING2  "\""("\\\""|[^"])"\""

%s BACKSLASH BADEOF

%%



{endline} {
  curr_lineno++;
}

{notation} {
  char *p=yytext;
  for(;p[0]!='\0';++p){
    if (p[0]=='\n')curr_lineno++;
  }
}

{int} {seal_yylval.symbol=idtable.add_string(yytext); return(TYPEID);}
{float} {seal_yylval.symbol=idtable.add_string(yytext); return(TYPEID);}
{string} {seal_yylval.symbol=idtable.add_string(yytext); return(TYPEID);}
{bool} {seal_yylval.symbol=idtable.add_string(yytext); return(TYPEID);}
{void} {seal_yylval.symbol=idtable.add_string(yytext); return(TYPEID);}

{var} {return(VAR);}

{IF} {return(IF);}            
{ELSE} {return(ELSE);}           
{WHILE}  {return(WHILE);} 
{FOR}    {return(FOR);}
{BREAK}  {return(BREAK);}
{CONTINUE} {return(CONTINUE);}
{FUNC}     {return(FUNC);}
{RETURN}   {return(RETURN);}

{CONST_BOOL} {
  if(strcmp("true",yytext)==0)
  {seal_yylval.boolean=true;}
  else {seal_yylval.boolean=false;}
  return(CONST_BOOL);
}

{CONST_FLOAT} {
  seal_yylval.symbol=floattable.add_string(yytext);
  return(CONST_FLOAT);
}
{CONST_INT10} {
  seal_yylval.symbol=inttable.add_string(yytext);
  return(CONST_INT);
}
{CONST_INT16} {
  int t;
  long long sum=0;
  int i;
  bool flag1;
  if (yytext[0]=='0') {i=2;flag1=false;}
  else {i = 3;flag1=true;}
  for(;yytext[i];i++){
    if(yytext[i]<='9'&&yytext[i]>='0')
    t=yytext[i]-'0';
    else if(yytext[i]<='Z'&&yytext[i]>='A')
    t=yytext[i]-'A'+10;
    else if(yytext[i]<='z'&&yytext[i]>='a')
    t=yytext[i]-'a'+10;
    sum=sum*16+t;
}
  if (yytext[0]=='-')sum=-sum;
  seal_yylval.symbol=inttable.add_int(sum);
  return(CONST_INT);
}


{Doubleflag} {
  char *a = new char[2];
  a[0]=yytext[0];
  a[1]=yytext[1];

  switch(a[0]){
    case '&':return(AND); break;
    case '|':return(OR);break;
    case '=':return(EQUAL);break;
    case '!':return(NE);break;
    case '>':return(GE);break;
    case '<':return(LE);break;

  }
}



{Singleflag} {return(yytext[0]);} 


{OBJECTIVE} {
  seal_yylval.symbol=idtable.add_string(yytext);
  return(OBJECTID);}

{CONST_STRING1} {
  char c;
  string_buf_ptr = string_buf;
  while((c=yyinput())!='`')
  {if(c=='\n')curr_lineno++;
  *string_buf_ptr++ = c;
  // if(c==EOF){
  //   BEGIN 0;
  //   strcpy(seal_yylval.error_msg, "EOF in string"); 
  //   return (ERROR);
  // }
  }
  *string_buf_ptr='\0';
  if (string_buf_ptr >= string_buf + MAX_STR_CONST) {
        strcpy(seal_yylval.error_msg, "TOO LONG");
        return (ERROR);
    }
  seal_yylval.symbol=stringtable.add_string(string_buf);
  return(CONST_STRING);
}



{CONST_STRING2} {
    char c;
  string_buf_ptr = string_buf;
  while((c=yyinput())!='\"')
  {if(c=='\\'){BEGIN BACKSLASH;continue;}
  *string_buf_ptr++ = c;
  }
  *string_buf_ptr='\0';
    if (string_buf_ptr >= string_buf + MAX_STR_CONST) {
        strcpy(seal_yylval.error_msg, "TOO LONG");
        return (ERROR);
    }
  seal_yylval.symbol=stringtable.add_string(string_buf);
  return(CONST_STRING);
}
<BACKSLASH>'\n' {
  curr_lineno++;
  *string_buf_ptr++ = '\n';
  BEGIN 0;
}
<BACKSLASH>'n' {
  *string_buf_ptr++ = '\\';
  *string_buf_ptr++ = 'n';
  BEGIN 0;
}
<BACKSLASH>'\\' {
  *string_buf_ptr++ = '\\';
  *string_buf_ptr++ = '\\';
  BEGIN 0;
}
<BACKSLASH>'0' {
  strcpy(yylval.error_msg,"String contains null character '\\0'");
  return(ERROR);
  BEGIN 0;
}
<BACKSLASH>'t' {
  *string_buf_ptr++ = '\\';
  *string_buf_ptr++ = '\t';
  BEGIN 0;
}







{empty} {}



.	{
	strcpy(seal_yylval.error_msg, yytext); 
	return (ERROR); 
}

%%
