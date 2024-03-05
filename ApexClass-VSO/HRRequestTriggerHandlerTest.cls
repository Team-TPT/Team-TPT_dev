@isTest
public class HRRequestTriggerHandlerTest {
    
    public static id hrid;
         @testsetup
    Public static void setupdata(){
         //Find a suitable HR department
        /*fHCM2__Team_Member__c ExistingEmployee = [SELECT Id, fHCM2__Department__c FROM fHCM2__Team_Member__c WHERE Basis_formula__c = 'Employee' AND fHCM2__Employment_Status__c = 'Active' LIMIT 1];
        Id HRDept = ExistingEmployee.fHCM2__Department__c;
        
        //Create Team Member records for old and new manager
        fHCM2__Team_Member__c Manager1 = new fHCM2__Team_Member__c(fHCM2__First_Name__c = 'Test', fHCM2__Surname__c = 'Manager1', fHCM2__Department__c = HRDept);
        fHCM2__Team_Member__c Manager2 = new fHCM2__Team_Member__c(fHCM2__First_Name__c = 'Test', fHCM2__Surname__c = 'Manager2', fHCM2__Department__c = HRDept);
        insert Manager1;
        insert Manager2;

        //Create Team Member and Employment under Manager1          
        fHCM2__Team_Member__c tm = new fHCM2__Team_Member__c(fHCM2__First_Name__c = 'Test', fHCM2__Surname__c = 'EmploymentTriggerTest', 
                                    fHCM2__Job_Title__c = 'OldJobTitle', fHCM2__Manager__c = Manager1.Id, fHCM2__Department__c = HRDept);
        insert tm;
        fHCM2__Employment__c e = new fHCM2__Employment__c(fHCM2__Start_Date__c = system.today()-10, fHCM2__Job_Effective_Date__c = system.today()-10, fHCM2__Basis__c = 'Employee',
                                                          Job_Title_Employment__c = 'OldJobTitle', fHCM2__Team_Member__c = tm.Id, Manager_Employment__c = Manager1.Id,
                                                          Funding_Fields_Status__c = 'Online Form Complete',Help_CostCentreText1__c = '220 Programmes Group',Help_ProjectText1__c='Test',
                                                          Help_ActivityText1__c = 'Test', Help_AccountText1__c = '3000 Employee Salary',Help_GrantText1__c = 'BAT001 British Aid Trust - BAT',Funding_Split_1_Percent__c=100);
        insert e;*/

        Id countryUser = [SELECT Id FROM User WHERE UserRoleId!='' AND isActive=true LIMIT 1].Id;      
        Profile p1 = [select id from profile where name='SP_People Group Manager_FSM'];  
        User u1 = new User(alias = 'UserEmp', email='TestUser_TeamMember@testorg.com', 
                           emailencodingkey='UTF-8', lastname='TestUser', languagelocalekey='en_US', 
                           localesidkey='en_US', profileid = p1.Id, 
                           timezonesidkey='America/Los_Angeles', username='TestUser_TeamMember@testorg.com');
        
        Country__c country=new Country__c(Name='TestClassCountry', Region__c='Europe', Country_People_Manager__c=countryUser, Country_Director__c=countryUser);
        insert country;
        
        Account acc = new Account(Name='Test');
            insert acc;
            //CR00000600:Value Changed from Applicant to Job Applicant   
            Contact con = new Contact(Firstname='Test',lastname='user1',email='test@testorg.com',Related_Employee__c=u1.id,Primary_Type__c='Job Applicant');
            insert con;
            
            Talogy_Package__c talogyPackage = new Talogy_Package__c();
            talogyPackage.Name = 'VSO Non Manager';
            talogyPackage.Package_Name__c = 'VSO Non Manager';
            talogyPackage.Accessibility__c ='Logiks & Factors+';
            talogyPackage.Package_Status__c = true;
            insert talogyPackage;
            
            fHCM2__Employment__c er=new fHCM2__Employment__c(Notice_Period_months__c=decimal.valueof('2'),fHCM2__Basis__c='Employee',Funding_Split_1_Percent__c=100);
            insert  er;
            
            fHCM2__Department__c Dept=new fHCM2__Department__c(name='TestDepartment');
            insert Dept;            
            
            fHCM2__Team_Member__c tm=new fHCM2__Team_Member__c(fHCM2__First_Name__c='Test',fHCM2__Surname__c='Member',Recruitment_Partner__c=acc.id,Relationship_Manager__c=u1.id,fHCM2__Department__c=Dept.id,fHCM2__Current_Employment__c=er.id,VSO_Recruit_Contact_Record__c=con.id);
            insert tm;
            
        
        fHCM2__HR_Request__c hr=new fHCM2__HR_Request__c();
        hr.E_Global_VSO_Entity__c='VSO International';
        hr.fHCM2__Effective_Date__c=System.today()-1;
        hr.E_Funding_Split_1_Percent__c=80;
        hr.E_Funding_Split_2_Percent__c=20;
        hr.E_Grant_1__c='AIF001 Aidsfonds - RCF 1';
        hr.E_Global_Grant_2__c='BAT001 British Aid Trust - BAT';
        hr.fHCM2__Employment__c=er.id;
        insert hr;
        
        /* fHCM2__HR_Request__c hr_list=[SELECT Id,E_Global_VSO_Entity__c,E_Funding_Split_1_Percent__c,E_Global_Grant_20__c,E_Funding_Split_20_Percent__c from fHCM2__HR_Request__c where id=:hr.id];
       hr_list.E_Funding_Split_20_Percent__c=100;
        hr_list.E_Global_Grant_20__c='BAT001 British Aid Trust - BAT';
        hr_list.fHCM2__Finalized_Date__c=system.today();
        update hr_list;*/
        
    }
   @IsTest
    public static void TestHR_Request(){
        fHCM2__HR_Request__c hr_list=[SELECT Id,E_Global_VSO_Entity__c,E_Funding_Split_1_Percent__c,E_Global_Grant_20__c,E_Funding_Split_20_Percent__c from fHCM2__HR_Request__c where E_Global_VSO_Entity__c='VSO International' limit 1];
       hr_list.E_Funding_Split_20_Percent__c=5;
         hr_list.E_Funding_Split_1_Percent__c=null;
         hr_list.E_Funding_Split_2_Percent__c=null;
         hr_list.E_Funding_Split_3_Percent__c=null;
         hr_list.E_Funding_Split_4_Percent__c=null;
         hr_list.E_Funding_Split_5_Percent__c=null;
         hr_list.E_Funding_Split_6_Percent__c=null;
         hr_list.E_Funding_Split_7_Percent__c=null;
         hr_list.E_Funding_Split_8_Percent__c=null;
         hr_list.E_Funding_Split_9_Percent__c=null;
         hr_list.E_Funding_Split_10_Percent__c=null;
         hr_list.E_Funding_Split_11_Percent__c=null;
         hr_list.E_Funding_Split_12_Percent__c=null;
         hr_list.E_Funding_Split_13_Percent__c=null;
         hr_list.E_Funding_Split_14_Percent__c=null;
         hr_list.E_Funding_Split_15_Percent__c=null;
         hr_list.E_Funding_Split_16_Percent__c=null;
         hr_list.E_Funding_Split_17_Percent__c=null;
         hr_list.E_Funding_Split_18_Percent__c=null;
         hr_list.E_Funding_Split_19_Percent__c=null;
        hr_list.fHCM2__Finalized_Date__c=system.today();
        update hr_list;
    }
}