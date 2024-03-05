@isTest
global class PB_UpdateSalaryRecordTest
{
static testmethod void salaryupdateunittest()
{
      
Id countryUser = [SELECT Id FROM User WHERE UserRoleId!='' AND isActive=true LIMIT 1].Id;      
        
    		User u1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]; 
    
        	Country__c country=new Country__c(Name='TestClassCountry', Region__c='Europe', Country_People_Manager__c=countryUser, Country_Director__c=countryUser);
        	insert country;
System.runAs(u1) 
        {
               
      	 	Account acc = new Account(Name='Test');
       		insert acc;
           
        	List<fHCM2__Policy__c> lstpol=new List<fHCM2__Policy__c	>();
            List<Id> polids=new List<Id>();
            lstpol.add(new fHCM2__Policy__c(Name='Test Policy',Other_Employer_Statutory_Cont_Ceiling__c=decimal.valueof('10')));
            lstpol.add(new fHCM2__Policy__c(Name='Test Policy1'));
            insert lstpol;
            polids.add(lstpol[0].id);
        
        	fHCM2__Department__c Dept=new fHCM2__Department__c(name='TestDepartment',fHCM2__Policy__c=lstpol[0].id);
        	insert Dept;  
            
            fHCM2__Team_Member__c tm=new fHCM2__Team_Member__c(fHCM2__First_Name__c='Test',fHCM2__Surname__c='Member',Recruitment_Partner__c=acc.id,Relationship_Manager__c=u1.id,fHCM2__Department__c=Dept.id);
        	insert tm; 
            
        	fHCM2__Employment__c er=new fHCM2__Employment__c(Notice_Period_months__c=decimal.valueof('2'),fHCM2__Basis__c='Employee',fHCM2__Active__c = True,fHCM2__Team_Member__c=tm.id);
            insert  er;
                                                  	           
        	fHCM2__Salary__c s = new fHCM2__Salary__c(fHCM2__Employment__c=er.id,
                                                  fHCM2__Active__c=True,fHCM2__Change_Reason__c='Starting salary',
                                                  fHCM2__Start_Date__c=system.today(),Basic_Annual_Salary__c=decimal.valueof('10000'),Social_Security_Cont_Fixed_Amount__c=decimal.valueof('1'),Other_Employer_Statutory_Contribution__c= decimal.valueof('1'));   
           	insert s;  
             
       PB_UpdateSalaryRecord.ClearRunOnce();           
       Test.startTest();     
       PB_UpdateSalaryRecord.GetPolicyDetails(polids);             
       Test.stopTest();            
                                 
       }    
}
}