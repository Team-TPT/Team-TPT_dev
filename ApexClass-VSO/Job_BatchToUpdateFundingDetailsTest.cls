@isTest 
public class Job_BatchToUpdateFundingDetailsTest {
    
    static testMethod void Job_BatchToUpdateFundingDetailsTest() {
        Profile p1 = [select id from profile where name='System Administrator'];  
        User u1 = new User(alias = 'share1', email='Job_UpdateApplicationShare1@testorg.com', 
            emailencodingkey='UTF-8', lastname='Job_UpdateApplicationShare1', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p1.Id, 
            timezonesidkey='America/Los_Angeles', username='Job_UpdateApplicationShare1@testorg.com');
        
        
            
            list<Country__c> lstCountry = new list<Country__c>();
            list<Job__c> lstJobs = new list<Job__c>();
            
            //prepare a dummy data for Country
            for(integer i=0; i<5;i++){
                Country__c cntry = TestDataClass.getCountry('TestClassCountry'+i);
                lstCountry.add(cntry);
            }
            //insert countries
            insert lstCountry;
            
            List<RecordType> JobRecordTypes=new List<RecordType>();
            JobRecordTypes=[select id,developername,name from RecordType where SobjectType='Job__c' AND (Developername='Employee_Job_Approved' OR Developername='Approved_Volunteer_Job')];
            
        System.runAs(u1) {
            Test.startTest();
            JobTriggerHandler.enableRandstad = false;          
            for(integer i=0; i<5;i++){
                if(i<3){
                    Job__c jb=new Job__c(Hiring_Manager__c=u1.id,RecordTypeid=JobRecordTypes[0].id,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob'+i,Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT'+i,Country__c=lstCountry[i].id,Job_Status__c='Approved for Recruitment');
                    lstJobs.add(jb);
                }else{
                    Job__c jb=new Job__c(Hiring_Manager__c=u1.id,RecordTypeid=JobRecordTypes[1].id,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob'+i,Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT'+i,Country__c=lstCountry[i].id,Job_Status__c='Approved for Recruitment');
                    lstJobs.add(jb);
                }
            }  
            insert lstJobs;  
            
            List<VSO_Project__c> projects = new List<VSO_Project__c>();
            projects.add(new VSO_Project__c(Name='Women’s Empowerment, Control over Incomes and Right to Food', Status__c='Active',Core_Programme_Area__c='L01 RESILIENT LIVELIHOODS',Signature_package_project_code__c='GP105'));
            projects.add(new VSO_Project__c(Name='Inclusive and Resilient Education', Status__c='Active',Core_Programme_Area__c='H01 HEALTH',Signature_package_project_code__c='GP101'));
            projects.add(new VSO_Project__c(Name='Global Leadership', Status__c='Active',Core_Programme_Area__c='I01 INITIATIVES',Signature_package_project_code__c='GP107'));
            insert projects;
            
            List<Grant__c> grants = new List<Grant__c>();           
            grants.add(new Grant__c(Name='BAT001', Grant_Name__c ='British Aid Trust - BAT',VSO_Project__c = projects[0].Id));
            grants.add(new Grant__c(Name='CIT005', Grant_Name__c ='Citi Foundation - YEEP',VSO_Project__c = projects[1].Id));
            grants.add(new Grant__c(Name='Placeholder', Grant_Name__c ='Placeholder',VSO_Project__c = projects[2].Id));
            insert grants;
            
            //Check insert logic
            List<Job_Grant__c> jobGrants = new List<Job_Grant__c>();                 
            jobGrants.add(new Job_Grant__c(Job__c=lstJobs[0].Id, Grant__c=grants[0].Id));   
            jobGrants.add(new Job_Grant__c(Job__c=lstJobs[0].Id, Grant__c=grants[1].Id));
            jobGrants.add(new Job_Grant__c(Job__c=lstJobs[0].Id, Grant__c=grants[2].Id));
            insert jobGrants;
            
            List<Job__c> lstJb = [Select id,Global_Programme_1__c,Core_Programme_Area__c from Job__c where id =: lstJobs[0].Id];
            for(Job__c j : lstJb){
                j.Global_Programme_1__c = '';
                j.Core_Programme_Area__c = '';
                j.Practice_Area_Name_1__c = '';
            }
            update lstJb;
            
            Job_BatchToUpdateFundingDetails obj = new Job_BatchToUpdateFundingDetails();
            Database.executeBatch(obj);
            Test.stopTest();
        }
     }   
    
     static testMethod void Job_BatchUpdateForFundingGrantDrivenTest() {
        Profile p1 = [select id from profile where name='System Administrator'];  
        User u1 = new User(alias = 'share1', email='Job_UpdateApplicationShare1@testorg.com', 
            emailencodingkey='UTF-8', lastname='Job_UpdateApplicationShare1', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p1.Id, 
            timezonesidkey='America/Los_Angeles', username='Job_UpdateApplicationShare1@testorg.com');
            
            list<Country__c> lstCountry = new list<Country__c>();
            list<Job__c> lstJobs = new list<Job__c>();
            
            //prepare a dummy data for Country
            for(integer i=0; i<5;i++){
                Country__c cntry = TestDataClass.getCountry('TestClassCountry'+i);
                lstCountry.add(cntry);
            }
            //insert countries
            insert lstCountry;
            
            List<RecordType> JobRecordTypes=new List<RecordType>();
            JobRecordTypes=[select id,developername,name from RecordType where SobjectType='Job__c' AND (Developername='Employee_Job_Approved' OR Developername='Approved_Volunteer_Job')];
            
        System.runAs(u1) {
            Test.startTest();
            JobTriggerHandler.enableRandstad = false;          
            Job__c jb=new Job__c(Signature_Programme_Project_Code__c = 'GP106',Hiring_Manager__c=u1.id,RecordTypeid=JobRecordTypes[0].id,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob',Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT',Country__c=lstCountry[0].id,Job_Status__c='Approved for Recruitment');
            insert jb;  
            
            List<VSO_Project__c> projects = new List<VSO_Project__c>();
            projects.add(new VSO_Project__c(Name='Women’s Empowerment, Control over Incomes and Right to Food', Status__c='Active',Core_Programme_Area__c='H01 HEALTH',Signature_package_project_code__c='GP105'));
            projects.add(new VSO_Project__c(Name='Inclusive and Resilient Education', Status__c='Active',Core_Programme_Area__c='H01 HEALTH',Signature_package_project_code__c='GP101'));
            projects.add(new VSO_Project__c(Name='Global Leadership', Status__c='Active',Core_Programme_Area__c='I01 INITIATIVES',Signature_package_project_code__c='GP107'));
            insert projects;
            
            List<Grant__c> grants = new List<Grant__c>();           
            grants.add(new Grant__c(Name='BAT001', Grant_Name__c ='British Aid Trust - BAT',VSO_Project__c = projects[0].Id));
            grants.add(new Grant__c(Name='CIT005', Grant_Name__c ='Citi Foundation - YEEP',VSO_Project__c = projects[1].Id));
            grants.add(new Grant__c(Name='Placeholder', Grant_Name__c ='Placeholder',VSO_Project__c = projects[2].Id));
            insert grants;
            
            //Check insert logic
            List<Job_Grant__c> jobGrants = new List<Job_Grant__c>();                 
            jobGrants.add(new Job_Grant__c(Job__c=jb.Id, Grant__c=grants[0].Id));   
            jobGrants.add(new Job_Grant__c(Job__c=jb.Id, Grant__c=grants[1].Id));
            jobGrants.add(new Job_Grant__c(Job__c=jb.Id, Grant__c=grants[2].Id));
            insert jobGrants;
            
            List<Job__c> lstJb = [Select id,Global_Programme_1__c,Core_Programme_Area__c from Job__c where id =: jb.Id];
            for(Job__c j : lstJb){
                j.Grant_1__c = '';
                j.Global_Programme_1__c = '';
                j.Core_Programme_Area__c = '';
                j.Practice_Area_Name_1__c = '';
            }
            update lstJb;
            
            Job_BatchUpdateForFundingGrantDriven obj1 = new Job_BatchUpdateForFundingGrantDriven();
            database.executeBatch(obj1);
            
            Test.stopTest();
        }
     }   

}