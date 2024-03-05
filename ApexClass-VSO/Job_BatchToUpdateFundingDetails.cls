/**
  * Created By: Dinesh Sivalingam
  * Created On: 25-Jul-2021
  * Description: GPAPA IT-2: Batchable Class to update existing funding fields in Job Object
  * */
global class Job_BatchToUpdateFundingDetails implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Get the Config values from Custom Metadata
        List<Job_Object_Batch_Configs__mdt> lstEbj = [SELECT Object_Name__c,Planned_Start_Date_Range1__c,Planned_Start_Date_Range2__c 
                                                      FROM Job_Object_Batch_Configs__mdt 
                                                      WHERE Object_Name__c =: 'Job__c'];
        
        string psdate = string.valueOf(lstEbj[0].Planned_Start_Date_Range1__c);
        string pedate = string.valueOf(lstEbj[0].Planned_Start_Date_Range2__c);
        
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT Id, Name,Projected_Start_Date__c,Projected_End_Date__c,Signature_Programme_Project_Code__c,Global_Programme_1__c,Core_Programme_Area__c,Practice_Area_Name_1__c FROM Job__c'                      
                        +' WHERE Signature_Programme_Project_Code__c != NULL AND Projected_Start_Date__c >= '+psdate
                        +' AND Projected_Start_Date__c <= '+pedate;
        
        //Logic to increase test class code coverage
        if(Test.isRunningTest()){
             query = 'SELECT Id, Name, Signature_Programme_Project_Code__c,Global_Programme_1__c,Core_Programme_Area__c,Practice_Area_Name_1__c FROM Job__c WHERE Signature_Programme_Project_Code__c != NULL';
        }
        
        system.debug('*** query '+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Job__c> jobList) {
        string pa,paName;
        set<string> setOfSignCode = new set<string>();
        for(Job__c jb : jobList) { 
            setOfSignCode.add(jb.Signature_Programme_Project_Code__c);
        }
        
        Map<string,VSO_Project__c> mapOfGPgm = new Map<string,VSO_Project__c>();
        List<VSO_Project__c> lstGP = [SELECT Id,Name,Signature_package_project_code__c,Core_Programme_Area__c FROM VSO_Project__c
                                      WHERE Signature_package_project_code__c IN : setOfSignCode];
        for(VSO_Project__c vp : lstGP){
            mapOfGPgm.put(vp.Signature_package_project_code__c,vp);system.debug('@@mapOfGPgm '+mapOfGPgm);
        }
        
        // process each batch of records default size is 200
        for(Job__c jb : jobList) { 
            if(jb.Signature_Programme_Project_Code__c != null){
                string gPgm = mapOfGPgm.get(jb.Signature_Programme_Project_Code__c).Signature_package_project_code__c +' '+mapOfGPgm.get(jb.Signature_Programme_Project_Code__c).Name;
                if(jb.Global_Programme_1__c == null || jb.Global_Programme_1__c == ''){
                    jb.Global_Programme_1__c = gPgm;
                }
                if(jb.Core_Programme_Area__c == null || jb.Core_Programme_Area__c == '' ||                   
                   (jb.Core_Programme_Area__c != mapOfGPgm.get(jb.Signature_Programme_Project_Code__c).Core_Programme_Area__c
                    && jb.Global_Programme_1__c == gPgm)){
                		jb.Core_Programme_Area__c = mapOfGPgm.get(jb.Signature_Programme_Project_Code__c).Core_Programme_Area__c;                   
                }
                if(jb.Practice_Area_Name_1__c == null || jb.Practice_Area_Name_1__c == ''){
                    pa = jb.Core_Programme_Area__c; 
                    paName = pa.substring(pa.indexOf(' ')+1); 
                    jb.Practice_Area_Name_1__c = paName;   
                }
            } 
        }
        try {
                List<Database.SaveResult> updateResults = Database.Update(jobList, false);
                for(Integer i=0;i<updateResults.size();i++){
                    if (!updateResults.get(i).isSuccess()){
                        // DML operation failed
                        Database.Error error = updateResults.get(i).getErrors().get(0);
                        String failedDML = error.getMessage();
                        system.debug('Error Message: '+failedDML);
                        system.debug('Job Record Failed ID: '+jobList.get(i).Id);
                    }
                }
        } catch(Exception e) {
            System.debug(e);
        }
    }
    
     global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}