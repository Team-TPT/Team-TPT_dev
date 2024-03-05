public class HRRequestTriggerHandler {
    
    public static map<id,fHCM2__HR_Request__c> EmpAndHQSet = new Map<id,fHCM2__HR_Request__c>();
        
    Public  void execute(){
        if(trigger.isBefore)
        {
            if(trigger.isInsert)
            {
              // this.TotalFundingValidation();
            }
        }
        if(trigger.isAfter)
        {
            if(trigger.isUpdate)
            {	
                List<fHCM2__HR_Request__c> hrRequestList = Trigger.new;
                for(fHCM2__HR_Request__c Hr : hrRequestList){
                    fHCM2__HR_Request__c hrMap = (fHCM2__HR_Request__c) Trigger.oldmap.get(Hr.id);
                    if(hrMap.fHCM2__Finalized_Date__c != Hr.fHCM2__Finalized_Date__c && Hr.fHCM2__Finalized_Date__c !=null && Hr.fHCM2__Finalized_Date__c.isSameDay(date.today())){
                        if(hr.E_Funding_Split_1_Percent__c != null || hr.E_Funding_Split_2_Percent__c != null || 
                            hr.E_Funding_Split_3_Percent__c != null || hr.E_Funding_Split_4_Percent__c != null ||
                            hr.E_Funding_Split_5_Percent__c != null || hr.E_Funding_Split_6_Percent__c != null ||
                            hr.E_Funding_Split_7_Percent__c != null || hr.E_Funding_Split_8_Percent__c != null ||
                            hr.E_Funding_Split_9_Percent__c != null || hr.E_Funding_Split_10_Percent__c != null ||
                            hr.E_Funding_Split_11_Percent__c != null || hr.E_Funding_Split_12_Percent__c != null ||
                            hr.E_Funding_Split_13_Percent__c != null || hr.E_Funding_Split_14_Percent__c != null ||
                            hr.E_Funding_Split_15_Percent__c != null || hr.E_Funding_Split_16_Percent__c != null ||
                            hr.E_Funding_Split_17_Percent__c != null || hr.E_Funding_Split_18_Percent__c != null ||
                            hr.E_Funding_Split_19_Percent__c != null || hr.E_Funding_Split_20_Percent__c != null){
                               EmpAndHQSet.put(hr.fHCM2__Employment__c ,Hr);
                        }
                    }
                }
            }
        }
    }
    

        public static HRRequestTriggerHandler getHandler(){
        
        if (handler == null) {
            handler = new HRRequestTriggerHandler();
        }
        
        return handler;
        
    }
    
    private static HRRequestTriggerHandler handler;
}