/* LEX Transition Changes
Modified by : Vel-TPT
Date        : Dec-2019 */

public without sharing class Job_DetailsPageController{
    public Job__c jobRec {get;set;}
    public String attachmentURL{get;set;}
    public String attachmentId{get;set;}
    public String filename{get;set;}
    //file showing in lightning *18.11.2019* Added by Vel-TPT
    public String FileId{get;set;}
    public String FileTitle{get;set;}
    public string JobId;
    // public boolean isActualRecordId;//CR-450: New variable declared
    
    //TPT-(20-April-2016):Added for AVI
    public String AVIJob{get;set;}
    
    private Map<string, VSO_Site_Settings__c> mapVSOSiteSettings;
    
    public Job_DetailsPageController(Apexpages.standardcontroller controller){
        this();
    }
    public Job_DetailsPageController(){
        system.debug('test simply--');
         mapVSOSiteSettings = VSO_Site_Settings__c.getAll();
         attachmentURL='';
       // String JobId = ApexPages.currentPage().getParameters().get('jid'); //Removed LEX Changes -Vel-TPT
         JobId = ApexPages.currentPage().getParameters().get('jid'); // commented for 450 encryption
         AVIJob=ApexPages.currentPage().getParameters().get('IsAVIJob');  //TPT-(20-April-2016):Added for AVI
         //commented encryption
        /*
        //CR-450: Dinesh Changes BEGINS: Step to decrypt the Job id
        String jobRecId,encryptedJobId;     
        jobRecId = ApexPages.currentPage().getParameters().get('jid');
        isActualRecordId = UtilityClass.doesRecordExist(jobRecId);
        if(isActualRecordId){
            JobId = jobRecId;
        } else{
            encryptedJobId = jobRecId;
            JobId = CryptoUtil.decryptData(encryptedJobId.replaceAll(' ','+'));
        }        
        //CR-450: Dinesh Changes ENDS
           **/
                 
         if(JobId!=null && JobId!=''){
            list<Job__c> joblist = [Select Job_Title__c,Help_Type__c,Desk_Space_Location__c,Projected_Start_Date__c ,
                    (select id,name from Attachments where IsPrivate=false AND Name like:'%VSOJD%' order by LastmodifiedDate DESC Limit 1),
                   Projected_End_Date__c,Job_Status__c,Job_Reason__c,Update_Job_Status__c,Actual_Start_Date__c,Actual_End_Date__c,
                   Primary_Work_Town_City__c, Country__c,Country__r.name, Contract_Type__c, Contract_Length__c,Full_Or_Part_Time__c,
                   Working_Hours_Per_Week__c, Application_Closing_Date__c,Advertised_Salary__c,Role_Overview__c,Introduction_to_VSO__c,
                   Ideal_Applicant_Summary__c,How_To_Apply__c, Advertised_Job_Start_Date__c, Advertised_Interview_Date__c,
                   Advertise_Internally__c,Advertise_Externally__c,Additional_Advert_Text__c,Projected_Duration_Weeks__c, Advertised_Project_Duration__c,
                   Employer__c,Employer__r.name,Use_Senior_Roles_Application_Form__c, Website_Job_Url__c, Mode_Of_Delivery__c, Mode_of_Delivery_Text__c From Job__c where Id=:JobId];            
            system.debug('test attach-11-'+joblist);
             
             if(joblist.size()>0){
                 system.debug('test attach-12-'+joblist);
                jobRec=joblist[0];
                 system.debug('test jobRec----'+jobRec);
                if(jobRec.Attachments.size()>0){
                    system.debug('test --jobRec.Attachments[0]----'+jobRec.Attachments[0]);
                    attachmentURL='/servlet/servlet.FileDownload?file='+jobRec.Attachments[0].id;
                    filename=jobRec.Attachments[0].name;
                    attachmentId=jobRec.Attachments[0].id;
                }

            } 
         }
         
    }

    // page action is called on page load
    // checks for m=i querystring (for internal jobs)
    // if its not internal, redirect to main web site
    // (Ian Finch Feb 2018)    
    public PageReference checkRedirectPageAction(){
      String mMode = ApexPages.currentPage().getParameters().get('m');  
    //--Devloped By Velu-TPT         
    //--File Downloaded link *18-11-2019*---    
         if(JobId!=null && JobId!=''){
        list<contentDocumentLink> CDLink = [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid=:JobId];
         //system.debug('test=CDLink==0='+CDLink);
                        list<id> contentDocuId = new list<id>();
                if(CDLink.size()>0){
                    for(contentDocumentLink cl : CDLink){
                        contentDocuId.add(cl.ContentDocumentid);
                       
                    }
                    if(contentDocuId.size()>0){
                     List<ContentVersion> cversion= [SELECT title, PathOnClient, FileType, versiondata,ContentUrl FROM contentversion WHERE ContentDocumentId IN :contentDocuId AND Title like:'%VSOJD%'];
                        if(cversion.size()>0){
                            FileTitle=cversion[0].title;                         
                            FileId = cversion[0].id;
                            }
                    }
                }
         }
        //CR-450: Changes BEGINS - Pass the ContentVersion Id and get the Download Url
        if(FileId != null && FileId != ''){
            FileId = getDownloadURL(Id.valueOf(FileId));
        }
        //CR-450: Changes ENDS
              
      if (mMode == 'i')
      {
          // page is showing internally advertised jobs, no need to redirect
          return null;
      }
      string externalJobUrl = this.jobRec.Website_Job_Url__c;
      if (externalJobUrl == null)
          return null;

      PageReference retURL = new PageReference(externalJobUrl);
      retURL.setRedirect(true);
      return retURL;
    }

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
    
    //Dinesh-TPT-RecruitV2 changes-08/June/2015.
    //Method changed to navigate the user to the appropriate application page based on the job type
    public pagereference Applytojob(){
        if((jobRec.Help_Type__c=='Employee') && (jobRec.Use_Senior_Roles_Application_Form__c!=false)){           
             pageReference pg1=page.Job_SeniorRoleApplicationPage; 
            //below line to be commented for encryption
            pg1.getparameters().put('jid',jobRec.id); 
             /*
             //CR-450: Dinesh Changes BEGINS
             if(isActualRecordId){
                pg1.getparameters().put('jid',jobRec.id);
             } else {
                String encryptedJobId = CryptoUtil.encyptData(string.valueOf(jobRec.id));
                pg1.getparameters().put('jid',encryptedJobId); 
             }
             //CR-450: Dinesh Changes ENDS
             **/
             pg1.setRedirect(true);         
             return pg1;            
        }
        else if (jobRec.Help_Type__c=='Corporate'){
             pageReference pg2=page.Job_KnowledgeExchangeApplicationPage;
              // Below line to be commented for encryption
             pg2.getparameters().put('jid',jobRec.id); 
             /*
             //CR-450: Dinesh Changes BEGINS
             if(isActualRecordId){
                pg2.getparameters().put('jid',jobRec.id);
             } else {
                String encryptedJobId = CryptoUtil.encyptData(string.valueOf(jobRec.id));
                pg2.getparameters().put('jid',encryptedJobId); 
             }
             //CR-450: Dinesh Changes ENDS
             **/
             pg2.setRedirect(true);         
             return pg2;        
        }
        else{
            pageReference  pg=page.Job_ApplicationPage; 
             // Below line to be commented for encryption
            pg.getparameters().put('jid',jobRec.id); 
            /*
            //CR-450: Dinesh Changes BEGINS
            if(isActualRecordId){
                pg.getparameters().put('jid',jobRec.id);
            } else {
                String encryptedJobId = CryptoUtil.encyptData(string.valueOf(jobRec.id));
                pg.getparameters().put('jid',encryptedJobId); 
            }
            //CR-450: Dinesh Changes ENDS
            **/
            pg.getparameters().put('IsAVIJob',AVIJob);   //TPT-(20-April-2016):Added for AVI
            pg.setRedirect(true);
            return pg;
        }
    }

    public String gettargetURL()
    {
        String workTargetURL = '';
                    
        pageReference pg=page.Job_ApplicationPage;
        pg.getparameters().put('jid',jobRec.id);
        pg.setRedirect(true);
        
        if (mapVSOSiteSettings != null && mapVSOSiteSettings.containsKey('Job Opportunities'))
        {
            VSO_Site_Settings__c workVSOSiteSetting;
            workVSOSiteSetting = mapVSOSiteSettings.get('Job Opportunities');
            workTargetURL = workVSOSiteSetting.Site_URL__c;
            if  (workVSOSiteSetting.Site_Path__c != null)
            {
                workTargetURL += workVSOSiteSetting.Site_Path__c;
            }
        }
                
        workTargetURL += pg.getUrl().replace('/apex','');

        return workTargetURL;
    }
    
    //CR-450: Method to Create ContentDistribution record
    public Static String getDownloadURL(ID LatestPublishedVersionId){
        ContentVersion cv = [SELECT ID , Title, ContentDocumentID from ContentVersion 
                             where ID= :LatestPublishedVersionId];

        List<ContentDistribution> cdList = [select ID,DistributionPublicUrl ,ContentDownloadURL 
                                            from ContentDistribution 
                                            where ContentVersionId= :cv.Id 
                                            and ContentDocumentId=:cv.ContentDocumentId ];
                    if(cdList.size()>0){
                      return cdList.get(0).ContentDownloadUrl;
                    }else{
                        ContentDistribution newItem = new ContentDistribution();
                        newItem.Name = cv.Title;
                        newItem.ContentVersionId = cv.Id;
                        newItem.PreferencesAllowViewInBrowser= true;
                        newItem.PreferencesLinkLatestVersion=true;
                        newItem.PreferencesNotifyOnVisit=false;
                        newItem.PreferencesPasswordRequired=false;
                        newItem.PreferencesAllowOriginalDownload= true;
                        Insert NewItem;
                        
                        newItem = [SELECT ID,DistributionPublicUrl, ContentDownloadURL 
                                   from  ContentDistribution where ID= :newItem.Id];
                     
                        return newItem.ContentDownloadURL;
                    }
        }
        
}