%{
#define YYSTYPE symbolinfo*
#include<bits/stdc++.h>
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "Symboltable.h"
#include<string>
#include<stdio.h>
#include<stdlib.h>

using namespace std;



int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int line_count;
extern int error;
int global_mark=0;
symbolinfo** global_array;  
int mark=0;
int bang=0;
string datatype;

int label_num=1;
int temp_num=1;



symbolinfo** array;                

Symboltable *table;

ofstream logfile;
ofstream code;

string dec_code=".MODEL SMALL\n.STACK 100H\n.DATA\n";
string func_code=""; 
string main_code="MAIN PROC\n";



void yyerror(char *s){}


bool lookup_scope(string symbol)
{
	int i;
	for(i=0;i<mark;i++)
	{
		if(array[i]->symbol==symbol)
			return true;
	
	}

	for(i=0;i<global_mark;i++)
	{
		if(global_array[i]->symbol==symbol)
			return true;
	
	}
	return false;
}

void processID(string datatype, symbolinfo* s1){
	symbolinfo* s=new symbolinfo();
	s=s1;
    
	if(lookup_scope(s->symbol)){
		logfile<<"Multiple Declaration of "<<s->symbol<<endl;error++;	
		return;	
	}
	s->data_type=datatype;
	s->lex_type="ID";
	dec_code +=s->symbol+"  DW"+"  ?\n";
	if(bang==0) {global_array[global_mark++]=s;}
	else array[mark++]=s;
}
 


void processfunc(string datatype, symbolinfo* s1,symbolinfo* s2){
	symbolinfo* s=new symbolinfo();
	s=s1;
	s->data_type=datatype;
	s->lex_type="ID";
	s->isFunction=true;
	
	table->Enter_scope(s1->symbol);
	int i;
	for(i=0;i<mark;i++)
	  {
		table->insert(array[i]);
	  }
	for(i=0;i<global_mark;i++)
	  {
		table->insert(global_array[i]);
	  }
	
	
	table->insert(s,table->head);
	mark=0;
	
	func_code +=s1->symbol+" Proc\n";
	func_code +=s2->code+s1->symbol+" Endp\n\n";
	
}





void processArray(string datatype, symbolinfo* s1, int size){
	symbolinfo* s=new symbolinfo();
	s=s1;
	if(lookup_scope(s->symbol)){
		logfile<<"Multiple Declaration of "<<s->symbol<<endl;error++;
		return;
	}
	s->data_type=datatype;
	s->lex_type="ID";
	s->createArray(s,size);
	s->isArray=true;
	int i;
	dec_code +=s->symbol+"  DW"+"  ";
	for(i=0;i<size-1;i++)
	{
		dec_code+="?,";
	}
	dec_code +="?\n";
	if(bang==0) {global_array[global_mark++]=s;}
	else array[mark++]=s;
}


string label()
{
	ostringstream convert;
	string label;
	convert<<label_num;
	label="L"+ convert.str(); 
	label_num++;
	return label;
}

string temp_str()
{
	ostringstream convert;
	string temp;
	convert<<temp_num;
	temp="t"+convert.str();
	temp_num++;
	return temp;
}

symbolinfo* processIDAccess(symbolinfo* s){
	if(!lookup_scope(s->symbol)){
		logfile<<"Undeclared varialable  "<<s->symbol<<"error"<<endl;error++;
		
	}
	return s;
}



symbolinfo* processArrayAccess(symbolinfo* d1, symbolinfo* d3){
	
	
	int index;
	if(!(lookup_scope(d1->symbol)) || d1->arraylength==-1){
		logfile<<"Undeclared varialable of "<<d1->symbol;error++;
		return d1;	
	}

	if(d1->arraylength>0){
		index = d3->intvalue;
		if(d3->data_type !="float" && index>=0 && index < d1->arraylength){
			symbolinfo* s=new symbolinfo();
			s=d1->array[index];
			s->array_index=index;
			ostringstream convert;
			convert<<index;
			s->code="LEA DI,"+s->symbol+"\n"+"ADD DI,"+convert.str()+"\n";
			return s;
		}
		logfile<<"Array Index out of bound"<<endl;error++;	
	}
	else {
		logfile<<d1->symbol<<" is not an array"<<endl;	error++;
	}	
		
	symbolinfo* dd = new symbolinfo();
	dd->data_type=d1->data_type;
	
	return dd;
}

symbolinfo* processAssign(symbolinfo* d1,symbolinfo* d2)
{
	symbolinfo* s=new symbolinfo();

	if(d1->data_type=="float" && d2->data_type=="int")
	{
		s->floatvalue=d2->intvalue;
		if(d2->lex_type=="CONS_INT" && d1->arraylength==-1)
		{
			ostringstream convert;
			convert<<d2->intvalue;
			s->code ="MOV AX,"+convert.str()+"\n"+"MOV "+d1->symbol+","+"AX\n";
			
		}
		
		else if(d2->lex_type=="CONS_INT" && d1->arraylength>-1)
		{
			ostringstream convert;
			ostringstream convert1;
			convert<<d1->array_index;
			convert1<<d2->intvalue;
			s->code=d1->code+"MOV [DI],"+convert1.str()+"\n";
		}
		
		else if(d1->arraylength==-1 && d2->arraylength>-1)
	       {
		
		
		s->code=d2->code+ "MOV AX,[DI]\nMOV "+d1->symbol+","+"AX\n";
		
	       }
	       
	       else
	      	 s->code=d2->code+"MOV "+d1->symbol+",AX\n";
	}
	if(d1->data_type =="float" && d2->data_type=="float")
	{
		s->floatvalue=d2->floatvalue;
		if(d2->lex_type=="CONS_FLOAT" && d1->arraylength==-1)
		{
			ostringstream convert;
			
			convert<<d2->floatvalue;
			s->code ="MOV AX,"+convert.str()+"\n"+"MOV "+d1->symbol+","+"AX\n";
		}
		else if(d2->lex_type=="CONS_FLOAT" && d1->arraylength>-1)
		{
			ostringstream convert;
			ostringstream convert1;
			convert<<d1->array_index;
			convert1<<d2->floatvalue;
			s->code=d1->code+"MOV [DI],"+convert1.str()+"\n";
		}
		
		else if(d1->arraylength==-1 && d2->arraylength>-1)
	       {
		
		
		s->code=d2->code+"MOV AX,[DI]\nMOV "+d1->symbol+","+"AX\n";
		
	       }
	        else
	      	 s->code=d2->code+"MOV "+d1->symbol+",AX\n";
	}
	if(d1->data_type=="int" && d2->data_type=="int")
	{
		s->intvalue=d2->intvalue;
		if(d2->lex_type=="CONS_INT" && d1->arraylength==-1)
		{
			ostringstream convert;
			
			convert<<d2->intvalue;
			s->code ="MOV AX,"+convert.str()+"\n"+"MOV "+d1->symbol+","+"AX\n";
		}
		else if(d2->lex_type=="CONS_INT" && d1->arraylength>-1)
		{
			ostringstream convert;
			ostringstream convert1;
			convert<<d1->array_index;
			convert1<<d2->intvalue;
			s->code=d1->code+"MOV [DI],"+convert1.str()+"\n";
		}
		
		else if(d1->arraylength==-1 && d2->arraylength>-1)
	       {
		
		
		s->code=d2->code+"MOV AX,[DI]\nMOV "+d1->symbol+","+"AX\n";
		
	       }
	        else
	      	 s->code=d2->code+"MOV "+d1->symbol+",AX\n";
	}
	if(d1->data_type=="int" && d2->data_type=="float")
	{
		s->intvalue=d2->floatvalue;
		if(d2->lex_type=="CONS_FLOAT" && d1->arraylength==-1)
		{
			ostringstream convert;
			
			convert<<d2->floatvalue;
			s->code ="MOV AX,"+convert.str()+"\n"+"MOV "+d1->symbol+","+"AX\n";
		}
		else if(d2->lex_type=="CONS_FLOAT" && d1->arraylength>-1)
		{
			ostringstream convert;
			ostringstream convert1;
			convert<<d1->array_index;
			convert1<<d2->floatvalue;
			s->code=d1->code+"MOV [DI],"+convert1.str()+"\n";
		}
		 
		
		else if(d1->arraylength==-1 && d2->arraylength>-1)
	       {
		
		
		s->code=d2->code+"MOV AX,[DI]\nMOV "+d1->symbol+","+"AX\n";
		
	       }
	        else
	      	 s->code=d2->code+"MOV "+d1->symbol+",AX\n";
	}
	
	

	return s;
	


}

symbolinfo* processLogic(symbolinfo* d1, symbolinfo* d2, symbolinfo* d3){
	symbolinfo* dd = new symbolinfo();
	dd->data_type="int";
	int temp;
	string logicop=d2->symbol;
	string label_true=label();
	string label_false=label();
	string temp_var=temp_str();
	
	
	if(d1->lex_type=="ID" && d3->lex_type=="ID"){
	if((d1->data_type=="int") && (d3->data_type=="int")){
	float x=d1->intvalue;
	float y=d3->intvalue;
	
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
				
			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
			
			
	}

	if(d1->data_type=="int" && d3->data_type=="float"){
	float x=d1->intvalue;
	float y=d3->floatvalue;
	
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
	}

	if(d1->data_type=="float" && d3->data_type=="int"){
	float x=d1->floatvalue;
	float y=d3->intvalue;
	
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";

			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
	}

	if(d1->data_type=="float" && d3->data_type=="float"){
	float x=d1->floatvalue;
	float y=d3->floatvalue;
	
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";

			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+d3->symbol+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
				
			}
	}
	}
	
if(d1->lex_type !="ID" && d3->lex_type!="ID"){
	
	
	ostringstream convert;
	ostringstream convert1;
	if((d1->data_type=="int") && (d3->data_type=="int")){
	float x=d1->intvalue;
	float y=d3->intvalue;
	convert<<x;
	convert1<<y;
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
				
			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
			
			
	}

	if(d1->data_type=="int" && d3->data_type=="float"){
	float x=d1->intvalue;
	float y=d3->floatvalue;
	convert<<x;
	convert1<<y;
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
	}

	if(d1->data_type=="float" && d3->data_type=="int"){
	float x=d1->floatvalue;
	float y=d3->intvalue;
	convert<<x;
	convert1<<y;
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";

			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
			}
	}

	if(d1->data_type=="float" && d3->data_type=="float"){
	float x=d1->floatvalue;
	float y=d3->floatvalue;
	convert<<x;
	convert1<<y;
	if(logicop=="&&") {
				temp=x&&y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JE "+label_false+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_true+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";

			}
	if(logicop=="||") {
				temp=x||y;
				dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV AX,"+convert1.str()+"\n"+"CMP AX,0\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",1\n"+"JMP "+label_false+"\n"+label_false+":\n"+"MOV "+temp_var+",1\n"+label_true+":\n"+"MOV AX,1\n";
				
			}
	}
	
	
	
	
	}
	dd->intvalue=temp;

	return dd;

}


symbolinfo* processRelation(symbolinfo* d1,string relation,symbolinfo* d3)
{
	symbolinfo* dd = new symbolinfo();
	dd->data_type="int";
	string label_true=label();
	string label_false=label();
	string temp_var=temp_str();
	ostringstream convert;
	ostringstream convert1;
	
	if(d1->lex_type == "ID" && d3->lex_type=="ID"){
	if(relation==">") {
				if(d1->data_type=="int" && d3->data_type=="int") dd->intvalue=(d1->intvalue)>(d3->intvalue);
				if(d1->data_type=="int" && d3->data_type=="float") dd->intvalue=(d1->intvalue)>(d3->floatvalue);
				if(d1->data_type=="float" && d3->data_type=="int") dd->intvalue=(d1->floatvalue)>(d3->intvalue);
				if(d1->data_type=="float" && d3->data_type=="float") dd->intvalue=(d1->floatvalue)>(d3->floatvalue);
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,"+d3->symbol+"\n"+"JG "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";
			}
	if(relation=="<") {
				if(d1->data_type=="int" && d3->data_type=="int") dd->intvalue=(d1->intvalue)<(d3->intvalue);
				if(d1->data_type=="int" && d3->data_type=="float") dd->intvalue=(d1->intvalue)<(d3->floatvalue);
				if(d1->data_type=="float" && d3->data_type=="int") dd->intvalue=(d1->floatvalue)<(d3->intvalue);
				if(d1->data_type=="float" && d3->data_type=="float") dd->intvalue=(d1->floatvalue)<(d3->floatvalue);
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,"+d3->symbol+"\n"+"JL "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";
			}
	if(relation=="<=") {
				if(d1->data_type=="int" && d3->data_type=="int") dd->intvalue=(d1->intvalue)<=(d3->intvalue);
				if(d1->data_type=="int" && d3->data_type=="float") dd->intvalue=(d1->intvalue)<=(d3->floatvalue);
				if(d1->data_type=="float" && d3->data_type=="int") dd->intvalue=(d1->floatvalue)<=(d3->intvalue);
				if(d1->data_type=="float" && d3->data_type=="float") dd->intvalue=(d1->floatvalue)<=(d3->floatvalue);
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,"+d3->symbol+"\n"+"JLE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";
				
			}
	if(relation==">=") {
				if(d1->data_type=="int" && d3->data_type=="int") dd->intvalue=(d1->intvalue)>=(d3->intvalue);
				if(d1->data_type=="int" && d3->data_type=="float") dd->intvalue=(d1->intvalue)>=(d3->floatvalue);
				if(d1->data_type=="float" && d3->data_type=="int") dd->intvalue=(d1->floatvalue)>=(d3->intvalue);
				if(d1->data_type=="float" && d3->data_type=="float") dd->intvalue=(d1->floatvalue)>=(d3->floatvalue);
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,"+d3->symbol+"\n"+"JGE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";
			}
	if(relation=="==") {
				if(d1->data_type=="int" && d3->data_type=="int") dd->intvalue=(d1->intvalue)==(d3->intvalue);
				if(d1->data_type=="int" && d3->data_type=="float") dd->intvalue=(d1->intvalue)==(d3->floatvalue);
				if(d1->data_type=="float" && d3->data_type=="int") dd->intvalue=(d1->floatvalue)==(d3->intvalue);
				if(d1->data_type=="float" && d3->data_type=="float") dd->intvalue=(d1->floatvalue)==(d3->floatvalue);
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,"+d3->symbol+"\n"+"JE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";
			}
	if(relation=="!=") {
				if(d1->data_type=="int" && d3->data_type=="int") dd->intvalue=(d1->intvalue)!=(d3->intvalue);
				if(d1->data_type=="int" && d3->data_type=="float") dd->intvalue=(d1->intvalue)!=(d3->floatvalue);
				if(d1->data_type=="float" && d3->data_type=="int") dd->intvalue=(d1->floatvalue)!=(d3->intvalue);
				if(d1->data_type=="float" && d3->data_type=="float") dd->intvalue=(d1->floatvalue)!=(d3->floatvalue);
				dd->code="MOV AX,"+d1->symbol+"\n"+"CMP AX,"+d3->symbol+"\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";
			}
			}
			
			
			
if(d1->lex_type != "ID" && d3->lex_type !="ID"){



	if(relation==">") {
				if(d1->data_type=="int" && d3->data_type=="int") {dd->intvalue=(d1->intvalue)>(d3->intvalue);convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JG "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				
				if(d1->data_type=="int" && d3->data_type=="float") {dd->intvalue=(d1->intvalue)>(d3->floatvalue);convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JG "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="int") {dd->intvalue=(d1->floatvalue)>(d3->intvalue);convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JG "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="float") {dd->intvalue=(d1->floatvalue)>(d3->floatvalue);convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JG "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
			}
	if(relation=="<") {
				if(d1->data_type=="int" && d3->data_type=="int") {dd->intvalue=(d1->intvalue)<(d3->intvalue);convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JL "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				
				if(d1->data_type=="int" && d3->data_type=="float") {dd->intvalue=(d1->intvalue)<(d3->floatvalue);convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JL "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="int") {dd->intvalue=(d1->floatvalue)<(d3->intvalue);convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JL "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="float") {dd->intvalue=(d1->floatvalue)<(d3->floatvalue);convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JL "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
			}
	if(relation=="<=") {
				if(d1->data_type=="int" && d3->data_type=="int") {dd->intvalue=(d1->intvalue)<=(d3->intvalue);convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JLE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				
				if(d1->data_type=="int" && d3->data_type=="float") {dd->intvalue=(d1->intvalue)<=(d3->floatvalue);convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JLE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="int") {dd->intvalue=(d1->floatvalue)<=(d3->intvalue);convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JLE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="float") {dd->intvalue=(d1->floatvalue)<=(d3->floatvalue);convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JLE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
			}
	if(relation==">=") {
				if(d1->data_type=="int" && d3->data_type=="int") {dd->intvalue=(d1->intvalue)>=(d3->intvalue);convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JGE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				
				if(d1->data_type=="int" && d3->data_type=="float") {dd->intvalue=(d1->intvalue)>=(d3->floatvalue);convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JGE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="int") {dd->intvalue=(d1->floatvalue)>=(d3->intvalue);convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JGE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="float") {dd->intvalue=(d1->floatvalue)>=(d3->floatvalue);convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JGE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
			}
			
	if(relation=="==") {
				if(d1->data_type=="int" && d3->data_type=="int") {dd->intvalue=(d1->intvalue)==(d3->intvalue);convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				
				if(d1->data_type=="int" && d3->data_type=="float") {dd->intvalue=(d1->intvalue)==(d3->floatvalue);convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="int") {dd->intvalue=(d1->floatvalue)==(d3->intvalue);convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="float") {dd->intvalue=(d1->floatvalue)==(d3->floatvalue);convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
			}
	if(relation=="!=") {
				if(d1->data_type=="int" && d3->data_type=="int") {dd->intvalue=(d1->intvalue)!=(d3->intvalue);convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				
				if(d1->data_type=="int" && d3->data_type=="float") {dd->intvalue=(d1->intvalue)!=(d3->floatvalue);convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="int") {dd->intvalue=(d1->floatvalue)!=(d3->intvalue);convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
				if(d1->data_type=="float" && d3->data_type=="float") {dd->intvalue=(d1->floatvalue)!=(d3->floatvalue);convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"CMP AX,"+convert1.str()+"\n"+"JNE "+label_true+"\n"+"MOV "+temp_var+",0\n"+"JMP "+label_false+"\n"+label_true+":\n"+"MOV "+temp_var+",1\n"+label_false+":\n";}
				
			}
		}
	return dd;
}


symbolinfo* processAdd(symbolinfo* d1,string addop,symbolinfo* d3)
{
	symbolinfo* dd=new symbolinfo();
	if((d1->arraylength==-1 && d1->lex_type !="ID") && (d3->arraylength==-1 && d3->lex_type != "ID")){
	if(addop=="+")
	{
		ostringstream convert;
		ostringstream convert1;
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	{dd->floatvalue=d1->floatvalue+d3->intvalue;convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"ADD AX,"+convert1.str()+"\n";}
			if(d1->data_type=="int" && d3->data_type=="float")	{dd->floatvalue=d1->intvalue+d3->floatvalue;convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"ADD AX,"+convert1.str()+"\n";}
			if(d1->data_type=="float" && d3->data_type=="float")	{dd->floatvalue=d1->floatvalue+d3->floatvalue;convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"ADD AX,"+convert1.str()+"\n";}
		
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue+d3->intvalue;
			convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"ADD AX,"+convert1.str()+"\n";
		}
		
		
	}

	if(addop=="-")
	{
		ostringstream convert;
		ostringstream convert1;
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	{dd->floatvalue=d1->floatvalue-d3->intvalue;convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"SUB AX,"+convert1.str()+"\n";}
			if(d1->data_type=="int" && d3->data_type=="float")	{dd->floatvalue=d1->intvalue-d3->floatvalue;convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"SUB AX,"+convert1.str()+"\n";}
			if(d1->data_type=="float" && d3->data_type=="float")	{dd->floatvalue=d1->floatvalue-d3->floatvalue;convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"SUB AX,"+convert1.str()+"\n";}
		
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue-d3->intvalue;
			convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"SUB AX,"+convert1.str()+"\n";
		}
		
		
	}
    }
    
    
    
    if((d1->arraylength==-1 && d1->lex_type =="ID") && (d3->arraylength==-1 && d3->lex_type == "ID")){
	if(addop=="+")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue+d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue+d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue+d3->floatvalue;
			
			
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue+d3->intvalue;
			
		}
		
		dd->code="MOV AX,"+d1->symbol+"\n"+"ADD AX,"+d3->symbol+"\n";
		
		
	}

	if(addop=="-")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			
			
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue-d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue-d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue-d3->floatvalue;
	
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue-d3->intvalue;
		
		
		}
		
		dd->code="MOV AX,"+d1->symbol+"\n"+"SUB AX,"+d3->symbol+"\n";
		
	}
    }
    
    
    
    if(d1->arraylength>-1 && d3->arraylength>-1){
	if(addop=="+")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue+d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue+d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue+d3->floatvalue;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue+d3->intvalue;
		}
		
		
		
		dd->code=d1->code+"MOV AX,[DI]\n"+d3->code+"MOV BX,[DI]\n"+"ADD AX,BX\n";
	}

	if(addop=="-")
	{
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue-d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue-d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue-d3->floatvalue;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue-d3->intvalue;
		}
		
		dd->code=d1->code+"MOV AX,[DI]\n"+d3->code+"MOV BX,[DI]\n"+"SUB AX,BX\n";
	

	}
    }
    
	return dd;
}

symbolinfo* processMul(symbolinfo* d1,string mulop,symbolinfo* d3)
{
	symbolinfo* dd=new symbolinfo();
	if((d1->arraylength==-1 && d1->lex_type !="ID") && (d3->arraylength==-1 && d3->lex_type != "ID")){
	if(mulop=="*")
	{
		ostringstream convert;
		ostringstream convert1;
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	{dd->floatvalue=d1->floatvalue*d3->intvalue;convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"MUL "+convert1.str()+"\n";}
			if(d1->data_type=="int" && d3->data_type=="float")	{dd->floatvalue=d1->intvalue*d3->floatvalue;convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"MUL ,"+convert1.str()+"\n";}
			if(d1->data_type=="float" && d3->data_type=="float")	{dd->floatvalue=d1->floatvalue*d3->floatvalue;convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"MUL "+convert1.str()+"\n";}
		
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue*d3->intvalue;
			convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"MUL "+convert1.str()+"\n";
		}
		
		
	}

	if(mulop=="/")
	{
		ostringstream convert;
		ostringstream convert1;
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	{dd->floatvalue=d1->floatvalue/d3->intvalue;convert<<d1->floatvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"DIV "+convert1.str()+"\n";}
			if(d1->data_type=="int" && d3->data_type=="float")	{dd->floatvalue=d1->intvalue/d3->floatvalue;convert<<d1->intvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"DIV ,"+convert1.str()+"\n";}
			if(d1->data_type=="float" && d3->data_type=="float")	{dd->floatvalue=d1->floatvalue/d3->floatvalue;convert<<d1->floatvalue;convert1<<d3->floatvalue;dd->code="MOV AX,"+convert.str()+"\n"+"DIV "+convert1.str()+"\n";}
		
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue/d3->intvalue;
			convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"DIV "+convert1.str()+"\n";
		}
		
		
	}

	if(mulop=="%"){
	
		ostringstream convert;
		ostringstream convert1;
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="int";
			logfile<<"Modulus operator does not work on floating point"<<endl;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue%d3->intvalue;
			convert<<d1->intvalue;convert1<<d3->intvalue;dd->code="MOV AX,"+convert.str()+"\n"+"DIV "+convert1.str()+"\n";
		
		
		}
		
	}
	}
	
	if((d1->arraylength==-1 && d1->lex_type =="ID") && (d3->arraylength==-1 && d3->lex_type == "ID")){
	if(mulop=="*")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue*d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue*d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue*d3->floatvalue;
			
			
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue*d3->intvalue;
			
		}
		
		dd->code="MOV AX,"+d1->symbol+"\n"+"MUL "+d3->symbol+"\n";
		
		
	}
	
	if(mulop=="/")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue/d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue/d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue/d3->floatvalue;
			
			
		}
		else
		{
			dd->data_type="int";
			
			dd->intvalue=d1->intvalue/d3->intvalue;
			
		}
		
		dd->code="MOV AX,"+d1->symbol+"\n"+"DIV "+d3->symbol+"\n";
		
		
	}
	
	if(mulop=="%")
	{
		
	
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="int";
			logfile<<"Modulus operator does not work on floating point"<<endl;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue%d3->intvalue;
			dd->code="MOV AX,"+d1->symbol+"\n"+"DIV "+d3->symbol+"\n";
		
		
		}
		
	}
		
		
		
	
	}
	
	
	if(d1->arraylength>-1 && d3->arraylength>-1){
	if(mulop=="*")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue*d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue*d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue*d3->floatvalue;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue*d3->intvalue;
		}
		
		
		
		dd->code=d3->code+"MOV BX,[DI]\n"+d1->code+"MOV AX,[DI]\n"+"MUL BX\n";
	}
	
	if(mulop=="/")
	{
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="float";
			if(d1->data_type=="float" && d3->data_type=="int")	dd->floatvalue=d1->floatvalue/d3->intvalue;
			if(d1->data_type=="int" && d3->data_type=="float")	dd->floatvalue=d1->intvalue/d3->floatvalue;
			if(d1->data_type=="float" && d3->data_type=="float")	dd->floatvalue=d1->floatvalue/d3->floatvalue;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue/d3->intvalue;
		}
		
		
		
		dd->code=d3->code+"MOV BX,[DI]\n"+d1->code+"MOV AX,[DI]\n"+"DIV BX\n";
	}
	
	
	if(mulop=="%")
	{
		
	
		
		if(d1->data_type=="float" || d3->data_type=="float")
		{
			dd->data_type="int";
			logfile<<"Modulus operator does not work on floating point"<<endl;
		}
		else
		{
			dd->data_type="int";
			dd->intvalue=d1->intvalue%d3->intvalue;
			dd->code=d3->code+"MOV BX,[DI]\n"+d1->code+"MOV AX,[DI]\n"+"DIV BX\n";
		
		
		}
		
	
		
		
		
		dd->code=d3->code+"MOV BX,[DI]\n"+d1->code+"MOV AX,[DI]\n"+"DIV BX\n";
	}
	}
	return dd;
}




symbolinfo* handle_for_loop(symbolinfo* init_cond, symbolinfo* loop_cond, symbolinfo* after_cond, symbolinfo* body_stmt)
{
	symbolinfo* s = new symbolinfo();
	
	string loop_begin = label();
	string loop_end = label();
	
	string code = "";
	
	code = code + init_cond->code + "\n"; // initial statement
	
	code = code + loop_begin + ":\n"; // start iteration
	
	code = code + loop_cond->code + "\n";
	code = code + "MOV AX,t " + "\n";
	code = code + "CMP AX, 0\n";    // loop condition checking
	
	code = code + "JE " + loop_end + "\n"; // condition fail
	code = code + body_stmt->code + "\n";
	code = code + after_cond->code + "\n";
	code = code + "JMP " + loop_begin + "\n"; // repeat
	
	code = code + loop_end + ":\n";
	
	s-> code = s->code + code;
	
	return s;
}


symbolinfo* handle_while_loop(symbolinfo* loop_cond, symbolinfo* body_stmt)
{
	symbolinfo* s = new symbolinfo();
	
	string loop_begin = label();
	string loop_end = label();
	
	string code = "";
	
	code = code + loop_begin + ":\n"; // start iteration
	
	code = code + loop_cond->code + "\n";
	
	code = code + "MOV AX,t"+ "\n";
	code = code + "CMP AX, 0\n";    // loop condition checking
	
	code = code + "JE " + loop_end + "\n"; // condition fail
	code = code + body_stmt->code + "\n";
	code = code + "JMP " + loop_begin + "\n"; // repeat
	
	code = code + loop_end + ":\n";
	
	s-> code = s->code + code;
	
	//while(loop_cond->boolval) {body_stmt;}
	
	return s;
}


symbolinfo* handle_if_else(symbolinfo* expr, symbolinfo* stmt_1, symbolinfo* stmt_2)
{
	symbolinfo* s = new symbolinfo();
	
	string label_false = label();
	string label_continue = label();
	
	string code = "";
	code = code + expr->code + "\n";
	
	code = code + "MOV AX, " + expr->symbol + "\n";
	
	code = code + "CMP AX, 0\n";
	code = code + "JE " + label_false + "\n"; //else
	
	//label_true
	code = code + stmt_1->code + "\n";
	code = code + "JMP " + label_continue + "\n";
	
	//label_false
	code = code + label_false + ":\n";
	code = code + stmt_2->code + "\n";
	
	//label_continue
	code = code + label_continue + ":\n";
	
	s->code = s->code + code;
	
	return s;
}

symbolinfo* processAddunary(string addop,symbolinfo* d)
{
	symbolinfo* dd=new symbolinfo();
	dd->data_type=d->data_type;
	if(addop=="+")
	{
		if(d->data_type=="int") dd->intvalue=d->intvalue;
		if(d->data_type=="float") dd->floatvalue=d->floatvalue;
		

	}
	if(addop=="-")
	{
		if(d->data_type=="int") dd->intvalue=-(d->intvalue);
		if(d->data_type=="float") dd->floatvalue=-(d->floatvalue);
		

	}
	return dd;
}


symbolinfo* handle_if(symbolinfo* expression, symbolinfo* statement)
{
	symbolinfo* s = new symbolinfo();
	
	string label_false = label();
	
	string code = "";
	code = code + expression->code + "\n";
	code = code + "MOV AX, " + expression->symbol + "\n";
	code = code + "CMP AX, 0\n";
	code = code + "JE " + label_false + "\n";
	code = code + statement->code + "\n";
	code = code + label_false + ":\n";
	
	return s;
}



symbolinfo* processNotunary(symbolinfo* d)
{
	symbolinfo* dd=new symbolinfo();
	dd->data_type="int";
	if(d->data_type=="int")
	{
		if(d->intvalue==0)	dd->intvalue=1;
		else dd->intvalue=0;
	}
	if(d->data_type=="float")
	{
		if(d->floatvalue==0)	dd->intvalue=1;
		else dd->intvalue=0;
	}
	return dd;
}

symbolinfo* processInc(symbolinfo* d)
{
	symbolinfo* dd=new symbolinfo();;
	dd->data_type=d->data_type;
	if(d->data_type=="int")		{dd->intvalue=d->intvalue+1;dd->code="MOV AX,"+d->symbol+"\n"+"INC AX\n"+"MOV "+d->symbol+",AX\n";}
	if(d->data_type=="float")	{dd->floatvalue=d->floatvalue+1;dd->code="MOV AX,"+d->symbol+"\n"+"INC AX\n"+"MOV "+d->symbol+",AX\n";}
	return dd;

}

symbolinfo* processDec(symbolinfo* d)
{
	symbolinfo* dd=new symbolinfo();;
	dd->data_type=d->data_type;
	if(d->data_type=="int")		{dd->intvalue=d->intvalue-1;dd->code="MOV AX,"+d->symbol+"\n"+"DEC AX\n"+"MOV "+d->symbol+",AX\n";}
	if(d->data_type=="float")	{dd->floatvalue=d->floatvalue-1;dd->code="MOV AX,"+d->symbol+"\n"+"DEC AX\n"+"MOV "+d->symbol+",AX\n";}
	return dd;

}



%}

%token CONST_INT CONST_FLOAT CONST_CHAR ID INCOP MULOP ADDOP RELOP LOGICOP ASSIGNOP LPAREN RPAREN RTHIRD LTHIRD LCURL RCURL COMMA SEMICOLON NOT DECOP IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE  STRING MAIN PRINTLN

%left '+' '-'
%left '*' '/'


%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		logfile<<"Line No:"<<line_count<<" start-> program\n\n";
		
	}
	;

program : program unit
	{
		logfile<<"Line No:"<<line_count<<" program-> program unit\n\n";
	}  
	| 
	unit
	{
		logfile<<"Line No:"<<line_count<<" program-> unit\n\n";
		
		
		
	}
	;
	
unit : var_declaration
	{
		logfile<<"Line No:"<<line_count<<" unit-> var_declaration\n\n";
	}
     	| 
     	func_declaration
     	{
		logfile<<"Line No:"<<line_count<<" unit-> func_declaration\n\n";
     	}
     	| 
     	func_definition
     	{
		logfile<<"Line No:"<<line_count<<" unit-> func_definition \n\n";
     	}
     	;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
			{
				logfile<<"Line No:"<<line_count<<" func_declaration-> type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n"<<$2->symbol<<"\n";
				
				$$=$2;
				
			}
		 	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement  {
				logfile<<"Line No:"<<line_count<<" func_declaration-> type_specifier ID LPAREN parameter_list RPAREN compound_statement\n"<<$2->symbol<<"\n";processfunc(datatype,$2,$6);$$=$2;}
			
 		 	;
 		 
parameter_list  : parameter_list COMMA type_specifier ID	{logfile<<"Line No:"<<line_count<<" parameter_list-> parameter_list COMMA type_specifier ID\n"<<$4->symbol<<"\n";bang=1;processID(datatype,$4);$$=$4;}

		| parameter_list COMMA type_specifier	 	{logfile<<"Line No:"<<line_count<<" parameter_list-> parameter_list COMMA type_specifier\n\n";bang=1;}

 		| type_specifier ID				{logfile<<"Line No:"<<line_count<<" parameter_list-> type_specifier ID\n"<<$2->symbol<<"\n";bang=1;processID(datatype,$2);$$=$2;}

 		| type_specifier				{logfile<<"Line No:"<<line_count<<" parameter_list-> type_specifier\n\n";bang=1;}
 		|						{bang=1;}
		;
 		
compound_statement : LCURL statements RCURL	{logfile<<"Line No:"<<line_count<<" compound_statement-> LCURL statements RCURL\n\n";$$=$2;}
 		    | LCURL RCURL		{logfile<<"Line No:"<<line_count<<" compound_statement-> LCURL  RCURL\n\n";}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON	{logfile<<"Line No:"<<line_count<<" var_declaration-> type_specifier declaration_list SEMICOLON\n\n";$$=$2;}
 		 ;
 		 
type_specifier	: INT		{logfile<<"Line No:"<<line_count<<" type_specifier-> INT\n\n";$$=$1;datatype="int";}
 		| FLOAT		{logfile<<"Line No:"<<line_count<<" type_specifier-> FLOAT\n\n";$$=$1;datatype="float";}
 		| VOID		{logfile<<"Line No:"<<line_count<<" type_specifier-> VOID\n\n";$$=$1;datatype="void";}
 		;
 		
declaration_list : declaration_list COMMA ID				{logfile<<"Line No:"<<line_count<<" declaration_list-> declaration_list COMMA ID\n"<<$3->symbol<<"\n";processID(datatype,$3);$$=$3;}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD	{logfile<<"Line No:"<<line_count<<" declaration_list-> declaration_list COMMA ID LTHIRD CONS_INT RTHIRD\n"<<$3->symbol<<"\n"<<$5->intvalue<<"\n";processArray(datatype,$3,$5->intvalue);$$=$3;}
 		  | ID							{logfile<<"Line No:"<<line_count<<" declaration_list-> ID\n"<<$1->symbol<<"\n";processID(datatype,$1); $$=$1;}

 		  | ID LTHIRD CONST_INT RTHIRD				{logfile<<"Line No:"<<line_count<<" declaration_list-> ID LTHIRD CONS_INT RTHIRD\n"<<$1->symbol<<"\n"<<$3->intvalue<<"\n";processArray(datatype,$1,$3->intvalue);$$=$1;}
 		  ;
 		  
statements : statement			{logfile<<"Line No:"<<line_count<<" statements-> statement\n\n";$$=$1;}
	   | statements statement	{logfile<<"Line No:"<<line_count<<" statements-> statements statement\n\n";$$=new symbolinfo();
	   $$->code=$1->code+$2->code;}
	   ;
	   
statement : var_declaration									{logfile<<"Line No:"<<line_count<<" statement-> var_declaration\n\n";$$=$1;}
	  | expression_statement								{logfile<<"Line No:"<<line_count<<" statement-> experession_statement\n\n";$$=$1;}
	  | compound_statement									{logfile<<"Line No:"<<line_count<<" statement-> compound_statement\n\n";$$=$1;}

	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement	{logfile<<"Line No:"<<line_count<<" statement-> FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";$$ = handle_for_loop($3, $4, $5, $7);}

	  | IF LPAREN expression RPAREN statement						{logfile<<"Line No:"<<line_count<<" statement-> IF LPAREN expression RPAREN statement\n\n";$$ = handle_if($3, $5);}

	  | IF LPAREN expression RPAREN statement ELSE statement				{logfile<<"Line No:"<<line_count<<" statement-> IF LPAREN expression RPAREN statement ELSE statement\n\n";$$ = handle_if_else($3, $5, $7);}

	  | WHILE LPAREN expression RPAREN statement						{logfile<<"Line No:"<<line_count<<" statement-> WHILE LPAREN expression RPAREN statement\n\n";$$ = handle_while_loop($3, $5);}

	  | PRINTLN LPAREN ID RPAREN SEMICOLON							{logfile<<"Line No:"<<line_count<<" statement-> RETURN LPAREN ID RPAREN SEMICOLON\n\n";}

	  | RETURN expression SEMICOLON								{logfile<<"Line No:"<<line_count<<" statement-> RETURN expression SEMICOLON\n\n";}
	  ;
	  
expression_statement 	: SEMICOLON			{logfile<<"Line No:"<<line_count<<" expression_statement-> SEMICOLON\n\n";}			
			| expression SEMICOLON 		{logfile<<"Line No:"<<line_count<<" expression_statement-> expression SEMICOLON\n\n";$$=$1;}
			;
	  
variable : ID					{logfile<<"Line No:"<<line_count<<" variable-> ID\n\n";$$=processIDAccess($1);} 		
	 | ID LTHIRD expression RTHIRD 		{logfile<<"Line No:"<<line_count<<" variable-> ID LTHIRD expression RTHIRD\n\n";$$=processArrayAccess($1,$3);}
	 ;
	 
 expression : logic_expression				{logfile<<"Line No:"<<line_count<<" expression-> logic_expression\n\n";$$=$1;}
	   | variable ASSIGNOP logic_expression 	{logfile<<"Line No:"<<line_count<<" expression-> variable ASSIGNOP logic_expression\n\n";$$=processAssign($1,$3);}
	   ;
			
logic_expression : rel_expression 				{logfile<<"Line No:"<<line_count<<" logic_expression-> rel_expression\n\n";
$$=$1;}								
		 | rel_expression LOGICOP rel_expression 	{logfile<<"Line No:"<<line_count<<" logic_expression-> rel_expression LOGICOP rel_expresson\n\n";$$=processLogic($1,$2,$3);}
		 ;
			
rel_expression	: simple_expression 				{logfile<<"Line No:"<<line_count<<" rel_exression-> simple_expression\n\n";
$$=$1;}								
		| simple_expression RELOP simple_expression	{logfile<<"Line No:"<<line_count<<" rel_expression-> simple_expression RELOP simple_expression\n\n";$$=processRelation($1,$2->symbol,$3);}
		;
				
simple_expression : term 				{logfile<<"Line No:"<<line_count<<" simple_expression-> term\n\n";$$=$1;}
		  | simple_expression ADDOP term 	{logfile<<"Line No:"<<line_count<<" simple_expression-> simple_expression ADDOP term\n\n";$$=processAdd($1,$2->symbol,$3);}
		  ;
					
term :	unary_expression		{logfile<<"Line No:"<<line_count<<" term-> unary_expression\n\n";$$=$1;}
     |  term MULOP unary_expression	{logfile<<"Line No:"<<line_count<<" term-> term MULOP unary_expression\n\n";$$=processMul($1,$2->symbol,$3);}
     ;

unary_expression : ADDOP unary_expression	{logfile<<"Line No:"<<line_count<<" unary_expression-> ADDOP unary_expression\n\n";$$=processAddunary($1->symbol,$2);}
		 | NOT unary_expression		{logfile<<"Line No:"<<line_count<<" unary_expression-> NOT unary_expression\n\n";$$=processNotunary($2);}	
		 | factor 			{logfile<<"Line No:"<<line_count<<" unary_expression-> factor\n\n";$$=$1;}
		 ;
	
factor	: variable 				{logfile<<"Line No:"<<line_count<<" factor-> variable\n\n";$$=$1;}
	| ID LPAREN argument_list RPAREN	{logfile<<"Line No:"<<line_count<<" factor-> ID LPAREN argument_list RPAREN\n\n";}
	| LPAREN expression RPAREN		{logfile<<"Line No:"<<line_count<<" factor-> LPAREN expression RPAREN\n\n";$$=$2;}
	| CONST_INT 				{logfile<<"Line No:"<<line_count<<" factor-> CONS_INT\n\n";$$=$1;}
	| CONST_FLOAT				{logfile<<"Line No:"<<line_count<<" factor-> CONS_FLOAT\n\n";$$=$1;}
	| variable INCOP 			{logfile<<"Line No:"<<line_count<<" factor-> variable INCOP\n\n";$$=processInc($1);}
	| variable DECOP			{logfile<<"Line No:"<<line_count<<" factor-> variable DECOP\n\n";$$=processDec($1);}
	;
	
argument_list : arguments	{logfile<<"Line No:"<<line_count<<" argument_list-> arguments\n\n";$$=$1;}
	      ;
arguments : arguments COMMA logic_expression	{logfile<<"Line No:"<<line_count<<" arguments-> arguments COMMA logic_expression\n\n";$$=$3;}
	 | logic_expression			{logfile<<"Line No:"<<line_count<<" arguments-> logic_expression\n\n";$$=$1;}
	 ;
 

%%
int main(int argc,char *argv[])
{
	table=new Symboltable(31);
	table->Enter_scope();
	logfile.open("log.txt");
	code.open("code.asm");
	logfile << "\n";
	yyin = fopen(argv[1], "r");
	
	array=new symbolinfo*[80];

	global_array=new symbolinfo*[80];

	cout << "##############################################################################" << endl;
	cout << "##############################################################################" << endl;
		
   	yyparse();
   	code<<dec_code+"\n";
   	code<<".CODE\n";
   	code <<func_code;
   	logfile << "\t\t symbol table:\n";
 	table->printAll();
 	logfile << endl;
 	logfile << "Total Lines: " << line_count << endl << endl;
 	logfile << "Total Errors: " << error << endl << endl;
 	
   	exit(0);
	
	
}

