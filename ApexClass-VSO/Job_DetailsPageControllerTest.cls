/* * Updated By: Dinesh -TPT
   * Project Name: Refactoring Phase-2,Iteration-2
   * Created Date: (08-Aug-2016)
   * Description: Test class updated to increase the code coverage.
*/
@IsTest
public class Job_DetailsPageControllerTest {

    static testmethod void JobDetailController_Test(){
            //prepare a dummy data for Country
            Country__c cntry = TestDataClass.getCountry('TestClassCountry');
            insert cntry;
            
            vso_site_settings__c vso=new vso_site_settings__c(Name='Job Opportunities',Site_URL__c='https://tpt-vso.cs87.force.com',Site_Path__c='/jobopportunities');
            insert vso;
            
            //Job__c jb=new Job__c(Name='TestJob',Demand_Sign_Off_Date__c=null,Job_Title__c='TJ',Country__c=cntry.id,Job_Status__c='Approved for Recruitment');
            //insert jb;
            
            List<RecordType> JobRecordTypes=new List<RecordType>();
            JobRecordTypes=[select id,developername,name from RecordType where SobjectType='Job__c' AND (Developername='Employee_Job_Approved' OR Developername='Approved_Volunteer_Job' OR Developername='Corporate_Job_Approved')];
            
            Talogy_Package__c talogyPackage = new Talogy_Package__c();
            talogyPackage.Name = 'VSO Non Manager';
            talogyPackage.Package_Name__c = 'VSO Non Manager';
            talogyPackage.Accessibility__c ='Logiks & Factors+';
            talogyPackage.Package_Status__c = true;
            insert talogyPackage;
        
            //For Employee job
            Job__c jb=new Job__c(RecordTypeid=JobRecordTypes[1].id,Use_Senior_Roles_Application_Form__c  =true,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob',Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT',Country__c=cntry.id,Job_Status__c='Approved for Recruitment',Talogy_Package__c=talogyPackage.id);
            insert jb;
            
            Attachment attach=new Attachment();
            attach.Name='Test Job description VSOJD';
            attach.Body=blob.valueof('this is test job description');
            attach.ContentType='pdf';
            attach.ParentId=jb.id;
            insert attach;
            
            Pagereference pageRef =Page.Job_DetailsPage;
            //Pass the required parameters in the Url while redirecting to the Visualforce page
            // Below line to be commented for encryption
            pageRef.getParameters().put('jid', jb.Id);
            //CR-450 Dinesh changes BEGINS            
            /*String encryptedJobId = CryptoUtil.encyptData(string.valueOf(jb.Id));
            pageRef.getParameters().put('jid', encryptedJobId);*/
        	//CR-450 Dinesh changes ENDS
            // tell page its an internal job
            pageRef.getParameters().put('m', 'i');
            Test.setCurrentPageReference(pageRef);
            Apexpages.standardcontroller stdcontroller=new Apexpages.standardcontroller(new Attachment());
            Job_DetailsPageController myPageCon = new Job_DetailsPageController(stdcontroller);
            myPageCon.Applytojob();
            
            //For Corporate job
            Job__c jb1=new Job__c(RecordTypeid=JobRecordTypes[2].id,Use_Senior_Roles_Application_Form__c  =true,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob',Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT',Country__c=cntry.id,Job_Status__c='Approved for Recruitment',Talogy_Package__c=talogyPackage.id);
            insert jb1;
            
            Attachment attach1=new Attachment();
            attach1.Name='Test Job description VSOJD';
            attach1.Body=blob.valueof('this is test job description');
            attach1.ContentType='pdf';
            attach1.ParentId=jb1.id;
            insert attach1;
            
            Pagereference pageRef1 =Page.Job_DetailsPage;
            //Pass the required parameters in the Url while redirecting to the Visualforce page
            // Below line to be commented for encryption
            pageRef1.getParameters().put('jid', jb1.Id);
            //CR-450 Dinesh changes BEGINS
        	/*String encryptedJobId1 = CryptoUtil.encyptData(string.valueOf(jb1.Id));
            pageRef1.getParameters().put('jid', encryptedJobId1);*/
        	//CR-450 Dinesh changes ENDS
            Test.setCurrentPageReference(pageRef1);
            Apexpages.standardcontroller stdcontroller1=new Apexpages.standardcontroller(new Attachment());
            Job_DetailsPageController myPageCon1 = new Job_DetailsPageController(stdcontroller1);
            myPageCon1.Applytojob();
            
        
            
        
            //For Volunteer job
            Job__c jb2=new Job__c(RecordTypeid=JobRecordTypes[0].id,Use_Senior_Roles_Application_Form__c  =true,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob',Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT',Country__c=cntry.id,Job_Status__c='Approved for Recruitment',Talogy_Package__c=talogyPackage.id);
            insert jb2;
            
            Attachment attach2=new Attachment();
            attach2.Name='Test Job description VSOJD';
            attach2.Body=blob.valueof('this is test job description');
            attach2.ContentType='pdf';
            attach2.ParentId=jb2.id;
            insert attach2;
            
            Pagereference pageRef2 =Page.Job_DetailsPage;
            //Pass the required parameters in the Url while redirecting to the Visualforce page
            // Below line to be commented for encryption    
            pageRef2.getParameters().put('jid', jb2.Id);
            //CR-450 Dinesh changes BEGINS
        	/*String encryptedJobId2 = CryptoUtil.encyptData(string.valueOf(jb2.Id));
            pageRef2.getParameters().put('jid', encryptedJobId2);*/
        	//CR-450 Dinesh changes ENDS
            Test.setCurrentPageReference(pageRef2);
            Apexpages.standardcontroller stdcontroller2=new Apexpages.standardcontroller(new Attachment());
            Job_DetailsPageController myPageCon2 = new Job_DetailsPageController(stdcontroller2);
            myPageCon2.getShowHeaderandSidebar();
            myPageCon2.gettargetURL();
            myPageCon2.Applytojob();
            }
            
        static testmethod void JobDetailController_TestPageAction(){
            //prepare a dummy data for Country
            Country__c cntry = TestDataClass.getCountry('TestClassCountry');
            insert cntry;
            
            vso_site_settings__c vso=new vso_site_settings__c(Name='Job Opportunities',Site_URL__c='https://tpt-vso.cs87.force.com',Site_Path__c='/jobopportunities');
            insert vso;
            
            //Job__c jb=new Job__c(Name='TestJob',Demand_Sign_Off_Date__c=null,Job_Title__c='TJ',Country__c=cntry.id,Job_Status__c='Approved for Recruitment');
            //insert jb;
            
            List<RecordType> JobRecordTypes=new List<RecordType>();
            JobRecordTypes=[select id,developername,name from RecordType where SobjectType='Job__c' AND (Developername='Employee_Job_Approved' OR Developername='Approved_Volunteer_Job' OR Developername='Corporate_Job_Approved')];
            
            Talogy_Package__c talogyPackage = new Talogy_Package__c();
            talogyPackage.Name = 'VSO Non Manager';
            talogyPackage.Package_Name__c = 'VSO Non Manager';
            talogyPackage.Accessibility__c ='Logiks & Factors+';
            talogyPackage.Package_Status__c = true;
            insert talogyPackage;
            
            //For Employee job
            Job__c jb=new Job__c(RecordTypeid=JobRecordTypes[1].id,Use_Senior_Roles_Application_Form__c  =true,Ready_To_Publish__c=true,External_Advert_Start_Date__c=system.today()-30,External_Advert_End_Date__c=system.today()+30,Name='TestJob',Projected_Start_Date__c=system.today()+10, Demand_Sign_Off_Date__c=null,Job_Title__c='JT',Country__c=cntry.id,Job_Status__c='Approved for Recruitment',Talogy_Package__c=talogyPackage.id);
            insert jb;
            
            Attachment attach=new Attachment();
            attach.Name='Test Job description VSOJD';
            attach.Body=blob.valueof('this is test job description');
            attach.ContentType='pdf';
            attach.ParentId=jb.id;
            insert attach;
            
            //Create Document
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document VSOJD';
            cv.PathOnClient = 'Test Document VSOJD.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.FirstPublishLocationId  = userinfo.getUserId();
            //cv.IsMajorVersion = true;
            Insert cv;
 
            //Get Content Version
            List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            System.assertEquals(cvList.size(), 1);
             
            //Get Content Documents
            List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(cdList.size(), 1);
            
            /*ContentDocumentLink ContentDL = new ContentDocumentLink();
            ContentDL.ContentDocumentId = cvList[0].contentdocumentid;
        	ContentDL.LinkedEntityId = jb.id;
        	ContentDL.ShareType ='V';
            ContentDL.Visibility='AllUsers';
        	Insert ContentDL;*/
            
            Pagereference pageRef =Page.Job_DetailsPage;
            //Pass the required parameters in the Url while redirecting to the Visualforce page
            // Below line to be commented for encryption
            pageRef.getParameters().put('jid', jb.Id);
            //CR-450 Dinesh changes BEGINS
            /*String encryptedJobId = CryptoUtil.encyptData(string.valueOf(jb.Id));
            pageRef.getParameters().put('jid', encryptedJobId);*/
            //CR-450 Dinesh changes ENDS
            // tell page its an internal job
            pageRef.getParameters().put('m', 'i');
            Test.setCurrentPageReference(pageRef);
            Apexpages.standardcontroller stdcontroller=new Apexpages.standardcontroller(new Attachment());
            Job_DetailsPageController myPageCon = new Job_DetailsPageController(stdcontroller);
            
            // page action method should return null because we specified m=i in querystring
            PageReference res = myPageCon.checkRedirectPageAction();
            string str = Job_DetailsPageController.getDownloadURL(cv.Id);
            System.assertEquals(null,res, 'expecting null pagereg from page action method');
    
        }    
    }