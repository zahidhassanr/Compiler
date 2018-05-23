%{
#define YYSTYPE symbolinfo*
#include<iostream>
#include<stdlib.h>
#include<string.h>
#include "Symboltable.h"
#include "y.tab.h"


using namespace std;

extern YYSTYPE yylval;

extern Symboltable *table;

extern ofstream logfile;
extern symbolinfo** array; 
extern symbolinfo** global_array; 
extern int mark;
extern int global_mark;
void yyerror(char *);
int flag=0;
int char_flag=0;
char ch;
int line_count=1;
int error=0;




%}



LETTER [a-zA-Z]
digit [0-9]
integer {digit}+
real ({digit}+[.]{digit}*)
exp ({integer}|{real})[eE]-?{integer}
ID [a-zA-Z_][a-zA-Z0-9_]*

NEWLINE \n
TAB \t
Backslash\
ALARM \a
CARRIAGERETURN \r
FORMFEED \f
BACKSPACE \b
VERTICALTAB \v
NULLCHAR \0


%x STRING
%x COMMENT

%x SINGLECOM
%x CHARACTER


%%



[+-]?{exp}  			|
[+-]?{real}			{
					symbolinfo *s=new symbolinfo(yytext,(char*) "CONS_FLOAT");
					s->floatvalue=atof(yytext);
					s->data_type="float";
					yylval=s;
					return CONST_FLOAT;
					

			}	

[+-]?{integer}	{
					symbolinfo *s=new symbolinfo(yytext,(char*) "CONS_INT");
					s->intvalue=atoi(yytext);
					s->data_type="int";
					yylval=s;
					return CONST_INT;

			}	


[+-]?{digit}+"."{digit}*[.]*{digit}*  {  
					error++;
					logfile<<"Too many decimal point error  at Line No; "<<line_count<<endl;
					
}



[+-]{digit}+[.](E[+-]?{digit}*[.]*{digit}*) 	{
					error++;
					logfile<<"Ill floating number error at Line NO: "<<line_count<<endl;
}



"/*"			{BEGIN COMMENT;

			}

<COMMENT>[^*\n]*	{/*any*/}

<COMMENT>"*"+[^*/\n]	{/*any*/}

<COMMENT>.		{}
<COMMENT>\n		{line_count++;}
<COMMENT><<EOF>>  {

                      error++;
		      logfile<<"Unfinished comment error at Line No: "<<line_count<<endl;
                      BEGIN INITIAL;
                        
                   } 
<COMMENT>"*"+"/"	{BEGIN INITIAL;}




"//"			{BEGIN SINGLECOM ;}

<SINGLECOM>"\\"		{flag=1;}

<SINGLECOM>.		{}
<SINGLECOM>\n		{
				if(flag==0){
					BEGIN INITIAL;
				}
				line_count++;
				flag=0;
			}	



"\'"        {
               BEGIN CHARACTER; 
            }

<CHARACTER><<EOF>> {
                         
                         error++;
			
                         BEGIN INITIAL;
                           
                   }


<CHARACTER>"\'" {   
                    
                    BEGIN INITIAL;
                    if(char_flag > 1){
                       
                       error++;
                    }                    
                    else if(char_flag == 1 && ch == '\\'){
                         
                         error++;
                    }
                    else if (char_flag == 0){
                       
                         error++;
                    }
                    else{
			symbolinfo *s=new symbolinfo(yytext,(char*) "CONST_CHAR");
			s->charvalue=ch;
			s->data_type="char";
			yylval=s;
			return CONST_CHAR;			
                     
                    }
                    char_flag = 0;
             }
<CHARACTER>.    {
                     char_flag += 1;
                     if(char_flag == 1){
                        ch = (char)yytext[0];  
                     }

               }



{NEWLINE} {line_count++; }






{TAB}  {}



{ALARM}	{}

{CARRIAGERETURN} {}

{FORMFEED}	{}

{BACKSPACE}	{}
{VERTICALTAB}	{}


{NULLCHAR}   {}


"if"	{return IF;}


		
"else"	{return ELSE;}



"for"  {return FOR;}

"do"  {return DO;}


"int"  {return INT;}


"float"  {return FLOAT;}


"void"  {return VOID;}



"switch"  {return SWITCH;}


"default"  {return DEFAULT;}


"while"  {return WHILE;}

"break"  {return BREAK;}


"char"  {return CHAR;}


"double"  {return DOUBLE;}



"return"  {return RETURN;}


"case"  {}


"continue"  {return CONTINUE;}







"+"		|

"-"		{
			symbolinfo *s= new symbolinfo(yytext, (char *)"ADDOP");
			yylval = (YYSTYPE)s;
			return ADDOP;
		}




"*"             |

"/"		|

"%"		{
			symbolinfo *s= new  symbolinfo(yytext, (char *)"MULOP");
			yylval = (YYSTYPE)s;
			return MULOP;

		}


"++" 		{return INCOP;}

"--" 		{return DECOP;}


"<" 		|

"<=" 		|

">" 		|

">=" 		|

"==" 		|

"!=" 		{
			symbolinfo *s= new  symbolinfo(yytext, (char *)"RELOP");
			yylval = (YYSTYPE)s;
			return RELOP;

		}


"=" 		{return ASSIGNOP;}

"&&" 		|

"||" 		{symbolinfo *s= new symbolinfo(yytext, (char *)"ADDOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;}



"(" 		{return LPAREN;}

")" 		{return RPAREN;}

"{"		{return LCURL;}

"}" 		{return RCURL;}


"["		{return LTHIRD;}

"]"		{return RTHIRD;}

","		{return COMMA;}

";"		{return SEMICOLON;}


"\""         {
              BEGIN STRING;
              
	     }
<STRING>"\\n"    {
                  
                  line_count++;
                   
                }
<STRING><<EOF>>   {
                    
                   error++;
		   logfile<<"Unfinished string error at Line No: "<<line_count<<endl;
                   BEGIN INITIAL;
                 
                   }

<STRING>"\""    {
                       
                    
                    BEGIN INITIAL;
               
                }

<STRING>"\\"    { } 

 
<STRING>.       { } 


{ID}                     { 
				symbolinfo* s=NULL;
				int i;
				for(i=0;i<mark;i++)
				{
					if(array[i]->symbol==yytext)
						s=array[i];
				}
				for(i=0;i<global_mark;i++)
				{
					if(global_array[i]->symbol==yytext)
						s=global_array[i];
				}

                                //symbolinfo *s= table->lookup_scope_id(yytext);
				if(s==NULL)
				{					
					s= new symbolinfo(yytext, (char *)"ID");
				}
				yylval = s;
							
				return ID;
                                                          
                         }




{exp}[a-zA-Z0-9_`~@#\$\\\\.|:]+ {error++;
				logfile<<"Ill floating number error at Line No: "<<line_count<<endl;
}

{integer}[a-zA-Z0-9_`~@#\$\\\\.|:]+ {error++;
				     logfile<<"Ill integer error at Line No: "<<line_count<<endl;
}

%%

int yywrap(void)
{
	
	return 1;
}






