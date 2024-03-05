/*
******************************************************************   
Change Log #1:

Modified date:30-Jan-2016
Modified by: Narpavi-TPT
Purpose:Added as a part of Timesheet Phase 2
Search Tag : Narpavi-TPT-Timesheet Phase-(30/Jan/17)

Change Log #2:

Modified date : 17-Apr-2017
Modified by   : Dinesh-TPT
Purpose       : Code changed for the Resourcing CR-Talent Search
Search Tag    : IN00004460 

Change Log #3:

Modified date: 8-June-2017
Modified by: Pawel
Purpose:Code changed on Paul request
Search Tag : IN00005965

Change Log #4:

Modified date : 20-Nov-2017
Modified by   : Dinesh-TPT
Purpose       : Code changed for the CR-41
Search Tag    : CR00000041     

Change Log #5:

Modified date : 29-Nov-2017
Modified by   : Dinesh-TPT
Purpose       : Code changed for the CR-56
Search Tag    : CR00000056  

Change Log #6:

Modified date : 08-Dec-2017
Modified by   : Dinesh-TPT
Purpose       : Code changed for the CR-61   
Search Tag    : CR00000061

Change Log #7:

Modified date : 03-Apr-2018
Modified by   : Dinesh-TPT
Purpose       : Changed the owner of the Team Member record to 'System User',
to remove the access of person who cleared the candidate to start in VSO Recruit.   
Search Tag    : CR00000087     

Change Log #8:

Modified date : 17-01-2023
Modified by   : Pranav
Purpose       : To update all 20 grants related fields and Global Programme related fields\
Method name   : populateFundingRelatedFields
****************************************************************** 
*/ 
public without sharing class FairsailIntegrationHandler
{
    
    Map<Id, fHCM2__Team_Member__c> userToTeamMemberMap;
    Map<String, fHCM2__Department__c> deptNameMap;
    
    // used to test change detection on team member/contact sync
    public List<Id> debugContactIdsChanged;
    
    
    // new bulkified version to be called from a trigger
    public void ProcessOnboardingCompleteFromTrigger()
    {
        
        List<OnboardingCheck__c> scope=trigger.new;
        
        // make a list of the onboardingchecks that have just completed and need to be processed
        List<OnboardingCheck__c> completedOnboarding = new List<OnboardingCheck__c>();
        for(OnboardingCheck__c o:scope)
        {	
            if (o.Helper_Ready_For_Transfer_To_Fairsail__c == true &&
                o.Transferred_to_Fairsail__C == false)
            {
                completedOnboarding.add(o);
            }
        }
        
        if (completedOnboarding.size() > 0)
        {
            
            // onboardingComplete functionality is fired by workflow rule that triggers trigger
            // the way Salesforce executes triggers and rules means that this will be the second
            // time the trigger has fired - we still want RunOnce checking but only once we get this
            // far. Hence this check.
            if (onboardingCompleteRunOnce())
            {
                
                // get further related data needed for processing
                List<OnboardingData> obdList = GetOnboardingDataList(completedOnboarding);
                PrepareUserDepartmentLookups(obdList);
                for(OnboardingData obd:obdList)
                {
                    ProcessOnBoardingCompleteInternal(obd);
                }
            }
            
        }
    }
    
    
    
    // this method processess OnboardingData sets one at a time
    // makes multiple updates/inserts so not fully bulkified yet
    private void ProcessOnBoardingCompleteInternal(OnboardingData od)
    {
        
        // find existing team member or create new one
        fHCM2__Team_Member__c tm = null;
        
        List<fHCM2__Team_Member__c> tmlist = [select id,fHCM2__Employment_Status__c, fHCM2__Current_Employment__c from fHCM2__Team_Member__c where id=:od.Contact.Team_Member__c];
        if (tmlist != null && tmlist.size() > 0)
            tm = tmlist[0];       
        boolean newTeamMember = false;   
        if (tm == null)
        {
            tm = new fHCM2__Team_Member__c();
            newTeamMember = true;
        }
        // make changes
        CopyOnboardingFieldsToTeamMember(tm, od);system.debug('DDD '+newTeamMember);
        // save changes
        if (newTeamMember)
        {
            //CR00000087:To avoid SOQL limit hardcoded the 'System User' record id 
            tm.OwnerId = '005D0000001odRD';            
            insert tm;
            od.Contact.Team_Member__c = tm.Id;
            update od.Contact;
        }
        else
        {
            update tm;
        }
        
        // if no current employment record then make one
        boolean newEmploymentCreated = false;  
        fHCM2__Employment__c e = null;
        fHCM2__Employment__c previousEmpRecord=null;
        List<fHCM2__Employment__c> emplist = [select id,fHCM2__Basis__c,fHCM2__End_Date__c from fHCM2__Employment__c where Id = :tm.fHCM2__Current_Employment__c];
        if (emplist != null && emplist.size() > 0)
        {
            e = emplist[0]; 
            // this is used below instead of 'e' because e might get reassigned when separate sevice is created    
            previousEmpRecord=emplist[0];
        }
        ///Dinesh-TPT- SCS-1309 changes -08/Sep/2015.
        if ((e == null) || (od.OnboardingCheck.Separate_Service_For__c=='Employee')
            ||(od.OnboardingCheck.Separate_Service_For__c=='Other Basis'))
        {
            newEmploymentCreated = true;
            e = new fHCM2__Employment__c();
            e.fHCM2__Team_Member__c = tm.Id;
            CopyOnboardingFieldsToEmployment(e, od, newEmploymentCreated, tm);
            
            //SCS-1309:Populate the Previouse Emp record details
            if(previousEmpRecord!=null)
            {
                e.Previous_Basis__c=previousEmpRecord.fHCM2__Basis__c;
                e.Previous_Actual_End_Date__c=previousEmpRecord.fHCM2__End_Date__c;
            }
            //CR00000087:To avoid SOQL limit hardcoded the 'System User' record id 
            e.OwnerId = '005D0000001odRD';
            //Added by Hassan
            e.Funding_Split_1_Percent__c = 100;
            insert e;
            
            tm.fHCM2__Current_Employment__c = e.Id;            
            update tm;
            
            ///Dinesh-TPT- SCS-1309 changes -09/Sep/2015.
            
            // if sepservice = other and previous emp was volunteer and entitled to HCFA
            if (od.OnboardingCheck.Separate_Service_For__c=='Other Basis' && previousEmpRecord!=null && previousEmpRecord.fHCM2__Basis__c=='Volunteer' && e.fHCM2__Basis__c=='Volunteer' && od.OnboardingCheck.Entitled_to_HCFA__c=='Yes')
            {
                // clone benefits over to new employment?
                createAllowanceRecord(previousEmpRecord,e);
            }
        }
        else
        {
            CopyOnboardingFieldsToEmployment(e, od, newEmploymentCreated, tm);
            update e;
        }
        
        MarkOnboardingAsProcessed(od.OnboardingCheck);
    }
    
    // clone fHCM2__Benefit__c from emp to eid
    public void createAllowanceRecord(fHCM2__Employment__c emp,fHCM2__Employment__c eid)
    {       
        List<fHCM2__Benefit__c> benefitLst= new List<fHCM2__Benefit__c>();
        String SobjectApiName = 'fHCM2__Benefit__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
        
        Set<String> fieldSet = fieldMap.keySet();     
        string allFields='';
        for(String fieldname:fieldSet)
        {
            if(allFields=='')
                allFields=fieldname;
            else
                allFields = allFields+ ',' + fieldname;            
        }
        string id=emp.id;        
        string query='select '+ allFields + ' from fHCM2__Benefit__c WHERE fHCM2__Employment__c=\''+ id +'\'';       
        benefitLst = Database.query(query);
        if(benefitLst.size()>0)
        {
            for(fHCM2__Benefit__c b:benefitLst)
            {
                fHCM2__Benefit__c benefit=b.clone(false, True, false, false);
                benefit.fHCM2__Employment__c=eid.id;
                insert benefit;
            }
        }
        
    }
    
    /*
// this is not used because trigger disabled
public void ProcessContactChanged(Contact c)
{
fHCM2__Team_Member__c tm = [Select Id from fHCM2__Team_Member__c where Id=:c.Team_Member__c];
CopyContactDetailsToTeamMember(tm,c);
update tm;
}
*/
    
    
    
    // callled when team member updated and it has a contact
    //Poornima : Code bulkified for SS-10986082 Fix dated 22/04/2016
    public void ProcessTeamMemberChanged(List<fHCM2__Team_Member__c> tm)
    {
        List<Id> conIds=new List<Id>();
        List<Contact> lstContactToUpdate=new List<Contact>();
        for(fHCM2__Team_Member__c t:tm)
        {
            conIds.add(t.VSO_Recruit_Contact_Record__c);
        }
        // LN 21/12/2015 Changed SObject to a list to handle scenario of no linked contacts
        // In this query we need to include all the fields that might be changed; 
        // otherwise change detection will not work
        Map<Id,Contact> ContactsLinkedToTM = new  Map<Id,Contact>([
            Select Id, FirstName, LastName, HomePhone, MobilePhone, npe01__WorkPhone__c, OtherPhone, Email, npe01__AlternateEmail__c,
            MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,Gender__c,Nationality_1__c,Nationality_2__c,
            OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, Skype_User_Name__c,Prefer_to_self_describe_gender_details__c,
            Vision__c,Sexuality__c,Self_describe_Sexual_Orientation_details__c,Hearing__c,Ethnicity__c,Mobility__c,Ethnicity_Other__c,Cognition__c,
            Religion__c,Self_care__c,Religion_Other__c,Communication__c,npe01__Preferred_Email__c,npe01__PreferredPhone__c from Contact where Id in:conIds]);
        // keep a copy of everything to detect changes later on
        Map<Id,Contact> contactOriginalValues = ContactsLinkedToTM.deepClone();
        // this is for unit testing 
        if (debugContactIdsChanged == null)
            debugContactIdsChanged = new List<Id>();
        //Contact[] ContactsLinkedToTM = [Select Id from Contact where Id=:tm.VSO_Recruit_Contact_Record__c];
        try{
            for(fHCM2__Team_Member__c t1:tm)
            {
                Contact c=ContactsLinkedToTM.get(t1.VSO_Recruit_Contact_Record__c);
                if(c!=null)
                {            
                    CopyTeamMemberToContact(c,t1);
                    Contact originalC = contactOriginalValues.get(t1.VSO_Recruit_Contact_Record__c);
                    // if object does not match original add to update list
                    if (!compareSObjects(originalC,c))
                    {
                        lstContactToUpdate.add(c);
                        // add contactId to debug list somewhere so unit tests can check change detection is working
                        debugContactIdsChanged.add(c.Id);
                    }
                }
            }
            if(lstContactToUpdate.size()>0)
                update lstContactToUpdate;            
            
        }
        Catch(Exception e)
        {
            System.debug('Team Member Error:'+e);
        }
    }
    
    
    /* Compare SObjects attributes; ignore non-existent attributes when new value is null */
    public static boolean compareSobjects(sObject pBeforeSo, sObject pAfterSo) {
        if(pBeforeSo!=pAfterSo) {
            if(pBeforeSo!=null&&pAfterSo!=null) {
                try {
                    map<string, object>beforeMap = (map<string,object>)JSON.deserializeUntyped(JSON.serialize(pBeforeSo));
                    map<string, object>afterMap = (map<string,object>)JSON.deserializeUntyped(JSON.serialize(pAfterSo));
                    system.debug(afterMap);
                    system.debug(beforeMap);
                    for(string key: afterMap.keySet()) {
                        if(beforeMap.containsKey(key))
                        {
                            if (afterMap.get(key)!=beforeMap.get(key))
                            {
                                system.debug('compareSobjects: failed - before/after missmatch for key: '+key);
                                return false;
                            }
                            else
                                system.debug('compareSobjects: field matches: '+key);
                        } else
                        {
                            if (afterMap.get(key)!=null) {
                                system.debug('compareSobjects: failed - after is not null for key: '+key);
                                return false;
                            }
                            else
                                system.debug('compareSobjects: field matches (null in after, missing from before) : '+key);
                        }
                    }
                } catch(Exception e){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'compareSobjects validation error. Please contact a system administrator. Error: '+e.getMessage()));
                    return false;
                }
            } else {
                system.debug('compareSobjects: failed - on or more SObjects were null');
                return false;
            }
        } 
        system.debug('compareSobjects: compare success');
        return true;
    }
    
    // called during ProcessOnBoardingComplete processing
    // no SOQL queries or updates happen in this method, except for in call to GetPrimaryContactSkill
    private void CopyOnboardingFieldsToTeamMember(fHCM2__Team_Member__c tm, OnboardingData od)
    {
        OnboardingCheck__c obc = od.OnboardingCheck;
        Contact c = od.Contact;
        Job__c j = od.Job;
        // set up contact link then call other func to do the fields
        tm.VSO_Recruit_Contact_Record__c = c.Id;
        //        tm.HCM2__Unique_Id__c = tbc;
        CopyContactDetailstoTeamMember(tm,c);
        
        ///Dinesh-TPT- SCS-1309 changes -09/Sep/2015.
        if ((obc.Separate_Service_For__c=='Employee')||(obc.Separate_Service_For__c=='Other Basis'))
        {           
            if(tm.fHCM2__Employment_Status__c=='Alumni')
                tm.fHCM2__Employment_Status__c='Active';            
        }
        
        tm.fHCM2__Job_Effective_Date__c = obc.Confirmed_Start_of_Service_Date__c;
        tm.fHCM2__Job_Title__c = j.Job_Title__c;
        tm.fHCM2__Location__c = j.Primary_Work_Town_City__c;
        
        tm.Partnerships_Programme_Org__c = c.Partnerships_Programme_Org__c;
        
        tm.Recruitment_Partner__c = obc.Recruitment_Partner__c;
        
        tm.Relationship_Manager__c = obc.Relationship_Manager__c;
        tm.Date_of_Last_Criminal_Record_Check__c = obc.Criminal_Background_Clearance_Date__c;
        tm.Date_of_Last_Medical_Check__c = obc.Medical_Clearance_Date__c;
        //Edited:Poornima: Added Nationality (SCS-1372)
        tm.Nationality_1__c=obc.Nationality__c;
        //Poornima(TPT)- SS-7771292 - Dated 27/04/2016 - set enrolled in AXA to true, copy duration from onboarding for policy number calculation
        tm.Enrolled_in_AXA_Medical_Insurance__c=True;
        tm.Duration_Weeks__c=obc.Duration_Weeks__c;
        
        //Narpavi-TPT-(19-Sep-2016): Added for SCR-35
        if(obc.Onboarding_User__c!=null)
        {                         
            tm.fHCM2__User__c=obc.Onboarding_User__c;                  
        }
        
        //Narpavi-TPT(8-N0v-2017): Fixed for IN00010058
        //To Copy Email ID from Contact to Team Menber only for Volunteer
        string jobType = TranslateJobRecordType(j.RecordTypeId);
        if (jobType == 'Volunteer')
            tm.fHCM2__Home_Email__c = c.Email;  
        
        
        tm.Profession__c = GetPrimaryContactSkill( c.Id);
        
        SetTeamMemberManager(tm,od);
        
        SetHRDepartment(tm,od);
        
        
    }
    
    // contains an soql query
    public Id GetPrimaryContactSkill(Id contactId)
    {
        Contact_Skill__c sk = null;
        
        List<Contact_Skill__c> sklist = [select id, Skill__c from Contact_Skill__c where Contact__c=:contactId and Primary_Contact_Skill__c = true];
        if (sklist != null && sklist.size() > 0)
            sk = sklist[0];
        
        if (sk == null)
            return null;
        return sk.Skill__c;
    }
    
    
    // no soql queries within
    private void SetTeamMemberManager(fHCM2__Team_Member__c tm, OnboardingData od)
    {
        if (userToTeamMemberMap == null)
            throw new IntegrationException('PrepareUserDepartmentLookups() should be called before SetTeamMemberManager() to prepare lookup data');
        
        string jobType = TranslateJobRecordType(od.Job.RecordTypeId);
        if (jobType == 'Volunteer')
        {
            // get country people manager
            tm.fHCM2__Manager_User__c = od.Country.Country_People_Manager__c;
        }
        else
        {
            // for other types of jobs, its the hiring manager
            tm.fHCM2__Manager_User__c = od.Job.Hiring_Manager__c;
        }
        
        // if Manager_User__c is set then find corresponding Team Member record
        if (tm.fHCM2__Manager_User__c != null)
        {
          if(jobType == 'Volunteer')
          {
              fHCM2__Team_Member__c volunteerManager = userToTeamMemberMap.get(od.Job.Hiring_Manager__c);
              system.debug(volunteerManager);
              if(volunteerManager!=null)
              {
                 tm.fHCM2__Manager__c = volunteerManager.id;
              }
          }
          else
           {
            fHCM2__Team_Member__c manager = userToTeamMemberMap.get(tm.fHCM2__Manager_User__c);
            system.debug(userToTeamMemberMap);
            system.debug(manager);
            if (manager!=null)                 
                tm.fHCM2__Manager__c = manager.Id;
           }
        }
        
    }
    
    // reduce number of SOQL queries by doing all the country/artment fetching now 
    private void PrepareUserDepartmentLookups(List<OnboardingData> odList)
    {
        
        List<Id> userIds = new List<Id>();
        List<String> hrDeptNames = new List<String>();
        for(OnboardingData od:odList)
        {
            userIds.add(od.Country.Country_People_Manager__c);
            userIds.add(od.Job.Hiring_Manager__c);
            
            hrDeptNames.add(od.OnboardingCheck.VSO_People_HR_Department__c);
        }
        
        // get the team members that correspond to the users
        system.debug(userIds);
        List<fHCM2__Team_Member__c> managerTms = [select id, fHCM2__User__c from fHCM2__Team_Member__c where fHCM2__User__c = :userIds];
        userToTeamMemberMap = new Map<Id, fHCM2__Team_Member__c>();
        system.debug(managerTms);
        for(fHCM2__Team_Member__c tm : managerTms)
            userToTeamMemberMap.put(tm.fHCM2__User__c, tm);
        
        List<fHCM2__Department__c> deptList = [select id, name from fHCM2__Department__c where name=:hrDeptNames];
        deptNameMap = new Map<String, fHCM2__Department__c>();
        for(fHCM2__Department__c d: deptList)
            deptNameMap.put(d.name, d);
        
    }
    
    // no soql queries within
    private void SetHRDepartment(fHCM2__Team_Member__c tm, OnboardingData od)
    {
        if (deptNameMap == null)
            throw new IntegrationException('PrepareUserDepartmentLookups() should be called before SetHRDepartment() to prepare lookup data');
        
        string hrText = od.OnboardingCheck.VSO_People_HR_Department__c;
        fHCM2__Department__c deptMatch = deptNameMap.get(hrText);
        if (deptMatch == null)
        {
            string onbref = od.OnboardingCheck.name;
            throw new IntegrationException('Could not find an HR Department record with name "' + hrText + '" (OnBoardingCheck ' + onbref + ')');            
        }
        tm.fHCM2__Department__c = deptMatch.Id;
        
    }
    
    // called during ProcessOnBoardingComplete processing
    // nb: no queries or updates issued within
    // Pranav TPT : CR00053761 - Added extra fields to copy data from contact to teammember
    private void CopyContactDetailsToTeamMember(fHCM2__Team_Member__c tm, Contact c)
    {
        tm.fHCM2__First_Name__c = c.FirstName;
        tm.fHCM2__Surname__c  = c.LastName;
        tm.fHCM2__Birth_Date__c=c.Birthdate;
        tm.fHCM2__Home_Phone__c = c.HomePhone;
        
        tm.fHCM2__Personal_Mobile__c = c.MobilePhone; 
        //        Removed work phone from details copied over, as this won't be accurate for vols or employees (LN 26/9/14)
        //        tm.Work_Phone__c = c.npe01__WorkPhone__c; 
        tm.Other_Phone__c = c.OtherPhone;
        
        tm.fHCM2__Home_Email__c=c.npe01__HomeEmail__c;
        tm.fHCM2__Email__c=c.npe01__WorkEmail__c;
        tm.Alternate_Email__c = c.npe01__AlternateEmail__c;
        
        tm.fHCM2__Home_Address_1__c = c.MailingStreet;
        tm.fHCM2__Home_Address_City__c = c.MailingCity;
        tm.fHCM2__Home_Address_Region__c = c.MailingState;       
        tm.fHCM2__Home_Address_Postal_Code__c = c.MailingPostalCode;      
        tm.fHCM2__Home_Address_Country__c = c.MailingCountry;
        tm.Secondary_Address_1__c = c.OtherStreet;
        tm.Secondary_Address_City__c = c.OtherCity;
        tm.Secondary_Address_Region__c = c.OtherState;
        tm.Secondary_Address_Postal_Code_Zip_Code__c = c.OtherPostalCode;
        tm.Secondary_Address_Country__c = c.OtherCountry;
        tm.Skype_Username__c = c.Skype_User_Name__c;
        tm.fHCM2__Gender__c = c.Gender__c;
        tm.Nationality_1__c = c.Nationality_1__c;
        tm.Nationality_2__c = c.Nationality_2__c;
        tm.Prefer_to_self_describe_gender_details__c = c.Prefer_to_self_describe_gender_details__c;
        tm.Vision__c = c.Vision__c;
        tm.Sexuality__c = c.Sexuality__c;
        tm.Self_describe_Sexual_Orientation_details__c = c.Self_describe_Sexual_Orientation_details__c;
        tm.Hearing__c = c.Hearing__c;
        tm.Ethnicity__c = c.Ethnicity__c;
        tm.MobilityVSO__c = c.Mobility__c;
        tm.Ethnicity_Other__c = c.Ethnicity_Other__c;
        tm.Cognition__c = c.Cognition__c;
        tm.Religion__c = c.Religion__c;
        tm.Self_care__c = c.Self_care__c;
        tm.Religion_Other__c = c.Religion_Other__c;
        tm.Communication__c = c.Communication__c;
        tm.Preferred_Email__c=c.npe01__Preferred_Email__c;
        tm.Preferred_Phone__c=c.npe01__PreferredPhone__c;
        
    }
    
    //Dinesh-TPT-Recruit V2 Changes-10/June/2015
    //Method changed due to Skill and Job object relationship is changed to Lookup relationship.
    // nb: includes an SOQL query to get dept details
    private void CopyOnboardingFieldsToEmployment(fHCM2__Employment__c e, OnboardingData od,
                                                  boolean newEmploymentCreated, fHCM2__Team_Member__c relatedTm)
    {
        OnboardingCheck__c obc = od.OnboardingCheck;
        Job__c j = od.Job;
        Application__c app=od.Application;
        //TPT Amended: for SCS-1527
        Account a=od.account;
        system.debug(a);
        string jobType = TranslateJobRecordType(j.RecordTypeId);
        
        //Dinesh-TPT- SCS-1309 changes -08/Sep/2015.
        if ((obc.Separate_Service_For__c=='Employee')||(obc.Separate_Service_For__c=='Other Basis'))
        {
            if(obc.Previous_Role_Break_Less_6_Months__c)
            {
                //CR00000056:Commented the below code for this CR 
                /*e.IT_Induction_Complete__c='N/A';
e.Anti_Corruption_Training_Complete__c='N/A';
e.Welcome_to_VSO_Course_Complete__c='N/A';                      
e.Global_Webinar_Complete__c='N/A';*/
                e.Help_Previous_Role_Less_6Months__c='LesserSixMonths';
            }        
            if(obc.Previous_Role_Break_Greater_6_Months__c)
                e.Help_Previous_Role_Greater_6Months__c='GreaterSixMonths';
        }
        else
        {
            e.fHCM2__Job_Effective_Date__c=obc.Confirmed_Start_of_Service_Date__c;
            if(e.fHCM2__End_Date__c !=null)
                e.fHCM2__End_Date__c=null;
        }
        
        if (newEmploymentCreated) {
            e.fHCM2__Trigger_Action_Email__c = 'Start';
            e.fHCM2__Start_Date__c = obc.Confirmed_Start_of_Service_Date__c;
            e.Previous_Engagement__c=obc.Previous_Engagement__c;
        }
        
        else {
            e.fHCM2__Trigger_Action_Email__c = 'Change';
            e.IsCreateNewSalary__c=true;
        }
        
        e.fHCM2__Job_Effective_Date__c = obc.Confirmed_Start_of_Service_Date__c;
        e.Start_Date_in_Position__c = obc.Confirmed_Start_of_Service_Date__c;
        
        e.On_Boarding_Record__c = obc.Id;
        if (obc.Proposed_End_Date__c != null && obc.Proposed_Start_Date__c != null)
            e.Duration_from_On_Boarding_Check__c = obc.Proposed_Start_Date__c.daysBetween(obc.Proposed_End_Date__c);
        else
            e.Duration_from_On_Boarding_Check__c = null;
        // set basis based on job record type etc
        e.fHCM2__Basis__c = jobType;
        // but override for volunteering within vso
        //IN00004460:Renamed the 'Volunteer Type' value from ‘Volunteering Within VSO’ To ‘Voluntary Workforce’ 
        //CR -123 : Modified to set the basis as 'Volunteer Workforce' for the Volunteer Type is Volunteer Workforce       
        if (j.Volunteer_Type__c == 'Voluntary Workforce')   
            e.fHCM2__Basis__c = 'Voluntary Workforce';
        
        
        if (jobType == 'Volunteer')
            e.Contract_Type__c = 'Volunteer Agreement';            
        else
            e.Contract_Type__c = j.Contract_Type__c;
        //CR-51- Narpavi-TPT-(14-Nov-2017)
        //Changed the fields as new global picklist created  
        e.Global_VSO_Entity__c = j.VSO_Entity__c;
        e.Global_Function__c = j.Group_Federation__c;
        e.Global_Department__c = j.Department__c;
        //CR00000041:Code changed for this CR    
        //e.Country__c =  j.Country__c;
        e.Country__c=od.onbJobCountryId;
        //Narpavi-TPT-Timesheet Phase-(30/Jan/17)
        //Added to auto populate the fields from job to employment record
        e.Global_Account_Code__c = od.Job.Global_Account_Code__c;
        e.Cost_Centre__c = od.Job.Global_Cost_Centre__c;
        
        //Narpavi-TPT-Salary Changes-(16/3/15)
        //Removed:Hours worked and FTE populating from the job record
        //e.fHCM2__Hours_Worked__c = j.Working_Hours_Per_Week__c;
        //e.fHCM2__FTE__c = j.Full_Time_Equivalent__c;
        //CR00000061:Code changed for this CR-61
        //e.Contract_Terms__c = j.Contract_Terms__c;
        if(obc.Contract_Terms_Picklist__c!=null && obc.Contract_Terms_Picklist__c!=''){
            e.Contract_Terms__c=obc.Contract_Terms_Picklist__c;
        }
        
        //Dinesh-TPT-KE Phase-2 Changes-20/July/2015
        //Condition to check whether the onboarding record is KE onboard record or not and then set the fields.
        if(obc.Knowledge_Exchange_Volunteer_Onboard__c)
        {
            e.Volunteer_Type__c = 'Knowledge Exchange';
            e.Knowledge_Exchange_Employment_Record__c=true;
            e.Corporate_Partner__c=app.Applicant__r.Corporate_Partner__c;
            e.Corporate_Id__c=app.Applicant__r.Corporate_Partner__r.Organization_Id__c;
            e.Flights_to_be_invoiced_Y_N_del__c=j.Knowledge_Exchange_Partner__r.Flights_to_be_invoiced_Y_N__c;
            e.Development_Partner__c=j.Development_Partner__c;
            e.Development_Partner_Id__c=j.Development_Partner__r.Organization_Id__c;
            e.Application_Id__c=app.Name;  
            e.Placement_Type_Group_Individual__c='Knowledge Exchange Individual';  
            e.Funded_Placement__c='No';        
        }
        else
        {
            e.Volunteer_Type__c = j.Volunteer_Type__c;
        }
        //e.Enrolled_in_AXA_Medical_Insurance_Scheme__c = tbc;
        e.fHCM2__Contract_End_Date__c = obc.Proposed_End_Date__c;
        e.Original_Planned_End_Date__c = obc.Proposed_End_Date__c;
        
        if (newEmploymentCreated)
            e.Probation_Status__c = 'Pending';
        
        if (jobType == 'Volunteer')
        {
            
            e.Employer__c = j.Employer__c;
            //CR00000041:Code changed for this CR
            //e.In_Country_Payroll_Office__c =  j.Country__c;
            e.In_Country_Payroll_Office__c=od.onbJobCountryId;
            //e.Home_Country_Payroll_Office__c = tbc;
            //2014-11-19 : CSL : We need to make sure the 'Entitled To HCFA' value is copied during updates
            // SCS-1641 but only for volunteers!
            e.Entitled_to_HCFA__c = obc.Entitled_to_HCFA__c;
            
            //TPT Amended: for SCS-1527            
            //e.Home_Country_Payroll_Office__c=a.country__c; //Comment By Raghu for SS-1223749
            //system.debug('Country' + a.country__c);
            e.Home_Country_Payroll_Office__c = od.offer.Payroll_Office_processing_location__c;// Added By raghu for SS-1223749          
        }
        if (jobType == 'Employee')
        {
            //Edited By Poornima - Commented the line populating payroll office - for SCS-1597
            //e.Employee_Payroll_Office__c = j.Country__c;
            e.Role_Type__c = 'Substantive';            
            //Start of change by Raghu
            // Add Payroll Office to Employment Record.
            e.Employee_Payroll_Office__c = od.offer.Payroll_Office_processing_location__c;
            //End of change by Raghu
            
            //Narpavi-TPT-SCS-1309-Change-30Sep2015 
            //populate the field in the employement record to check the continuing Service or Separate Service for employee          
            e.Is_Continuing_Employee_Service__c=obc.Separate_Service_For__c;  
            
            //Narpavi TPT- CR:75 added the below field
            VSO_Settings__c vso=VSO_Settings__c.getInstance();   
            e.fta__Timesheet_Pattern__c = vso.Timesheet_Pattern_ID__c;
            
            //Narpavi TPT-Empolyee Offer and Onboarding-(13-Nov-2015) 
            //Populate the probation end date in employment record from Onboarding  
            if(od.Offer.Probation_Period__c !=null) 
            {          
                if(od.Offer.Probation_Period__c=='1 month')
                {
                    od.thedate= obc.Confirmed_Start_of_Service_Date__c.addMonths(1);                   
                }
                
                if(od.Offer.Probation_Period__c=='3 months')
                {
                    od.thedate =obc.Confirmed_Start_of_Service_Date__c.addMonths(3);
                }
                
                if(od.Offer.Probation_Period__c=='6 months' )                 
                {
                    od.thedate = obc.Confirmed_Start_of_Service_Date__c.addMonths(6);
                }
                
                if(od.thedate !=null)
                {
                    //Find the day of the week and populate probation peiod               
                    Datetime dt = DateTime.newInstance(od.thedate, Time.newInstance(0, 0, 0, 0));
                    String dayOfWeek=dt.format('EEEE');                 
                    
                    if((dayOfWeek !='Saturday')||(dayOfWeek !='Sunday')) 
                    {
                        e.fHCM2__Probation_End_Date__c=od.thedate;    
                    }   
                    if(dayOfWeek =='Saturday')
                    {
                        e.fHCM2__Probation_End_Date__c=od.thedate-1;
                    }
                    if(dayOfWeek =='Sunday')
                    {
                        e.fHCM2__Probation_End_Date__c=od.thedate-2;
                    }
                }
            }            
        }  
        
        //e.Accompanied_Post__c = tbc;
        //e.fHCM2__Salary_Band__c = tbc;
        
        e.Senior_Approver_for_Budget__c = j.Senior_Approver__c;
        
        
        e.Primary_Job_Skill__c = j.Primary_Skill__c;
        
        e.Programme_Manager__c = j.Hiring_Manager__c;
        //If Consultant: Fee Payable Currency = tbc;
        //If Consultant: Fee Payable= tbc;
        //If Consultant: Payment Frequency= tbc;
        
        e.VSO_Recruit_Job_Record__c = j.Id;
        e.VSO_Recruit_Job_Id__c = j.Job_Id__c;
        
        // copy tm fields (SCS-1119)
        e.Manager_Employment__c = relatedTm.fHCM2__Manager__c;
        e.Job_Title_Employment__c = relatedTm.fHCM2__Job_Title__c;
        
        //CR-51-Narpavi-TPT-(14-Nov-2017)
        //Changed the fields as new global picklist created 
        e.VSO_Entity_portal__c = e.Global_VSO_Entity__c;
        e.Group_Federation_portal__c = e.Global_Function__c;
        e.Department_portal__c = e.Global_Department__c;
        e.Country_Name_Portal__c = od.Country.name;
        
        // SCS-1442
        e.Confirm_Changes_Effective_From__c = true;
        
        // SCS-1123
        if (od.Offer != null)
        {        
            e.Notice_Period__c = od.Offer.Notice_Period__c;
            e.Notice_Period_During_Probation_Weeks__c = od.Offer.Notice_Period_During_Probation_Weeks__c;
            
            //Narpavi-TPT-SCS-1122-(13/5/15)
            //Populate the pay band in employment record from offer 
            if(od.Offer.RecordType.DeveloperName =='Employee_Offer')
            {                 
                if(od.Offer.Pay_Band__c!=null)
                {
                    e.fHCM2__Salary_Band__c=od.Offer.Pay_Band__c;
                }               
                //Narpavi TPT-Empolyee Offer and Onboarding-(13-Nov-2015) 
                //Populate the probation Period in employment record from Offer 
                e.Probation_Period__c=od.Offer.Probation_Period__c;                
                
                
                //Poornima-TPT-Salary Changes-(16/3/15)
                //Update Employment Record fields from Offer and Policy             
                e.Full_Time_Part_Time__c=od.Offer.Full_Time_Part_Time__c;                               
                if(od.Offer.Full_Time_Part_Time__c =='Full Time')
                { 
                    List<fHCM2__Department__c> dept = [select id, name,fHCM2__Policy__r.fHCM2__Hours_Per_Week__c from fHCM2__Department__c where id=:relatedTm.fHCM2__Department__c];
                    if (dept != null && dept.size() > 0)
                    {
                        e.fHCM2__Hours_Worked__c =dept[0].fHCM2__Policy__r.fHCM2__Hours_Per_Week__c ;
                    }                   
                }
                else 
                {
                    e.fHCM2__Hours_Worked__c = od.Offer.Working_Hours_Per_Week__c;
                } 
            } 
        }
        
        // SCS-1125 transfer position funding codes
        
        // project will likely only have been chosen for volunteer jobs
        if (od.VSOProject != null)
            e.Project_1__c = od.VSOProject.Legacy_Project_Code__c;
        
        // code fields on Job__c will only have been filled in for employee jobs
        //e.Account_1__c = od.Job.Account_Code__c;
        e.Activity_1__c = od.Job.Activity_Code__c;
        //e.Cost_Centre_1__c = od.Job.Cost_Centre__c;
        //GPAPA IT-2 #12 changes: Commented the below code on 25-Apr-2021
        //e.Theme_1__c = TranslateTheme(od.Job.Theme__c);
       
        
         // Pranav : Added this condition to copy the mode of delivery field from job to employment for volunteer type job
        if(j.Type__c.contains('Volunteer'))
        {
            if(j.Mode_Of_Delivery__c!=null)
            {
               e.Mode_Of_Delivery__c=j.Mode_Of_Delivery__c;
            }
            
        }
       
        
        populateFundingRelatedFields(e,od);
        
    }   
    
    /**
* Created By: Dinesh Sivalingam
* Created On: 19-Jun-2021
* Description: GPAPA IT-2: Method to populate Grant related fields and Global Programme related fields
* */
    
/* modified by : Pranav
modified on : 27-12-2022
purpose: To update all 20 grants related fields and Global Programme related fields*/
    
    // Pranav : refactored the code 
    private void populateFundingRelatedFields(fHCM2__Employment__c e, OnboardingData od){
        
        string coreProgrammeArea='Core_Programme_Area__c';
        for(integer i=1;i<21;i++){
            String jobGrant = 'Grant_'+i+'__c';
            String Grant = 'Global_Grant_'+i+'__c';
            String globalProgramme='Global_Programme_'+i+'__c';
            String practiceAreaName='Practice_Area_Name_'+i+'__c';
            string practiceAreaCode='Practice_Area_Code_'+i+'__c';
            String fundingSplitPercentage ='Funding_Split_'+i+'_Percent__c';
            String jobFundingpropotion='Funding_Proportion_'+i+'__c';
            
            if(i==1)
            {
                e.put(jobGrant,od.job.get(jobGrant));
                e.put(globalProgramme,od.job.get(globalProgramme));
                e.put(practiceAreaName,od.job.get(practiceAreaName));
                e.put(practiceAreaCode,od.job.get(coreProgrammeArea));
                e.put(fundingSplitPercentage,od.job.get(jobFundingpropotion));
            }
            else
            {
               e.put(Grant,od.job.get(jobGrant));
                e.put(globalProgramme,od.job.get(globalProgramme));
                e.put(practiceAreaName,od.job.get(practiceAreaName));
                e.put(practiceAreaCode,od.job.get(practiceAreaCode));
                e.put(fundingSplitPercentage,od.job.get(jobFundingpropotion)); 
            }
            
        }
    }
    
    // Pranav TPT : CR00053761 - Changed the method to copy teammember to contact
    private void CopyTeamMemberToContact(Contact c, fHCM2__Team_Member__c tm)
    {
       Map<string,string> fieldMap = new map<string,string>();
       fHCM2__Team_Member__c oldRecord =(fHCM2__Team_Member__c)trigger.oldMap.get(tm.id);
        fieldMap.put('fHCM2__First_Name__c','FirstName');
        fieldMap.put('fHCM2__Surname__c','LastName');
        fieldMap.put('fHCM2__Birth_Date__c','Birthdate');
        fieldMap.put('fHCM2__Home_Phone__c','HomePhone');
        fieldMap.put('fHCM2__Personal_Mobile__c','MobilePhone');
        fieldMap.put('Other_Phone__c','OtherPhone');
        fieldMap.put('fHCM2__Home_Email__c','npe01__HomeEmail__c');
        fieldMap.put('fHCM2__Email__c','npe01__WorkEmail__c');
        fieldMap.put('Alternate_Email__c','npe01__AlternateEmail__c');
        fieldMap.put('fHCM2__Home_Address_1__c','MailingStreet');
        fieldMap.put('fHCM2__Home_Address_City__c','MailingCity');
        fieldMap.put('fHCM2__Home_Address_Region__c','MailingState');
        fieldMap.put('fHCM2__Home_Address_Postal_Code__c','MailingPostalCode');
        fieldMap.put('fHCM2__Home_Address_Country__c','MailingCountry');
        fieldMap.put('Secondary_Address_1__c','OtherStreet');
        fieldMap.put('Secondary_Address_City__c','OtherCity');
        fieldMap.put('Secondary_Address_Region__c','OtherState');
        fieldMap.put('Secondary_Address_Postal_Code_Zip_Code__c','OtherPostalCode');
        fieldMap.put('Secondary_Address_Country__c','OtherCountry');
        fieldMap.put('Skype_Username__c','Skype_User_Name__c');
        fieldMap.put('fHCM2__Gender__c','Gender__c');
        fieldMap.put('Nationality_1__c','Nationality_1__c');
        fieldMap.put('Nationality_2__c','Nationality_2__c');
        fieldMap.put('Prefer_to_self_describe_gender_details__c','Prefer_to_self_describe_gender_details__c');
        fieldMap.put('Vision__c','Vision__c');
        fieldMap.put('Sexuality__c','Sexuality__c');
        fieldMap.put('Self_describe_Sexual_Orientation_details__c','Self_describe_Sexual_Orientation_details__c');
        fieldMap.put('Hearing__c','Hearing__c');
        fieldMap.put('Ethnicity__c','Ethnicity__c');
        fieldMap.put('MobilityVSO__c','Mobility__c');
        fieldMap.put('Ethnicity_Other__c','Ethnicity_Other__c');
        fieldMap.put('Cognition__c','Cognition__c');
        fieldMap.put('Religion__c','Religion__c');
        fieldMap.put('Self_care__c','Self_care__c');
        fieldMap.put('Religion_Other__c','Religion_Other__c');
        fieldMap.put('Communication__c','Communication__c');
        fieldMap.put('Preferred_Email__c','npe01__Preferred_Email__c');
        fieldMap.put('Preferred_Phone__c','npe01__PreferredPhone__c');
        
        for(string fields : fieldMap.keyset())
        {
           if(tm.get(fields)!=oldRecord.get(fields) && tm.get(fields)!=null)
           {
               c.put(fieldMap.get(fields),tm.get(fields));
           }
        }
    }
    
    // fetches record type info, counts as a query? could be cached.
    private string TranslateJobRecordType(ID recordTypeId)
    {
        Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Job__c.getRecordTypeInfosById();
        string typeName = rtMap.get(recordTypeId).getName();
        
        if (typeName.startsWith('Employee Job'))
            return 'Employee';
        if (typeName.startsWith('Volunteer Job'))
            return 'Volunteer';
        if (typeName.startsWith('Consultant Job'))
            return 'Consultant';
        //Dinesh-TPT-KE Phase-2 Changes-20/July/2015
        //Return the job type as 'Volunteer' for 'Corporate Job'
        if (typeName.startsWith('Corporate Job'))
            return 'Volunteer';
        
        throw new IntegrationException('Unknown Job RecordType ' + typeName + ' encountered');
    }
    //GPAPA IT-2 #12 changes: Commented the below method on 25-Apr-2021
    // translates Theme as used on Job__c to Theme as used on fHCM2__Employment__c
    /*public string TranslateTheme(string jobTheme)
{
// hard coded mapping, will have to do for now
Map<String,String> themeMap = new Map<String,String>();
themeMap.put('Climate Change','C01 CLIMATE CHANGE');
themeMap.put('Disability','Disability');
themeMap.put('Education','E01 EDUCATION');
themeMap.put('Gender Equality','Gender Equality');
themeMap.put('Health/HIV','H01 HEALTH');
themeMap.put('Participation and Governance','G01 GOVERNANCE');
themeMap.put('Secure Livelihoods','L01 SECURE LIVELIHOODS');
themeMap.put('Youth','Youth');
themeMap.put('N/A – Volunteering Within VSO','# NOT GOAL RELATED');
//IN00004460:Auot populate the fields based on the Themes from Job Record
themeMap.put('Health','H01 HEALTH');
themeMap.put('National Volunteering','N01 NATIONAL VOLUNTEERING');            
themeMap.put('Other Innovations','I01 OTHER INNOVATION');

string employmentTheme = themeMap.get(jobTheme);

if (employmentTheme == null)
employmentTheme = jobTheme;

return employmentTheme;

}*/
    
    private void MarkOnboardingAsProcessed(OnboardingCheck__c obc)
    {
        
        obc.Transferred_to_Fairsail__c = true;
        // can't call update because obc object was passed in from trigger
    }
    
    public List<OnboardingData> GetOnboardingDataList(List<OnboardingCheck__c> obcList)
    {
        // need various IDs in lists/sets in order to do other queries: 
        List<Id> recPartnerIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        List<Id> applicationIds = new List<Id>();
        for(OnboardingCheck__c o:obcList)
        {
            contactIds.add(o.Contact__c);
            applicationIds.add(o.Application__c);
            // may end up with dupes in this list but doesn't matter
            recPartnerIds.add(o.Recruitment_Partner__c);           
        }
        Map<Id, Account> recPartnerMap = new Map<Id, Account>(
            [select id,Country__c from Account where id=:recPartnerIds]
        );
        Map<Id, Contact> contactMap = new Map<Id, Contact>(
            [select id, FirstName, LastName, HomePhone, MobilePhone, npe01__WorkPhone__c, OtherPhone,Birthdate,Gender__c,
             Email, npe01__AlternateEmail__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
             OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, Skype_User_Name__c,Nationality_1__c,Nationality_2__c,
             Prefer_to_self_describe_gender_details__c,Vision__c,Sexuality__c,Self_describe_Sexual_Orientation_details__c,
             Hearing__c,Ethnicity__c,Mobility__c,Ethnicity_Other__c,Cognition__c,Religion__c,Self_care__c,Religion_Other__c,
             Partnerships_Programme_Org__c, Primary_Skill__c, Team_Member__c,Communication__c,npe01__Preferred_Email__c,npe01__HomeEmail__c,npe01__WorkEmail__c,npe01__PreferredPhone__c
             from Contact where Id = :contactIds ]);
        Map<Id, Application__c> applicationMap = new Map<Id, Application__c>(
            [select id,Name,Job__c,Applicant__r.Corporate_Partner__c,Applicant__r.Corporate_Partner__r.Organization_Id__c 
             from Application__c where Id = :applicationIds ]);
        // TODO what if more than one offer per app?       
        //Narpavi-TPT-SS-14980813-(4-Aug-16)-Fixed to populate the fields from Offer to Employment
        Map<Id, Offer__c> offerMap = new Map<Id, Offer__c>();         
        List<Offer__c> lstoffer=[select id, name,Application__c, CreatedDate, Notice_Period__c,Pay_Band__c,Probation_Period__c,Notice_Period_During_Probation_weeks__c,Full_Time_Part_Time__c,Working_Hours_Per_Week__c,Payroll_Office_processing_location__c,RecordType.DeveloperName 
                                 from Offer__c where Application__c=:applicationIds Order by CreatedDate];
        for(Offer__c ofr:lstoffer)
        {
            offerMap.put(ofr.Application__c,ofr);
        }    
        
        // get jobIds from Application
        // modified the query related to grant 20 CR ( Modified by Pranav )
        List<Id> jobIds = new List<Id>();
        for(Application__c a:applicationMap.values())
        {
            jobIds.add(a.Job__c);     
        }
        Map<Id, Job__c> jobMap = new Map<Id, Job__c>(
            [select id, Job_Id__c, Job_Title__c, Primary_Work_Town_City__c, RecordTypeId, Volunteer_Type__c, Volunteering_Within_VSO_Sub_Type__c, Contract_Type__c,
             VSO_Entity__c, Group_Federation__c, Department__c, Country__c, Working_Hours_Per_Week__c, Full_Time_Equivalent__c,
             Employer__c, Senior_Approver__c, Primary_Skill__c, Hiring_Manager__c,Type__c,Mode_Of_Delivery__c,
             Global_Account_Code__c, Activity_Code__c, Global_Cost_Centre__c,Knowledge_Exchange_Partner__c,Development_Partner__c,Knowledge_Exchange_Partner__r.Organization_Id__c,
             Development_Partner__r.Organization_Id__c,Knowledge_Exchange_Partner__r.Flights_to_be_invoiced_Y_N__c,
             Grant_1__c,Global_Programme_1__c,Core_Programme_Area__c,Practice_Area_Name_1__c,Funding_Proportion_1__c,
             Grant_2__c,Global_Programme_2__c,Practice_Area_Code_2__c,Practice_Area_Name_2__c,Funding_Proportion_2__c,
             Grant_3__c,Global_Programme_3__c,Practice_Area_Code_3__c,Practice_Area_Name_3__c,Funding_Proportion_3__c,
             Grant_4__c,Global_Programme_4__c,Practice_Area_Code_4__c,Practice_Area_Name_4__c,Funding_Proportion_4__c,
             Grant_5__c,Global_Programme_5__c,Practice_Area_Code_5__c,Practice_Area_Name_5__c,Funding_Proportion_5__c,
             Grant_6__c,Global_Programme_6__c,Practice_Area_Code_6__c,Practice_Area_Name_6__c,Funding_Proportion_6__c,
             Grant_7__c,Global_Programme_7__c,Practice_Area_Code_7__c,Practice_Area_Name_7__c,Funding_Proportion_7__c,
             Grant_8__c,Global_Programme_8__c,Practice_Area_Code_8__c,Practice_Area_Name_8__c,Funding_Proportion_8__c,
             Grant_9__c,Global_Programme_9__c,Practice_Area_Code_9__c,Practice_Area_Name_9__c,Funding_Proportion_9__c,
             Grant_10__c,Global_Programme_10__c,Practice_Area_Code_10__c,Practice_Area_Name_10__c,Funding_Proportion_10__c,
             Grant_11__c,Global_Programme_11__c,Practice_Area_Code_11__c,Practice_Area_Name_11__c,Funding_Proportion_11__c,
             Grant_12__c,Global_Programme_12__c,Practice_Area_Code_12__c,Practice_Area_Name_12__c,Funding_Proportion_12__c,
             Grant_13__c,Global_Programme_13__c,Practice_Area_Code_13__c,Practice_Area_Name_13__c,Funding_Proportion_13__c,
             Grant_14__c,Global_Programme_14__c,Practice_Area_Code_14__c,Practice_Area_Name_14__c,Funding_Proportion_14__c,
             Grant_15__c,Global_Programme_15__c,Practice_Area_Code_15__c,Practice_Area_Name_15__c,Funding_Proportion_15__c,
             Grant_16__c,Global_Programme_16__c,Practice_Area_Code_16__c,Practice_Area_Name_16__c,Funding_Proportion_16__c,
             Grant_17__c,Global_Programme_17__c,Practice_Area_Code_17__c,Practice_Area_Name_17__c,Funding_Proportion_17__c,
             Grant_18__c,Global_Programme_18__c,Practice_Area_Code_18__c,Practice_Area_Name_18__c,Funding_Proportion_18__c,
             Grant_19__c,Global_Programme_19__c,Practice_Area_Code_19__c,Practice_Area_Name_19__c,Funding_Proportion_19__c,
             Grant_20__c,Global_Programme_20__c,Practice_Area_Code_20__c,Practice_Area_Name_20__c,Funding_Proportion_20__c
             from Job__c where Id=:jobIds]);
        //CR00000041:Code Commented for this CR                
        // get country ids from job        
        /*List<Id> countryIds = new List<Id>();
for(Job__c j:jobMap.values())
{
countryIds.add(j.Country__c);
}*/
        //CR00000041:Code changed for this CR
        Map<Id, Country__c> countryMap = new Map<Id, Country__c>(
            [select id, name, Country_People_Manager__c from Country__c ]); // where Id=:countryIds]);                      
        
        Map<Id, VSO_Project__c> jobProjectMap = GetJobProjectMap(jobIds);
        
        
        
        // we now have all the data in maps
        // knit it together into a list of OnboardingData objects
        List<OnboardingData> retList = new List<OnboardingData>();
        for(OnboardingCheck__c o:obcList)
        {
            OnboardingData odb = new OnboardingData();
            odb.OnboardingCheck = o;
            odb.Contact = contactMap.get(o.Contact__c);
            odb.Application = applicationMap.get(o.Application__c);
            odb.Job = jobMap.get(odb.Application.Job__c);
            odb.Country = countryMap.get(odb.Job.Country__c);
            // get most recent offer for application         
            odb.Offer = offerMap.get(o.Application__c);
            // get Project
            odb.VSOProject = jobProjectMap.get(odb.Job.Id);
            odb.RecPartner = recPartnerMap.get(o.Recruitment_Partner__c);       
            //CR00000041:Code changed for this CR
            if(o.JobCountry__c!=null && o.JobCountry__c!='')
            {
                for(Country__c c:countryMap.values()){
                    if(c.Name==o.JobCountry__c)
                        odb.onbJobCountryId=string.valueOf(c.id);
                }
            }
            retList.add(odb);
        }
        return retList;
    }
    
    // given a list of jobIds, returns a map linking jobId to a VSO_Project__c record.
    // where a job is associated with multiple projects, returns the most recent link
    private Map<Id, VSO_Project__c> GetJobProjectMap(List<Id> jobIds)
    {
        // get the job-project link records
        // ordering by name means newest are last
        List<VSO_Project_Job__c> projectJobLinks = new List<VSO_Project_Job__c>(
            [select id, job__c, vso_project__c, Name
             from VSO_Project_Job__c where Job__c = :jobIds Order by Name]);
        
        // select latest project id for each job id and keep in a map
        Map<Id, Id> jobProjectIdMap = new Map<Id, Id>();    
        for(VSO_Project_Job__c pj:projectJobLinks)
        {
            jobProjectIdMap.put(pj.Job__c,pj.VSO_Project__c);
        }
        // get all the projects (note use of Map.values() to get project ids from jobProjectIdMap)
        Map<Id, VSO_Project__c> relatedProjectsMap = new Map<Id, VSO_Project__c>(
            [select id, name, Legacy_Project_Code__c from VSO_Project__c where Id=:jobProjectIdMap.values()]);
        // finally make a map linking jobId to Project
        Map<Id, VSO_Project__c> jobToProjectsMap = new Map<Id, VSO_Project__c>();
        for(Id jobId:jobProjectIdMap.keySet())
        {
            VSO_Project__c linkedProject = relatedProjectsMap.get(jobProjectIdMap.get(jobId));
            jobToProjectsMap.put(jobId, linkedProject);
        }
        return jobToProjectsMap;
    }
    
    
    /*
// old non-bulkified version
//Dinesh-TPT-Recruit V2 Changes-10/June/2015
//Method changed due to Skill and Job object relationship is changed to Lookup relationship. 
public OnboardingData GetOnboardingData(OnboardingCheck__c obc)
{
// throw errors if any obvious data missing
// (more likely in tests than in production)

OnboardingData od = new OnboardingData();
od.OnboardingCheck = obc;

//TPT Amended: for SCS-1527
if(obc.Recruitment_Partner__c!=null)
{
od.account=[select id,Country__c from Account where id=:obc.Recruitment_Partner__c];
}

if (obc.Contact__c == null)
throw new IntegrationException('No Contact is linked to the OnboardingCheck record ' + obc.Name);

od.Contact = [select id, FirstName, LastName, HomePhone, MobilePhone, npe01__WorkPhone__c, OtherPhone,
Email, npe01__AlternateEmail__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, Skype_User_Name__c, 
Partnerships_Programme_Org__c, Primary_Skill__c, Team_Member__c
from Contact where Id = :obc.Contact__c ];

if (obc.Application__c == null)
throw new IntegrationException('No Application is linked to the OnboardingCheck record ' + obc.Name);

od.Application = [select id,Name,Job__c,Applicant__r.Corporate_Partner__c,Applicant__r.Corporate_Partner__r.Organization_Id__c from Application__c where Id = :obc.Application__c ];

if (od.Application.Job__c == null)
throw new IntegrationException('No Job is linked to the Application linked to the OnboardingCheck record ' + obc.Name);
//Dinesh-TPT-KE Phase-2 Changes-21/July/2015
od.Job = [select id, Job_Id__c, Job_Title__c, Primary_Work_Town_City__c, RecordTypeId, Volunteer_Type__c, Volunteering_Within_VSO_Sub_Type__c, Contract_Type__c,
VSO_Entity__c, Group_Federation__c, Department__c, Country__c, Working_Hours_Per_Week__c, Full_Time_Equivalent__c,
Contract_Terms__c, Employer__c, Senior_Approver__c, Primary_Skill__c, Hiring_Manager__c,
Account_Code__c, Activity_Code__c, Cost_Centre__c,Knowledge_Exchange_Partner__c,Development_Partner__c,Knowledge_Exchange_Partner__r.Organization_Id__c,
Development_Partner__r.Organization_Id__c,Knowledge_Exchange_Partner__r.Flights_to_be_invoiced_Y_N__c
from Job__c where Id=:od.Application.Job__c];

od.Country = [select id, name from Country__c where Id=:od.Job.Country__c];

// SCS-1123
// is there an offer?
Id offerId = null;

List<Offer__c> offlist = [select id, name from Offer__c where Application__c=:od.Application.Id limit 1];
if (offlist != null && offlist.size() > 0)
offerId = offlist[0].Id;

if(offerId != null)
od.Offer = [select id, name,Notice_Period__c,Pay_Band__c,Probation_Period__c,Notice_Period_During_Probation_weeks__c,Full_Time_Part_Time__c,Working_Hours_Per_Week__c,Payroll_Office_processing_location__c,RecordType.DeveloperName from Offer__c 
where Id=:offerId];

// SCS-1125
// is there a VSO project related to job?
Id projectId = null;
List<VSO_Project_Job__c> projjoblist = [select id, job__c, vso_project__c from VSO_Project_Job__c where Job__c = :od.Job.Id];
if (projjoblist != null && projjoblist.size() > 0)
projectId = projjoblist[0].vso_project__c;

if (projectId != null)
od.VSOProject = [select id, name, Legacy_Project_Code__c from VSO_Project__c where Id=:projectId];

return od;

}
*/
    
    public static FairsailIntegrationHandler getHandler(){
        if(handler == null){
            handler = new FairsailIntegrationHandler();
        }
        return handler;
    }
    
    private static FairsailIntegrationHandler handler;
    
    private static boolean onboardingCompleteDetected = false;
    
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
    
    public static boolean onboardingCompleteRunOnce()
    {
        if (!onboardingCompleteDetected)
        {
            onboardingCompleteDetected = true;
            return true;
        }
        else
            return false;
    }
    
    // for testing
    public static void ClearRunOnce()
    {
        trueFirstTimeOnly = true;
    }
    
    
    public class IntegrationException extends Exception {}
    
    public class OnboardingData {
        public OnboardingCheck__c OnboardingCheck {get;set;}
        public Contact Contact {get;set;}
        public Application__c Application {get;set;}
        public Job__c Job {get;set;}
        public Country__c Country {get; set;}
        public Offer__c Offer {get; set;}
        public VSO_Project__C VSOProject {get; set;}
        //TPT Amended: for SCS-1527
        public Account account{get;set;}
        public Account RecPartner{get;set;}
        //TPT Amended: for Employee Offer and onboarding
        //public integer addMonths{get;set;}
        // this should be a local variable somewhere rather than a field here
        public Date thedate{get;set;}    
        public String onbJobCountryId {get;set;}   
    }
    
}