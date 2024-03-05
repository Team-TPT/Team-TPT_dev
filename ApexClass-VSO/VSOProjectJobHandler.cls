/************************************************************************************
* Description    : Update and Remove the value from the fields 'Core Programme Area' and 
			       'Signature Programme / Project Code' when a project is added or removed in Job record.
				     
* Developer Name : Narpavi
* Company        : TPT
* Date created   : 24/10/2018
* Remedyforce CR : CR-230   
            
**************************************************************************************/


public without sharing class VSOProjectJobHandler {
       
    private VSOProjectJobHandler()
    {       
            if(!trigger.isExecuting){
            throw new InternalException('Not in Trigger context!');
     		}
    }

    public void execute(){    
       
        if(trigger.isAfter){
            if(trigger.isInsert){
                  
                     updateJobRecord();                        
            }
            if(trigger.isdelete)
            {
                     removevalueinJobRecord();                                        
            }
           
        }
            //GPAPA IT-2: Method created to validate the user from being edit/delete the record    
            if(Trigger.isBefore){
                set<Id> jobIds = new set<Id>();
                if(Trigger.isInsert){
                    for(VSO_Project_Job__c jg : (List<VSO_Project_Job__c>) trigger.new){
                        jobIds.add(jg.Job__c);
                    }
                    JobGrantTriggerHandler.validateUserAccess(jobIds,JobGrantTriggerHandler.CREATE_OPERATION);            
                } else if(Trigger.isUpdate){
                    for(VSO_Project_Job__c jg : (List<VSO_Project_Job__c>) trigger.new){
                        jobIds.add(jg.Job__c);
                    }
                    JobGrantTriggerHandler.validateUserAccess(jobIds,JobGrantTriggerHandler.UPDATE_OPERATION);
                } else if(Trigger.isDelete){
                    for(VSO_Project_Job__c jg : (List<VSO_Project_Job__c>) trigger.old){
                        jobIds.add(jg.Job__c);
                    }
                    JobGrantTriggerHandler.validateUserAccess(jobIds,JobGrantTriggerHandler.DELETE_OPERATION);
                }           
            }
       
    }
   
  public void updateJobRecord()
 {
     List<VSO_Project_Job__c> scope= trigger.new;
     
      List<Id> jobIds=new List<Id>();
      List<Id> projectIds=new List<Id>();
       for(VSO_Project_Job__c vpj:scope)
       {
           jobIds.add(vpj.Job__c);
           projectIds.add(vpj.VSO_Project__c);
       }       
     
     Map<Id,Job__c> mapJob =new Map<id,Job__c> ([select id,Signature_Programme_Project_Code__c,Core_Programme_Area__c,Type__c,Help_CP_SP_Code_Updated__c from Job__c where Id IN:jobIds]);
     
     list<VSO_Project__c> lstproject=[select id,Core_Programme_Area__c,Signature_package_project_code__c from VSO_Project__c where id IN:projectIds];
     list<Job__c> lstjobupdate = new list<Job__c>();
     
     for(Job__c job:mapJob.values())
     {
         if(job !=null)
         {
             if(!job.Help_CP_SP_Code_Updated__c)
             {
             	Job__c newjob = new Job__c();
         	 	newjob.id= job.id;
                 //GPAPA IT-2 below code commented
         	 	//newjob.Core_Programme_Area__c = lstproject[0].Core_Programme_Area__c;
                newjob.Signature_Programme_Project_Code__c = lstproject[0].Signature_package_project_code__c;
                newjob.Help_CP_SP_Code_Updated__c = True;  
               lstjobupdate.add(newjob);
             }
        }                 
     } 
     
     try{
     if(lstjobupdate!=null)
     {
         update lstjobupdate;
     } 
     
     } catch (DMLException e) 
            {
                 string errMsg=string.valueOf(e);
                 string ValidationMessage;
                 if(errMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) 
                 {
                       ValidationMessage = errMsg.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                       trigger.new[0].addError(ValidationMessage);     
                 }
                 else
                       trigger.new[0].addError(e);    
            }     
     
     
 }   

public void removevalueinJobRecord()
 {
     List<VSO_Project_Job__c> scope= Trigger.old;
     
      List<Id> jobIds=new List<Id>();      
       for(VSO_Project_Job__c vpj:scope)
       {
           jobIds.add(vpj.Job__c);          
       }       
     
     list<Job__c> lstjobupdate = new list<Job__c>();
     Map<Id,Job__c> mapJob =new Map<id,Job__c> ([select id,Signature_Programme_Project_Code__c,Core_Programme_Area__c,Type__c,Help_CP_SP_Code_Updated__c from Job__c where Id IN:jobIds]);
                    
     for(Job__c job:mapJob.values())
     {        
        if(job !=null)
         {                          
         			Job__c newjob = new Job__c();
         			newjob.id= job.id;
             		//GPAPA IT-2 below code commented
         			//newjob.Core_Programme_Area__c = null;
                    newjob.Signature_Programme_Project_Code__c = null;
                  	newjob.Help_CP_SP_Code_Updated__c = False;
         			lstjobupdate.add(newjob);             
         }                  
     }
     
     if(lstjobupdate!=null)
     {
         update lstjobupdate;
     }
          
 }      
    
    
public static VSOProjectJobHandler getHandler(){
        if(handler == null){
            handler = new VSOProjectJobHandler();
        }
    return handler;
    }
    
    private static VSOProjectJobHandler handler;
    
    private static boolean trueFirstTimeOnly = true;
    
    // static function will only return true once in each transaction
    // used to avoid trigger recursion
    // see http://help.salesforce.com/apex/HTViewSolution?id=000133752&language=en_US
    public static boolean runOnce(){
        if(trueFirstTimeOnly){
            trueFirstTimeOnly = false; 
            return true;
        }else{
            return false;
        }
    }
    
    // for testing
    public static void ClearRunOnce()
    {
        trueFirstTimeOnly = true;
    }
         

}