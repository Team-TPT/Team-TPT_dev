/*
******************************************************************   
 Change log #1
 
   Modified date : 16 Feb 2016
   Modified by   : Narpavi-TPT
   Purpose       : For Data Quality added the new condition to the existing condition and updated the contact if meets the criteria to avoid the duplication of contact records. 
   Search Tag    : TPT-(16-Feb-2016)

 Change log #2
 
   Modified date : 28 Apr 2016
   Modified by   : Dinesh-TPT
   Purpose       : Implementation of Part-A and Part-B of the Application Form. Converting the single form in to two separate forms to fill Part-A and Part-B of the application forms.
   Search Tag    : Application Form-TPT-(28-Apr-2016)
                        
 Change log #3

   Modified date : 20 April 2016
   Modified by   : Narpavi-TPT
   Purpose       : To display the application form for AVI 
   Search Tag    : TPT-(20-April-2016)  
   
Change log #4
    
   Modified date : 2 August 2016
   Modified by   : Narpavi-TPT
   Project Name  : Refactoring Phase-2
   Purpose       : Code Refactoring
   Search Tag    : TPT-(2-Aug-2016)
   
Change log #5
 
   Modified date : 20-Dec-2016
   Modified by   : Dinesh-TPT
   Purpose       : To pass the Application Source information from VSO website to Salesforce
   Search Tag    : IN00002012     
   
Change log #6
 
   Modified date : 06-Feb-2017
   Modified by   : Dinesh-TPT
   Purpose       : One Stage Application Form
   Search Tag    : AppForm
   
Change log #7
 
   Modified date : 13-Mar-2018
   Modified by   : Dinesh-TPT
   Purpose       : Application Form changes for CR00000128
   Search Tag    : CR00000128
 
Change log #8
 
   Modified date : 14-Sep-2020
   Modified by   : Reena-TPT
   Purpose       : Update Gender Identity Options for CR00000467
   Search Tag    :CR00000467

Change log #9
 
   Modified date : 09-Aug-2022
   Modified by   : Nalla Kannu-TPT
   Purpose       : Added New Validations for CR00000430
   Search Tag    : CR00000430
****************************************************************** 
*/ 

Public   class Job_ApplicationController
{
    public Job__c selectedJob {get;set;}
    public Contact Applicant {get;set;}
    public Application__c jobApplication{get;set;}
    public List<QuestionWrapper> QuestionList{get;set;}
    public SelectOption[] SelectedSkills{get;set;}
    public SelectOption[] allSkills{get;set;}
    public Boolean isQuestions{get;set;}
    public string msg{get;set;}
    //variables for CV upload
    public transient blob uploadedFile{get;set;}   
    public Integer filesize {get; set;}
    public boolean isAppPreview {get; set;}
    public boolean isSupportingError{get;set;}
    public String AVIJob{get;set;}  
    
    public Boolean showCVMissingMsg;
    private String mfilename;
    public String filename{get;set;}
    //CR00000128:Below fields created for this CR
    public string professionValue {get;set;}
    public string consentEmailValue {get;set;}  
    public string consentMailValue {get;set;}     
    public string consentTextValue {get;set;} 
    public string consentTelephoneValue {get;set;}         

    //IN00002012:Code changed for this incident    
    public String sourceSite;
    public String directApp;
    public String sourceSiteToApp;  
    
    public String selectedJobCountry{get;set;}  
    //IN00016384:Added the below code
    public static final String CONSENT_SOURCE = 'Application';
    public static final String CONSENT_WORDING_CODE = 'APP01';
    
    
    public boolean getShowHeaderandSidebar(){
        
         //TPT-(20-April-2016): Amended for AVI
        if(AVIJob!='True')
        {
            return (Utility.getProfileName(Userinfo.getProfileId())!='Job Opportunities Sites Profile');
        }
        else if(AVIJob=='True')
        {
             return (Utility.getProfileName(Userinfo.getProfileId())!='AVI Job Opportunities Profile');
        }
        return false;
    }
    
    // main constructor, used by visualforce page
    // Ian Finch 21/Jan/2016
    public Job_ApplicationController()
    {            
        String jobIdParam = ApexPages.currentPage().getParameters().get('jid');
        setup(jobIdParam);        
        AVIJob=ApexPages.currentPage().getParameters().get('IsAVIJob'); //TPT-(20-April-2016): Added for AVI                        
    }
    
    // alternative constructor for use when calling controller from non-visualforce environment
    // such as web services. Ian Finch 21/Jan/2016
    public Job_ApplicationController(String jobIdParam)
    {
        setup(jobIdParam);     
    }
    
    // setup code used by constructors. Ian Finch 21/Jan/2016
    private void setup(String jobIdParam) 
    {
        validationCheck=false;
        isQuestions=false;
        errormsg='';
        
        showCVMissingMsg = false;

        selectedJob=new Job__c();
        Applicant=new Contact();
        jobApplication=new Application__c();      
        QuestionList=new List<QuestionWrapper>();
        SelectedSkills=new List<SelectOption>();
        
        List<Skill__c> skills = [SELECT Id, Name, Group__c FROM Skill__c WHERE Active__c=true AND (NOT Group__c LIKE '%Migrated Skill%') ORDER BY Group__c, Name];    
        allSkills = new List<SelectOption>();
        for (Skill__c s : skills) 
        {
            //allSkills.add(new SelectOption(s.Id, s.Group__c + ': ' + s.Name));
            allSkills.add(new SelectOption(s.Id, s.Name));
        }       
        
        String JobId = jobIdParam;
        if(JobId!=null && JobId!='')
        {
            //AppForm: New fields added to the SELECT Query
            List<Job__c>temp =[Select id, RecordType.DeveloperName, RecordTypeId, (Select id,Name, Job__c, Question__c,Question__r.name,Question__r.Question__c,Question__r.Correct_Answer__c,
                    Question__r.Applies_To__c,Weighting__c,Mandatory_Question__c,Help_Correct_Answer__c From Job_Questions__r where Question__r.Active__c=true),
                    Job_Title__c,name,Desk_Space_Location__c,Projected_Duration_Weeks__c,Projected_Start_Date__c ,Country__c,
                    Projected_End_Date__c,Job_Reason__c,Actual_Start_Date__c,Introduction_to_VSO__c,
                    Actual_End_Date__c,Role_Overview__c,Ideal_Applicant_Summary__c,How_To_Apply__c,
                    Advertised_Job_Start_Date__c,Advertised_Interview_Date__c,Advertise_Internally__c,Advertise_Externally__c,
                    Additional_Advert_Text__c,Country__r.Name,EligibilityToWorkIn_JobCountry_Essential__c,Help_Type__c,
                    Use_Supporting_Statement__c,Supporting_Statement_Instruction__c From Job__c where Id=:JobId]; 
              
            if(temp.size()>0)
            {
                selectedJob=temp[0];
            }
            
            if(selectedJob.Job_Questions__r.size()>0)
            {
                isQuestions=true;
                for(Job_Question__c jq:selectedJob.Job_Questions__r){
                    QuestionList.add(new QuestionWrapper(jq));
                }
            }  
            
            if(selectedJob.Country__r.Name!=null){
                selectedJobCountry=selectedJob.Country__r.Name;
            }          
        }
    }
    
    /*-----------finding picklist values---------------------------------*/  
    
    public List<selectoption> getAnswersOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =Application_Answer__c.Answer__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }
  
    public List<selectoption> getCountryList()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =Contact.Country_List__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();       
        for( Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;     
    }
    
    public List<selectoption> getSkills()
    {
        List<SelectOption> options = new List<SelectOption>();
        List<Skill__c> skills = [SELECT Id, Name, Group__c FROM Skill__c WHERE Active__c=true AND (NOT Group__c LIKE '%Migrated Skill%')];
        for (Skill__c s : skills) {
            options.add(new SelectOption(s.Id, s.Group__c + ': ' + s.Name));
        }
        return options;
    }
    
    public List<selectoption> getSkillsWithNoneOption()    
    {
        List<SelectOption> options = new List<SelectOption>();
        List<Skill__c> skills = [SELECT Id, Name, Group__c FROM Skill__c WHERE Active__c=true AND (NOT Group__c LIKE '%Migrated Skill%') ORDER BY Group__c, Name];
        
        // Add the option for None
        options.add(new SelectOption('--None--', '--None--'));
        
        // Add all Skills in system
        for (Skill__c s : skills)
        {
            options.add(new SelectOption(s.Id, s.Group__c + ': ' + s.Name));
        }
        return options;
    }
        
    public String applicationStatus{get;set;}       
    public boolean validationCheck{get;set;}
    public String errormsg{get;set;}
    
    // added for web service, Ian Finch 21/Jan/2016
    public String internalErrorMsg{get;set;}
    
    public PageReference ApplicationSubmit()
    {    
              
        validationCheck=false;         
        errormsg='';
        applicationStatus='';
        system.debug('**********applicationStatus:'+applicationStatus);   
             
        Savepoint sp1=database.setSavepoint();       
         
        if(Applicant.Available_From__c<System.today())
        {           
            errormsg+='<li>Available from and available to cannot be in past date</li>';
        }  
       
        if(!Applicant.Consent_To_Information_Being_Stored__c)
        {
            errormsg+='<li>Please provide your consent to information being stored</li>';
        }
        
        if(!jobApplication.Declaration__c)
        {
            errormsg+='<li>Please declare that the information provided is true and correct</li>';
        }  
              
        for(QuestionWrapper qw:QuestionList)
        {
            if (!Test.isRunningTest() && (qw.response==null || qw.response==''))
            {
                errormsg+='<li>Please answer application question "' + qw.JobQuestion.Question__r.Question__c + '"</li>';
            }
            //AppForm:Added a new validation message
            if(qw.JobQuestion.Mandatory_Question__c && qw.JobQuestion.Help_Correct_Answer__c!=qw.response){
                errormsg+='<li>Please specify the correct answer to the question"'+qw.JobQuestion.Question__r.Question__c+'"</li>';
            }
        }        
        
        if ((jobApplication.Supporting_Statement__c== null || jobApplication.Supporting_Statement__c== '') &&
             selectedJob.Use_Supporting_Statement__c)
        {
            errormsg+= '<li>Please provide a supporting statement.</li>';            
        }
        
        if (Applicant.MailingCountry == null || Applicant.MailingCountry == '' || Applicant.MailingCountry == '--None--')           
        {
            errormsg+= '<li>Please select a country of residence.</li>';            
        }  
        
        //IN00005997 - Added a new validation message
        if (Applicant.MailingCountry == 'United Kingdom' && Applicant.MailingPostalCode == null)           
        {
            errormsg+= '<li>Please enter the PostCode </li>';            
        }
          
        if (uploadedFile == null && filename != null && filename != '' && !showCVMissingMsg)
        {
            showCVMissingMsg = true;
            errormsg+= '<li>Please re-attach your CV before submitting the form.</li>';
        }
        else if (uploadedFile == null)
        {
            errormsg+= '<li>Please attach your CV before submitting the form.</li>';
        }

        //SS-13740087-Narpavi-TPT-(29-Jun2-2016)
        //Increased the file size from 200KB to 1024KB 
        if (uploadedFile != null && filename != '' && filesize > 1049600){
            errormsg+= '<li>Please attach a smaller size CV: ' + filename + ' (size=' + Decimal.valueOf(filesize/1024).setScale(0) + 'KB) has exceeded the 1024KB limit.</li>';  
        }             
        
        //Application Form-TPT-(28-Apr-2016)
        //Validate if the supporting statement exceeds 1500 words        
        if(isSupportingError!=null && isSupportingError)
        {
            errormsg+='<li>Please provide the supporting statement within the limit of 1500 words</li>' ;
        }
        
        //AppForm:Added a new validation message
        if(selectedJob.Help_Type__c=='Employee' && selectedJob.EligibilityToWorkIn_JobCountry_Essential__c==True && jobApplication.Eligibility_To_Work__c!='Yes'){
            errormsg+='<li>You are not eligible to submit the Application Form, as you are not having the right to work in '+selectedJob.Country__r.Name+'</li>';
        } 
        
        if(SelectedSkills.size()<=0){
                errormsg+='<li>Please select the Areas of Expertise</li>' ;
        }
        
         //CR00000467: Reena - Added validation for the new field Gender Identity Details
        
        if(Applicant.Prefer_to_self_describe_gender_details__c == null && Applicant.Gender__c =='Prefer to self-describe'){
                errormsg+='<li>Please include details for how you prefer to self-describe  your  Gender</li>' ;
        }
        
        if(Applicant.Prefer_to_self_describe_gender_details__c != null && Applicant.Gender__c !='Prefer to self-describe'){
                errormsg+='<li>"Prefer to self-describe gender details" should only be completed if "prefer to self-describe" is selected for "What best describes your gender?"</li>' ;
        } 
        
        // End of CR00000467
        
        //CR00000128:Added a validation message and also hardcoded the user id (AppFormAPI User) to avoid the below 
        //validations for Application form in Drupal page.
        
        if(userInfo.getUserId()!='005D0000007cWYZIA2'){
                if(Applicant.Consent_Email__c == null || Applicant.Consent_Email__c == ''){
                    errormsg+='<li>Please select the Consent for Email</li>';
                }         
                if(Applicant.Consent_Phone__c == null || Applicant.Consent_Phone__c == ''){
                    errormsg+='<li>Please select the Consent for Phone</li>';
                }        
                if(Applicant.Consent_Post__c == null || Applicant.Consent_Post__c == ''){
                    errormsg+='<li>Please select the Consent for Post</li>';
                }                     
                if(Applicant.Consent_Text__c == null || Applicant.Consent_Text__c == ''){
                    errormsg+='<li>Please select the Consent for Text</li>';
                } 
        }
        
        //CR00000430: Added New Validation 
        if(Applicant.Religion__c=='Other' && Applicant.Religion_Other__c==Null){
            errormsg+='<li>Please include details for Religion Other</li>' ;
        }
        
        if(Applicant.Ethnicity__c=='Other' && Applicant.Ethnicity_Other__c==Null){
            errormsg+='<li>Please include details for Ethnicity Other</li>' ;
        }
        
        if(Applicant.Sexuality__c=='Prefer to Self-describe' && Applicant.Self_describe_Sexual_Orientation_details__c==Null){
            errormsg+='<li>Please include details for Self-describe Sexual Orientation details</li>' ;
        }
        
        if(errormsg!=''&& errormsg!=null)
        {            
            validationCheck=true;           
            system.debug('************errormsg:'+errormsg);
        }
        else
        {           
           try
           {         
                //TPT-(16-Feb-2016)- Added new condition to the existing condition               
                List<Contact> con=[SELECT id,name FROM Contact WHERE
                                   (npe01__HomeEmail__c=:Applicant.npe01__HomeEmail__c) 
                                    OR (npe01__WorkEmail__c=:Applicant.npe01__HomeEmail__c) 
                                    OR (FirstName=:Applicant.FirstName AND MobilePhone=: Applicant.MobilePhone) 
                                    OR (FirstName=:Applicant.FirstName AND HomePhone=: Applicant.MobilePhone) 
                                    OR (FirstName=:Applicant.FirstName AND MailingStreet=:Applicant.MailingStreet 
                                    AND LastName=:Applicant.LastName ) LIMIT 1];
                if(con.size()>0)
                {
                   Applicant.id=con[0].id;
                }
                    
                //to avoid validation
                Applicant.npe01__PreferredPhone__c = 'Mobile';
                Applicant.npe01__Preferred_Email__c = 'Personal';
                                                                             
                //CR00000128:Storing the Consent section Fields.
                //IN00016384:Added the CONSENT_SOURCE and CONSENT_WORDING_CODE for this incident
                if(Applicant.Consent_Email__c!='' && Applicant.Consent_Email__c!=null){
                    Applicant.Email_Consent_Date__c         = datetime.now();                    
                    Applicant.Email_Consent_Source__c       = CONSENT_SOURCE;
                    Applicant.Email_Consent_Wording_Code__c = CONSENT_WORDING_CODE;
                }
                
                if(Applicant.Consent_Post__c!='' && Applicant.Consent_Post__c!=null){
                    Applicant.Mail_Consent_Date__c         = datetime.now();
                    Applicant.Mail_Consent_Source__c       = CONSENT_SOURCE;
                    Applicant.Mail_Consent_Wording_Code__c = CONSENT_WORDING_CODE;
                }
                
                if(Applicant.Consent_Text__c!='' && Applicant.Consent_Text__c!=null){
                    Applicant.SMS_Text_Instant_Consent_Date__c         = datetime.now();
                    Applicant.SMS_Text_Instant_Consent_Source__c       = CONSENT_SOURCE;
                    Applicant.SMS_Text_Instant_Consent_Wording_Code__c = CONSENT_WORDING_CODE;
                }
                
                if(Applicant.Consent_Phone__c!='' && Applicant.Consent_Phone__c!=null){
                    Applicant.Telephone_Consent_Date__c         = datetime.now();
                    Applicant.Telephone_Consent_Source__c       = CONSENT_SOURCE;
                    Applicant.Telephone_Consent_Wording_Code__c = CONSENT_WORDING_CODE;
                }
                
                upsert Applicant;
                         
                jobApplication.Status__c='New';                                            
                jobApplication.Applicant__c = Applicant.id;
                jobApplication.Job__c=selectedJob.id;                    
                jobApplication.Source__c='Web';
                jobApplication.Consent_To_Information_Being_Stored__c=Applicant.Consent_To_Information_Being_Stored__c;
                // map contact fields to application
                jobApplication.Current_Education_Level__c = Applicant.Current_Education_Level__c;                        
                      
                //TPT-(20-April-2016):Added for AVI to autopopulate the Recuriment Partner in application.
                if(AVIJob=='True')
                {    
                     List<Account> listAccount=[SELECT Id, Name FROM Account WHERE Name='Recruitment Channel - AVI'];                       
                     if(listAccount.size()>0)
                     {                        
                        jobApplication.Assigned_Recruitment_Partner__c=listAccount[0].id;
                     }                        
                     jobApplication.Is_AVI_Application_Form__c= true;                   
                }
               
                //IN00002012:Code changed for this incident                        
                if(sourceSite!=null){
                    jobApplication.Source_Site__c=sourceSite;
                }
                if(directApp!=null){
                    jobApplication.Direct_Application__c=Boolean.valueOf(directApp);
                }
                if(sourceSiteToApp!=null){
                    jobApplication.Source_Site_to_Application_Days__c=Decimal.valueOf(sourceSiteToApp);
                }               
                        
                insert jobApplication;
                
                //Update the Contact record to calculate the field 'Available To'
                 if(jobApplication.How_Long_are_You_Available__c!=null ||
                    jobApplication.How_Long_are_You_Available__c!=''){
                    
                        Contact conObj=new Contact();
                        conObj.id=Applicant.id;
                        if(jobApplication.How_Long_are_You_Available__c=='3 Months'){
                            conObj.Available_To__c=Applicant.Available_From__c.addMonths(3);
                        }             
                        else if(jobApplication.How_Long_are_You_Available__c=='6 Months'){
                            conObj.Available_To__c=Applicant.Available_From__c.addMonths(6);
                        }                     
                        else if(jobApplication.How_Long_are_You_Available__c=='1 Year'){
                            conObj.Available_To__c=Applicant.Available_From__c.addYears(1);
                        }                     
                        else if(jobApplication.How_Long_are_You_Available__c=='2 Years'){
                            conObj.Available_To__c=Applicant.Available_From__c.addYears(2);
                        }       
                        update conObj;
                }
                                                                                                      
                if(uploadedFile!=null)
                {
                        Attachment attach=new Attachment();
                        attach.name=filename;
                        attach.body=uploadedFile;
                        attach.parentid=jobApplication.id;
                        insert attach;
                }

                if(QuestionList.size()>0)
                {
                        List<Application_Answer__c> AppQuestionRecords=new List<Application_Answer__c> ();
                        for(QuestionWrapper qw:QuestionList)
                        {
                            Application_Answer__c appAns=new Application_Answer__c(Application__c=jobApplication.id,Job_Question__c=qw.JobQuestion.id,Answer__c=qw.response);
                            AppQuestionRecords.add(appAns);
                        }
                        insert AppQuestionRecords;
                }
                //AppForm:Added the below codes to make the Single picklist to Multipicklist for Skills
                // Get the revised list of current skills for the Contact record
                List<Contact_Skill__c> ExistingSkills = [SELECT Id, Skill__c FROM Contact_Skill__c WHERE Contact__r.Id = :Applicant.Id ORDER BY Skill__c];
                List<Contact_Skill__c> NewSkills = new List<Contact_Skill__c>();
                Boolean SelectedSkillInCurrentSkills = false;
               
                // For each of the selected skills...
                for(SelectOption so : selectedskills){
                    SelectedSkillInCurrentSkills = false;
                        
                     // ...check whether it exists in the current list...
                     for(Contact_Skill__c es : ExistingSkills){
                         system.debug('$$$ so.getValue() = '+ so.getValue() +' es.Skill__c= ' + es.Skill__c);
                         if(so.getValue() == es.Skill__c){
                              SelectedSkillInCurrentSkills = true;
                         }
                     }                        
                     
                     // ...and if it doesn't, add a new skill to the list to be created
                     if(SelectedSkillInCurrentSkills == false){
                        Contact_Skill__c skills= new Contact_Skill__c(Contact__c=Applicant.Id,Skill__c=so.getValue(),Primary_Contact_Skill__c=false);
                        NewSkills.add(skills);
                     }
                }
                if (NewSkills.size()>0){                    
                    insert NewSkills;
                }
                                
                applicationStatus='Submitted';                             
           }
            catch(exception e)
            {
                    //uploadedFile = null;
                    applicationStatus='Submission Error';
                    
                    // keep error message for internal use but dont show to user. Ian Finch 21/Jan/2016
                    internalErrorMsg = e.getMessage() + ' Line: ' + e.getLineNumber() + '<br/>Stack Trace:<br/>' + e.getStackTraceString();
                    msg=internalErrorMsg;
                    Database.rollback(sp1); 
                    system.debug('ERORR:'+msg);
            }
            finally{
                //attach.body = null;
            }   
       }        
        return null;
    }
   
    public class QuestionWrapper
    {
        public Job_Question__c JobQuestion{get;set;}
        public String response{get;set;}       
        public QuestionWrapper(Job_Question__c Jq)
        {
            this.JobQuestion=Jq;
        }
    }
    
    //Application Form-TPT-(28-Apr-2016)
    //Method to nvaigate to the application preview page
    public PageReference appPreview() 
    {  
        isAppPreview =true; 
        PageReference oPageRef = Page.ApplicationPage_Preview;           
        oPageRef.setRedirect(false); 
        professionValue='';
        if(selectedskills!=null){
            for(SelectOption so : selectedskills){                
                    professionValue+=so.getLabel();
            }
        }
             
        return oPageRef;       
    }  
    
    //CR00000128:Created the below method
    public List<SelectOption> getConsentItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }   
    
}