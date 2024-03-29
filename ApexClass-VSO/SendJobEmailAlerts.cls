//Poornima - Created the class for processing job alert emails in batch - Dated 12-01-2015
//Poornima -23-mar-2016- modified to add database.stateful to get the total emails processed for checking against the email limit 
global class SendJobEmailAlerts implements Database.Batchable<sObject>,Database.Stateful{

private List<JobAlert__c> jobalerts;
public Contact contact {get;set;}
public List<Messaging.SingleEmailMessage> mails;
public String[] contactIdList;
public Integer emailLimit;

public Integer jobAlertCount=0;
global final String query;  

//Query passed from the scheduler - ScheduledBatchJobEmailAlerts
global SendJobEmailAlerts(String q) {
       query = q;   }


global Database.QueryLocator start(Database.BatchableContext BC)
{
    return Database.getQueryLocator(query);
}

global void execute(Database.BatchableContext BC,List<JobAlert__c> jobalertList)
{
    //Get the email limit
    VSO_Site_Settings__c site=VSO_Site_Settings__c.getValues('Job Opportunities');
    emailLimit=Integer.valueOf(site.Job_Alert_Email_Limit__c);
    system.debug('Email Limit:'+emailLimit);
    
    for(JobAlert__c JobAlertContact:jobalertList)
    {   
        if(jobAlertCount<=emailLimit)
        {  
            string[] jobDetails=new List<string>();
            string[] jobTitle=new List<string>();
            string[] locatedIn=new List<string>();
            string[] plannedStartDate=new List<string>();
            string[] jobType=new List<string>();
            string[] terms=new List<string>();
            string[] closingDate=new List<string>();   
            string[] jobUrl=new List<string>();
            string contactName,unSubscribeUrl,contactId,encryptedContactId;
            
            jobalerts = [SELECT id,Contact__c,Contact__r.FirstName,Contact__r.Email,Job__r.Job_Title__c,Job__r.Help_Country__c,Job__r.Advertised_Job_Start_Date__c,Job__r.Type__c,Job__r.Advertised_Salary__c,Job__r.Contract_Type__c,Job__r.Full_Or_Part_Time__c,Job__r.Application_Closing_Date__c,Job__r.Help_Job_Ad_Url__c,Job__r.Help_Unsubscribe_Url__c FROM jobalert__c WHERE Processed__c=:false and Contact__c=:JobAlertContact.Contact__c and Contact__r.Unsubscribe_For_Job_Email_Alert__c=:false];
            if(jobalerts.size()>0)
            {
                 contactName=jobalerts[0].Contact__r.FirstName;
                 unSubscribeUrl=jobalerts[0].Job__r.Help_Unsubscribe_Url__c;
                 contactId=jobalerts[0].Contact__r.Id;
                //CR-450 changes BEGINS to encrypt the contact record id
                 encryptedContactId = CryptoUtil.encyptData(contactId);
                //CR-450 changes ENDS to encrypt the contact record id
                //get the details of the matched jobs to contruct the email
                for(jobalert__c obj:jobalerts)
                {      
                   jobTitle.add(obj.Job__r.Job_Title__c); 
                   locatedIn.add(obj.Job__r.Help_Country__c);   
                   plannedStartDate.add(obj.Job__r.Advertised_Job_Start_Date__c); 
                   jobType.add(obj.Job__r.Type__c);
                       
                   string termsDetails='ADVERTISED SALARY: '+obj.Job__r.Advertised_Salary__c
                                       +'<br/>CONTRACT TYPE: '+obj.Job__r.Contract_Type__c
                                       +'<br/>FULL OR PART TIME: '+obj.Job__r.Full_Or_Part_Time__c+'<br/>';
                   if(obj.Job__r.Type__c=='Volunteer Job')               
                       {termsDetails='';}
                   terms.add(termsDetails);               
                   
                   if(obj.Job__r.Application_Closing_Date__c==NULL)
                       {closingDate.add(''); }
                   else                   
                       {closingDate.add(string.valueof(obj.Job__r.Application_Closing_Date__c));}
                   
                   jobUrl.add(obj.Job__r.Help_Job_Ad_Url__c);
                }
                try
                {           
                
                    // grab the email template
                    EmailTemplate emailTemplate = [SELECT Id,Name,Subject,HtmlValue,Body FROM EmailTemplate where Name=:'Job Alert Email Template'];
                    // process the merge fields
                    String id=emailTemplate.Id;
                    String plainBody = emailTemplate.Body;
                    String htmlBody=emailTemplate.HtmlValue; 
                    
                    string headerImg='<table align="center"><tr valign="top"><td style="vertical-align: middle; height: 100px; text-align: left; width: 700px; background-color: rgb(173, 0, 117);"><img id="r1sp1" blabel="headerImage" border="0" beditid="r1sp1" src="https://vso--c.eu1.content.force.com/servlet/servlet.ImageServer?id=015D0000002Rrmy&oid=00DD0000000o0JM&lastMod=1403235570000"></td></tr></table>';
                    plainBody = plainBody.replace('[HeaderImage]',headerImg);
                    string commonMsg='<table align="center"><tr><td style="font-family:Verdana, arial, helvetica, sans-serif; font-size:13px; vertical-align: middle;text-align: left; width: 700px;">'
                                     +'Dear '+contactName+'<br/>'
                                     +'<br/>Thank you for registering to receive job alerts from VSO. The following job(s) are now posted on our website which match your criteria:<br/></td></tr></table>';
                    plainBody=plainBody.replace('[CommonMessage]',commonMsg);
                    
                    string b='';
                    Integer jobCount=1;
                    for(Integer i=0;i<jobalerts.size();i++)
                    {              
                       string a='<table align="center"><tr>'
                                +'<td style="font-family:Verdana, arial, helvetica, sans-serif; font-size:13px; vertical-align: middle;text-align: left; width: 700px;">'
                                +'<b>JOB OPPORTUNITY</b> '+jobCount                    
                                +'<br/>JOB TITLE: '+string.valueof(jobTitle.get(i))
                                +'<br/>JOB LOCATION: '+string.valueof(locatedIn.get(i))
                                +'<br/>PLANNED START DATE: '+string.valueof(plannedStartDate.get(i))
                                +'<br/>JOB TYPE: '+string.valueof(jobType.get(i))
                                +'<br/>'+string.valueof(terms.get(i))
                                +'CLOSING DATE: '+string.valueof(closingDate.get(i))                                       
                                +'<br/>For more information and to apply please <a href='+string.valueof(jobUrl.get(i))+'>click here</a>.';                    
                       jobCount++; 
                       jobDetails.add(a);     
                    }
                
                    for(Integer j=0;j<jobalerts.size();j++)
                    { 
                       b+=string.valueof(jobDetails.get(j))+'<br/><br/>';      
                    }     
                              
                    plainBody = plainBody.replace('[JobDetails]',b);                    
                   
                    string unsubscribeText='<br/>Thank you for your interest in VSO.<br/></td></tr></table>';
                    
                    plainBody=plainBody.replace('[UnsubscribeDetails]',unsubscribeText);
                    //CR-450 changes added the variable encryptedContactId to the email template	
                    string footerImg='<table align="center"><tr valign="top">'
                    +'<td bgcolor="#ffffff" style="border-top: 4px solid #ad0075;width: 700px;">'
                    +'<table border="0" cellpadding="0" cellspacing="0">'          
                    +'<tr><td style="font-size:1px; line-height:20px;">&nbsp;</td></tr>'
                    +'<tr><td align="left" style="font-family:Verdana, arial, helvetica, sans-serif; font-size:11px;">'
                    +'VSO is the world&#39;s leading independent international development charity that works through volunteers to fight poverty. Voluntary Service Overseas is a company limited by guarantee, registered in England and Wales registered number 703509. Registered Office 100 London Road, Kingston upon Thames KT2 6QJ, England. Charity Registration 313757 (England and Wales) SCO39117 (Scotland). Copyright &#169; 2018 VSO unless otherwise stated.' 
        			+'<br/><br/>We will never sell or swop your data, and we promise to keep it safe and secure in line with our <a href="http://www.vsointernational.org/privacy">privacy policy</a>.If you would prefer not to receive Job Alerts emails please <a href='+unSubscribeUrl+encryptedContactId+'>unsubscribe</a>.You may continue to receive other types of emails from VSO. You can unsubscribe from these by clicking the link in each email you receive. Email our supporter care team on <a href="mailto:enquiry@vsoint.org">enquiry@vsoint.org </a> if you have any questions.'        
        			+'</td></tr>'+'<tr><td style="font-size:1px; line-height:20px;">&nbsp;</td></tr>'     
        			+'<tr><td style="font-size:1px; line-height:20px;">&nbsp;</td></tr></table></td></tr></table>';    
                    
                    plainBody = plainBody.replace('[FooterImage]',footerImg);
                    
                    //build the email message and send  
                    Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();        
                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:'noreply@vsoint.org'];
                    if ( owea.size() > 0 ) {
                       email.setOrgWideEmailAddressId(owea.get(0).Id);
                    }       
                    email.setTargetObjectId(contactId);    
                    email.setSubject('VSO has posted  a job which matches your criteria!');          
                    email.setHtmlBody(plainBody);      
                    List<Messaging.SendEmailResult> results= Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});     
                    boolean emailSent=results.get(0).isSuccess();
                   
                    //Update Job alert as processed if email sent successfully.
                    // If email not sent and the error message return invalid email address unsubscribe the contact from receiving job alerts.
                    if(emailSent)
                    {
                        jobAlertCount+=1;
                        List<JobAlert__c> lstToUpdate=new List<JobAlert__c>();
                        List<JobAlert__c> jobAlertsRecords=[SELECT id,Contact__c,Processed__c 
                                                              FROM JobAlert__c WHERE Contact__c=:contactid and Processed__c=:false ];
                        if(jobAlertsRecords.Size()>0)
                        {
                            for(JobAlert__c ja:jobAlertsRecords)                                      
                            {
                                ja.Processed__c=true;
                                lstToUpdate.add(ja);               
                            }           
                        }
                        if(lstToUpdate.size()>0)
                        {
                            update lstToUpdate;
                        }
                    }          
                 }
                 catch(Exception e)
                 {
                    System.debug('Error while sending email'+e.getMessage()); 
                    //Unsubscribe contact if email address is invalid
                    if(e.getMessage().contains('INVALID_EMAIL_ADDRESS'))
                    {
                    	List<Contact> contactRecords=[SELECT id,Unsubscribe_For_Job_Email_Alert__c,FirstName FROM Contact WHERE id=:contactid];
                        if(contactRecords.Size()>0)
                        {
                            contact=contactRecords[0];
                            contact.Unsubscribe_For_Job_Email_Alert__c=true;
                            update contact;
                        }
                    }
                   //Add error to error log
                   string errorMsg=e.getmessage();
                   string errorClass='SendJobEmailAlerts';
                   string errorStack=e.getStackTraceString();
                   string errorType=e.getTypeName();
                   //log the exception
                   ApplicationErrorLogController obj=new ApplicationErrorLogController();
                   obj.logError(errorClass,errorMsg,errorStack,errorType); 
                 }                 
            } 
        }
    }   
}
   

//Method to send job alerts email  
global void finish(Database.BatchableContext BC)
{
    system.debug('Emails Processed:'+jobAlertCount);
}



}