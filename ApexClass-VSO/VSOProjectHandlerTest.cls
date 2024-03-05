@isTest
private class VSOProjectHandlerTest {
    
    
    static testmethod void  testUpdateJob()
    {
        
        Id countryUser = [SELECT Id FROM User WHERE UserRoleId!='' AND isActive=true LIMIT 1].Id;
        Profile p1 = [select id from profile where name='System Administrator'];  
        User u1 = new User(alias = 'VSO33', email='VSOProject3@testorg.com', 
            emailencodingkey='UTF-8', lastname='TVSOProject33', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p1.Id, 
            timezonesidkey='America/Los_Angeles', username='VSOProject33@testorg.com');
                    

            Country__c cntry=new Country__c(Name='TestClassCountry', Region__c='Europe', Country_People_Manager__c=countryUser, Country_Director__c=countryUser);
            insert cntry;
            
            List<RecordType> JobRecordTypes=new List<RecordType>();
            JobRecordTypes=[select id,developername,name from RecordType where SobjectType='Job__c' AND (Developername='Volunteer_Job')];
            
            
        System.runAs(u1)
        {
                                    
            Job__c job=new Job__c(Hiring_Manager__c=u1.id,RecordTypeid=JobRecordTypes[0].id,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob',Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT',Country__c=cntry.id,Job_Status__c='Approved for Recruitment', Volunteer_Type__c='Voluntary Workforce',Volunteering_Within_VSO_Sub_Type__c='Selector');                               
            insert job;
                        
            VSO_Project__c project=new VSO_Project__c(Name='Test Project',Goals__c='Education',Core_Programme_Area__c='E01 Education',Status__c = 'Active');
            insert project;            
           
            VSO_Project_Job__c vsojb=new VSO_Project_Job__c(Job__c =job.id ,VSO_Project__c= project.id );
            insert vsojb;            
            
             VSOProjectJobHandler.ClearRunOnce();
           Test.startTest();
          job.Core_Programme_Area__c=project.Core_Programme_Area__c;
          update job;                                 
          Test.stopTest();
            
            try{
                Delete  vsojb;

            }
            catch(Exception ee)
            {
                
            }
            
                    
        }                   
    }
    
    static testmethod void testrunOnce(){
        Test.startTest();
        VSOProjectJobHandler.runOnce();
        Test.stopTest();
    }
    
}