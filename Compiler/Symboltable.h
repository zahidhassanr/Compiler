
#include <bits/stdc++.h>>

using namespace std;

extern ofstream logfile;

class symbolinfo
{
public:
    int sym_key;
    string symbol="!";
    string data_type;
    string lex_type="";
    int intvalue; 
    float floatvalue;
    char charvalue;
    bool isFunction;
    bool isArray=false;
    symbolinfo* next;
    int arraylength=-1;
    symbolinfo** array;
    string code;
    int array_index;

    symbolinfo(string symbol,string lex_type)
    {
        this->symbol=symbol;
        this->lex_type=lex_type;
	this->intvalue=-9999;
	this->floatvalue=-9999;
	this->charvalue='!';
	this->isFunction=false;
	
       
    }
    symbolinfo(){
    	
	this->intvalue=-9999;
	this->floatvalue=-9999;
	this->charvalue='!';
	this->isFunction=false;
}
    symbolinfo(char* symbol,char* lex_type,string data_type)
    {
	this->symbol=string(symbol);
	this->lex_type=string(lex_type);
	this->intvalue=-9999;
	this->floatvalue=-9999;
	this->charvalue='!';
	this->isFunction=false;
        this->data_type=data_type;
    }
    void createArray(symbolinfo* s,int size){
		arraylength = size;
		array = new symbolinfo*[size];
		for(int i=0; i<size; i++){
			array[i] = new symbolinfo();
			array[i]->data_type=data_type;
			array[i]->symbol=s->symbol;
			array[i]->arraylength=size;		
		}
	}

};

struct symbolpoint
{
    struct symbolinfo* head;
};

class scopetable
{
public:
    int scope_num;
    string scope_name;
    int bucket=31;
    symbolpoint *arr;
    scopetable *next;
    
    scopetable()
    {
	
        arr=new symbolpoint[bucket+1];
        for(int i=0;i<bucket;i++)
        {
            arr[i].head=NULL;

        }
      

    }
    void insert1(string sym,string tp)
    {

        int c=0;
        int hashkey=gethash(sym);
        if(arr[hashkey].head==NULL)
        {

            symbolinfo *newnode;
            newnode=new symbolinfo(sym,tp);
//            newnode->symbol=sym;
//            newnode->type=tp;
            newnode->sym_key=0;
            newnode->next=NULL;
            arr[hashkey].head=newnode;
            cout<<"Inserted into scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<newnode->sym_key<<endl;
        }
        else{
                c=1;
                symbolinfo *temp;
                temp=arr[hashkey].head;
                while(temp->next!=NULL)
                {
                    temp=temp->next;
                    c++;
                }
                symbolinfo *newnode;
                newnode=new symbolinfo(sym,tp);
//                newnode->symbol=sym;
//                newnode->type=tp;
                newnode->sym_key=c;
                newnode->next=NULL;
                temp->next=newnode;

                cout<<"Inserted into scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<newnode->sym_key<<endl;

       }
//        symbolinfo *sinfo;
//        sinfo=new symbolinfo;
//        sinfo->symbol=sym;
//        sinfo->type=tp;
//        sinfo->sym_key=listpos++;
//        int hashkey=gethash(sym);
//        scope[hashkey].push_back(sinfo);
       // cout<<"Inserted into scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<newnode->sym_key<<endl;
       c=0;

    }

    void insert1(symbolinfo* newnode)
    {

        int c=0;
        int hashkey=gethash(newnode->symbol);
        if(arr[hashkey].head==NULL)
        {

            
            newnode->sym_key=0;
            newnode->next=NULL;
            arr[hashkey].head=newnode;
            cout<<"Inserted into scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<newnode->sym_key<<endl;
        }
        else{
                c=1;
                symbolinfo *temp;
                temp=arr[hashkey].head;
                while(temp->next!=NULL)
                {
                    temp=temp->next;
                    c++;
                }
                
                newnode->sym_key=c;
                newnode->next=NULL;
                temp->next=newnode;

                cout<<"Inserted into scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<newnode->sym_key<<endl;

       }
//        symbolinfo *sinfo;
//        sinfo=new symbolinfo;
//        sinfo->symbol=sym;
//        sinfo->type=tp;
//        sinfo->sym_key=listpos++;
//        int hashkey=gethash(sym);
//        scope[hashkey].push_back(sinfo);
       // cout<<"Inserted into scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<newnode->sym_key<<endl;
       c=0;

    }



    bool lookup(string sym)
    {
        int flag=0;
        int hashkey=gethash(sym);
        symbolinfo *temp;
        temp=arr[hashkey].head;
        if(temp==NULL) return false;
        else{
                while(temp!=NULL)
                {
                    if(temp->symbol==sym)
                    {
                        flag=1;
                        cout<< "found in scopetable#"<<scope_num<< " in positon "<<hashkey<<"."<<temp->sym_key<<endl;
                        break;
                    }
                    temp=temp->next;
                }

        }
      //  list<symbolinfo>::iterator i;
//      //  for(i=scope[hashkey].begin();i!=scope[hashkey].end();i++)
//        {
//            if((*i).symbol==sym)
//            {
//
//            }
//        }
        if(flag==0)
        {
            return false;
        }
        else return true;

    }


symbolinfo* lookupid(string sym)
    {
        int flag=0;
        int hashkey=gethash(sym);
        symbolinfo *temp;
        temp=arr[hashkey].head;
        if(temp==NULL) return NULL;
        else{
                while(temp!=NULL)
                {
                    if(temp->symbol==sym)
                    {
                        flag=1;
                       //cout<< "found in scopetable#"<<scope_num<< " in positon "<<hashkey<<"."<<temp->sym_key<<endl;
                        break;
                    }
                    temp=temp->next;
                }

        }

        if(flag==0)
        {
            return NULL;
        }
        else return temp;

    }


    bool Delete(string sym)
    {
        int c=0;
        int hashkey=gethash(sym);
        symbolinfo *temp;
        symbolinfo *temp1;
        temp=arr[hashkey].head;
        temp1=arr[hashkey].head;
        if(temp==NULL) cout<<"Not found"<<endl;
        else if(temp->symbol==sym)
        {
            cout<<"Found in scopetable# "<<scope_num<<" at position "<<hashkey<<"."<<temp->sym_key<<" deleted entry at "<<hashkey<<"."<<temp->sym_key<<" from scopetable# "<<scope_num<<endl;
            c=1;
            arr[hashkey].head=NULL;
            free(temp);
        }
        else{
            while(temp!=NULL)
            {
                if(temp->symbol==sym)
                {
                    temp1->next=temp->next;
                    cout<<"deleted entry at"<<hashkey<<"."<<temp->sym_key<<"from scopetable"<<scope_num<<endl;
                    c=1;
                    break;
                }
                temp1=temp;
                temp=temp->next;

            }
            free(temp);
        }

        if(c==0) return false;
        else return true;
    }

    void print()
    {
        symbolinfo *temp;
        logfile<<"scopetable#"<<scope_num<<endl;
        for(int i=0;i<bucket;i++)
        {
            logfile<<i<<"-->  ";
            temp=arr[i].head;
            while(temp!=NULL)
            {
		
                logfile<<"< "<<temp->symbol<<" : "<<temp->lex_type ;
		if(temp->isFunction){	logfile<<">";}
		else{
		if(temp->data_type=="int") {
			if(temp->isArray){
				logfile<<" : ";
				for(int i=0;i<temp->arraylength;i++)
					logfile<<(temp->array[i])->intvalue<<",";		
				logfile<<">";}
			else 	logfile<<" : "<<temp->intvalue<<">";
		}
		if(temp->data_type=="float") {
			if(temp->isArray){
				logfile<<" : ";
				for(int i=0;i<temp->arraylength;i++)
					logfile<<(temp->array[i])->floatvalue<<",";		
				logfile<<">";}
		else	logfile<<" : "<<temp->floatvalue<<">";
		}		
		if(temp->data_type=="char") {
		if(temp->isArray){
				logfile<<" : ";
				for(int i=0;i<temp->arraylength;i++)
					logfile<<(temp->array[i])->charvalue<<",";		
				logfile<<">";}

		else	logfile<<" : "<<temp->charvalue<<">";
		}
	}
                temp=temp->next;
	        }
            
            logfile<<endl;
        }



    }
    int gethash(string sym)
    {
        int k=sym[0];
        int hashkey=k%bucket;
        return hashkey;
    }

};

class Symboltable
{
public:
    int bucket=31;
    int bang=0;
    int table_num=1;
    scopetable*  current;
    scopetable* head;
    Symboltable(int num)
    {
        bucket=num;
        current=NULL;
   	head=NULL;
	
    }
    void Enter_scope()
    {
       
        scopetable* scope_obj;
        scopetable* temp;
        scope_obj=new scopetable;
        if(current==NULL)
        {
            current=scope_obj;
            current->next=NULL;
	    head=current;
            

        }
        else
        {

            temp=current;
            current=scope_obj;
            current->next=temp;	
	    bang++;
	    
        }
        current->scope_num=table_num++;

        cout<<"New scopetable with id "<<current->scope_num<< " created"<<endl;
    
    }

    void Enter_scope(string name)
    {
       
        scopetable* scope_obj;
        scopetable* temp;
        scope_obj=new scopetable;
	scope_obj->scope_name=name;
        if(current==NULL)
        {
            current=scope_obj;
            current->next=NULL;
	    head=current;
            

        }
        else
        {

            temp=current;
            current=scope_obj;
            current->next=temp;
	    bang++;
        }
        current->scope_num=table_num++;

        cout<<"New scopetable with id "<<current->scope_num<< " created"<<endl;
    
    }


    void insert(string sym,string tp)
    {
        current->insert1(sym,tp);

    }

   void insert(symbolinfo* temp,scopetable* current)
  {
	current->insert1(temp);
  }

   void insert(symbolinfo* temp)
   {
	current->insert1(temp);
   }

   

    void Exit_scope()
    {
       scopetable* temp;
       if(current==NULL)
       {
           cout<<"There is no scopetable"<<endl;
       }
       else{

               temp=current;
               current=current->next;
               free(temp);
               cout<<"scopetable with id "<<table_num-1<<" removed"<<endl;
               table_num--;
            }

    }


    bool lookup_scope(string sym)
    {
        scopetable* temp;
        int flag=0;
        temp=current;
        if(temp==NULL) cout<<"There is no table"<<endl;
        else{
            while(temp!=NULL)
            {
                bool look=temp->lookupid(sym);
                if(look)
                {
                    flag=1;
                    break;
                }
                temp=temp->next;
            }
        }
        if(flag==0) return false;
	else return true;
    }


   symbolinfo* lookup_scope_id(char* sym)
    {
        scopetable* temp;
        int flag=0;
        temp=current;
	symbolinfo* look;
        if(temp==NULL) cout<<"There is no table"<<endl;
        else{
            while(temp!=NULL)
            {
                look=temp->lookupid(string(sym));
                if(look != NULL)
                {
                    flag=1;
                    break;
                }
                temp=temp->next;
            }
        }
        if(flag==0) return NULL;
	else return look;
    }


   symbolinfo* lookup_scope_id(string sym)
    {
        scopetable* temp;
        int flag=0;
        temp=current;
	symbolinfo* look;
        if(temp==NULL) cout<<"There is no table"<<endl;
        else{
            while(temp!=NULL)
            {
                look=temp->lookupid(sym);
                if(look != NULL)
                {
                    flag=1;
                    break;
                }
                temp=temp->next;
            }
        }
        if(flag==0) return NULL;
	else return look;
    }

    void removes(string sym)
    {
        scopetable* temp;
        int flag=0;
        temp=current;
        if(temp==NULL) cout<<"There is no table"<<endl;
        else{
            while(temp!=NULL)
            {
                bool delt=temp->Delete(sym);
                if(delt)
                {
                    flag=1;
                    break;
                }
                temp=temp->next;
            }
        }
        if(flag==0) cout<<"Not found"<<endl;
    }

    void printtable()
    {
        if(current==NULL) cout<<"No Table"<<endl;
       current->print();
    }

    void printAll()
    {
        scopetable* temp;
        temp=current;
        if(temp==NULL) cout<<"No table"<<endl;

        else{
            while(temp!=NULL)
            {
                temp->print();
                temp=temp->next;
            }
        }
    }


};
