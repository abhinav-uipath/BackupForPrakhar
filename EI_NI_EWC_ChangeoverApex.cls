public without sharing class EI_NI_EWC_ChangeoverApex {
    
    public static String newNIDAN; 
    public static String newEWCDAN; 
    public static String caseIdForMailjet;
    
    // List<Id> newTenantId;
    // Define a global list variable
    // global List<String> newTenantId;
    // Constructor to initialize the list
    // global EI_NI_EWC_ChangeoverApex() {
    // newTenantId = new List<String>();
    // }

    @AuraEnabled(cacheable=true)
    public static List<DepositAllocWrapper> getDepositDetailsForChangeover(String depositId, String scheme) 
    {
        List<DepositAllocWrapper> depositWrapperList = new List<DepositAllocWrapper>();
        DepositAllocWrapper depWrapper = new DepositAllocWrapper();
        
        if(scheme.toUpperCase().contains('NI') || scheme.toUpperCase().contains('EW')) 
        {
            List<User> userRec = [SELECT Id, AccountId, ContactId, Name, Email, ProfileId, Profile.Name FROM User 
                                  WHERE Id=:UserInfo.getUserId() LIMIT 1];
            
            List<Deposit__c > depList = [SELECT Id, Name, NI_Deposit_Number__c, Customer__c, Protected_Amount__c, Deposit_Amount__c, Final_Protected_Amount__c, 
                                         Actual_Protected_Amount__c, Start_Date__c, Change_Overamount_Sum__c, EWC_Deposit_Number__c,ChangeOver_CaseStatus__c,
                                         (Select Id, Istenantmoved__c, Tenencychangeoveramount__c, Deposit__r.Protected_Amount__c, Deposit__r.Final_Protected_Amount__c,  
                                          Deposit__r.Customer__c, Deposit_Holder__r.PersonEmail, Deposit__r.Deposit_Amount__c, 
                                          Deposit__r.Id, Deposit_Holder__c, Deposit_Holder__r.Name, Contact__c
                                          FROM Deposit_Allocations__r WHERE Role__c='Tenant') 
                                         FROM Deposit__c where Id=:depositId];
            
            List<Account> acctBankDetailsRec = new List<Account>();
            if(userRec.size()>0) {
                acctBankDetailsRec = [SELECT Id, Name, Bank_Account_Holder_Name__c, Account_Number__c, Sort_Code__c, Bank_Name__c, 
                                      ValidInternationBankDetails__c, International_Bank_Account_Holder_Name__c, BIC__c, Swift_Code__c, 
                                      IBAN__c, International_Bank_Name__c, Beneficiary_home_address__c FROM Account 
                                      WHERE Id=:userRec[0].AccountId LIMIT 1];
                depWrapper.userRec = userRec[0];
            }
            
            if(depList.size()>0) {
                depWrapper.depositRec = depList[0];
                if(depList[0].Deposit_Allocations__r.size()>0) {
                    depWrapper.depAllocList = depList[0].Deposit_Allocations__r;
                }
            }
            depWrapper.acctBankDetailsRec = acctBankDetailsRec;
        }
        
        depositWrapperList.add(depWrapper);        
        if(depositWrapperList.size()>0) {
            return depositWrapperList;
        }  
        else {
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DepositAllocWrapper> getDepositDetailsForChangeoverByAgent(String depositId, String scheme) 
    {
        List<DepositAllocWrapper> depositWrapperList = getDepositDetailsForChangeover(depositId, scheme);
        
        if(depositWrapperList.size()>0) {
            List<Case> depCaseList = [SELECT Id, Case_Statuses__c FROM Case WHERE Deposit_Account_Number__c=:depositId ORDER BY CreatedDate DESC LIMIT 1];
            depositWrapperList[0].depCaseList = depCaseList;
        }
        
        return depositWrapperList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getDepositDetailsForRespondChangeoverByTenant(String depositId, String scheme) 
    {   
        List<Case> depCaseList = [SELECT Id, Case_Statuses__c FROM Case WHERE Case_Statuses__c='Tenant changeover initiated - agent/landlord' 
                                  AND Deposit_Account_Number__c=:depositId ORDER BY CreatedDate DESC LIMIT 1];
        
        if(!depCaseList.isEmpty()) {
            return depCaseList;    
        }
        else {
            return null;
        }
    }
    
    @AuraEnabled 
    public static String getLoggedInUserAccountId() 
    {
        User tenantAccount = [Select contact.AccountId,id from user where id=: UserInfo.getUserId()];
        return tenantAccount.contact.AccountId;
    }
    
    @AuraEnabled    
    public static list<depositwrapper> getdeposittenantdetails(string depositId, string tenantChangeOver) 
    {  
        list<depositwrapper> wraplist = new list<depositwrapper>();     
        for (deposit__C deposit :([select id,name,Deposit_Amount__c,Protected_Amount__c,Start_Date__c,Number_of_Tenants__c,Scheme__c,Property__c,Property_Address__c from deposit__C where id=:depositId])) 
        {   
            wraplist.add(new depositwrapper(deposit));  
        }   
        if(tenantChangeOver == 'true'){ 
            for (Deposit_Allocation__c depall : ([select id,Deposit__c,Tenencychangeoveramount__c, Istenantmoved__c,Role__c,Is_Lead__c, Deposit_Holder__c,Deposit_Holder__r.Id,Deposit_Holder__r.Salutation,Deposit_Holder__r.FirstName, Deposit_Holder__r.LastName, Deposit_Holder__r.Name, Deposit_Holder__r.PersonEmail, Deposit_Holder__r.Phone,Deposit_Holder__r.PersonMailingStreet,Deposit_Holder__r.PersonMailingCity,Deposit_Holder__r.PersonMailingCountry,Deposit_Holder__r.PersonMailingPostalCode from Deposit_Allocation__c where Deposit__c=:depositId and Role__c='Tenant' and Istenantmoved__c = true]))   
            {   
                wraplist.add(new depositwrapper(depall));   
            }   
        }else{  
            for (Deposit_Allocation__c depall : ([select id,Deposit__c,Tenencychangeoveramount__c, Istenantmoved__c,Role__c,Is_Lead__c, Deposit_Holder__c,Deposit_Holder__r.Id,Deposit_Holder__r.Salutation,Deposit_Holder__r.FirstName, Deposit_Holder__r.LastName, Deposit_Holder__r.Name, Deposit_Holder__r.PersonEmail, Deposit_Holder__r.Phone,Deposit_Holder__r.PersonMailingStreet,Deposit_Holder__r.PersonMailingCity,Deposit_Holder__r.PersonMailingCountry,Deposit_Holder__r.PersonMailingPostalCode from Deposit_Allocation__c where Deposit__c=:depositId and Role__c='Tenant']))   
            {   
                wraplist.add(new depositwrapper(depall));   
            }   
        }   
        
        return  wraplist;   
    }
    
    // NN-57 and EN-33 Tenant Initiate Changeover
    @AuraEnabled(cacheable=false)
    public static String submitTenantInitiatedChangeover(String depositId, String depoAllocList, String scheme) 
    {
        List<User> loggedInUser = [SELECT Id, Name, ContactId, Contact.AccountId, AccountId FROM User WHERE Id=: Userinfo.getUserId() LIMIT 1];
        List<Deposit_Allocation__c> depositAllocationList = [SELECT Deposit__r.Customer__c, Deposit__r.Customer__r.Email__c, Deposit__r.Branch__c,Deposit__r.Customer__r.Name,Deposit__r.Customer__r.Id, Deposit_Holder__r.PersonEmail, Istenantmoved__c, 
                                                             Deposit__r.Deposit_Amount__c, Deposit__r.Id, Deposit_Holder__r.Name, Tenencychangeoveramount__c, Role__c, 
                                                             Deposit__r.Property_Address__c,Deposit__r.NI_Deposit_Number__c,Deposit__r.EWC_Deposit_Number__c,Deposit__r.Contact__r.Name,Deposit__r.Contact__r.Email,Deposit__r.First_line_of_address_with_postcode__c
                                                             FROM Deposit_Allocation__c WHERE Deposit__c=:depositId /* AND Role__c='Tenant' */];
        
        List<Deposit_Allocation__c> depAllocToUpdateList = updateMovedTenantOnDepAllocation(depoAllocList, depositAllocationList);
        String BranchId = '';
        Deposit__c deprec = [Select id, Branch__c FROM Deposit__c WHERE Id =:depositId];
        if(deprec != null && deprec.Branch__c != null && !String.isBlank(deprec.Branch__c)){
            BranchId = deprec.Branch__c;
        }
        try {
            if(!depAllocToUpdateList.isempty()) {
                update depAllocToUpdateList;
                
                // Creating case
                String caseStatus = createCaseOnChangeOver(depositId, loggedInUser, 'tenant', scheme, BranchId);
                
                // Updating deposit
                Deposit__c updateDeposit = new Deposit__c(Id=depositId, 
                                                          Tenant_Changeover_Status__c='In Progress', 
                                                          ChangeOver_CaseStatus__c=caseStatus);
                update updateDeposit;
                
                /* 
** Mailjet code END 
*/
                List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();

                // NN-57 AC-5
                if(scheme.toUpperCase().contains('NI')) {
                    String toName;
                    String toaddress;
                    String toAddressTT;
                    String tenantName;
                    String address ;
                    String dan;
                    string firstLineAdd;
                    String toBranch;
                    address=depositAllocationList[0].Deposit__r.Property_Address__c;
                    dan=depositAllocationList[0].Deposit__r.NI_Deposit_Number__c;
                    firstLineAdd=depositAllocationList[0].Deposit__r.First_line_of_address_with_postcode__c;
                    List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                    List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                    //   System.debug('branchcheck' +depositAllocationList[0].Deposit__r.Branch__c);
                    if (deprec.Branch__c != null) {
                        toAddress = branchEmailMailjet(deprec.Branch__c);
                    }
                    else {
                        toAddress = depositAllocationList[0].Deposit__r.Customer__r.Email__c;
                        }
                    
                        toName = depositAllocationList[0].Deposit__r.Customer__r.Name;
                    
                    
                    emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, caseIdForMailjet,depositAllocationList[0].Deposit__r.Customer__c,''));   
                    Map<String, String> variableMap = new Map<String, String>();
                    variableMap.put('user_name',toName);
                    variableMap.put('property_address',address);
                    variableMap.put('DAN',dan); 
                    
                    emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                            'NN57AC5ChangeoverMailAgLL', 'Tenant Changeover initiated by tenant - '+ address)); 
                    
                    for(Deposit_Allocation__c depAll :[select id,contact__c,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                       where deposit__c=:depositId ]){
                                                           toAddressTT = depAll.Contact__r.Email;
                                                           tenantName =  depAll.Contact__r.Name;
                                                           
                                                           List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                                           
                                                           String email ;
                                                           if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                               email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                           }
                                                           if(email!=null){
                                                               emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id));       
                                                           }
                                                           if(toAddressTT!=null){
                                                               emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id)); 
                                                           }if(email==null && toAddressTT==null){
                                                               emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id));       
                                                           }        
                                                           Map<String, String> variableMap1 = new Map<String, String>();
                                                           variableMap1.put('user_name',tenantName);
                                                           variableMap1.put('property_address',address);
                                                           variableMap1.put('DAN',dan); 
                                                           
                                                           if(depAll.Istenantmoved__c){
                                                               emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                       'NN57AC5ChangeoverOutgoingTT', 'Tenant Changeover initiated - ' + firstLineAdd));
                                                           }else{
                                                               emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                       'NN57AC5ChangeoverRemainingTT', 'Tenant Changeover initiated - ' + firstLineAdd));
                                                           }
                                                           
                                                           
                                                           
                                                       }
                } 
                
                /*else if(scheme.toUpperCase().contains('EW')) {
                    String toName;
                    String toaddress;
                    String toAddressTT;
                    String tenantName;
                    String address ;
                    String dan;
                    string firstLineAdd;
                    address=depositAllocationList[0].Deposit__r.Property_Address__c;
                    dan=depositAllocationList[0].Deposit__r.EWC_Deposit_Number__c;
                    firstLineAdd=depositAllocationList[0].Deposit__r.First_line_of_address_with_postcode__c;
                    String outgoingTenant='';
                    String selfRegister;
                    selfRegister = '<a href="'+System.Label.LoginPage+'">here</a>';
                    

                    List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                    List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                    
                    if (depositAllocationList[0].Deposit__r.Branch__c != null){
                        
                        toAddress = branchEmailMailjet(depositAllocationList[0].Deposit__r.Branch__c);
                    }
                    else{
                        toAddress = depositAllocationList[0].Deposit__r.Customer__r.Email__c;
                        }
                    
                        toName = depositAllocationList[0].Deposit__r.Customer__r.Name;
                    
                    
                    emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, depositId,depositAllocationList[0].Deposit__r.Customer__c,''));   
                    Map<String, String> variableMap = new Map<String, String>();
                    variableMap.put('Reciepient_Name',toName);
                    variableMap.put('Tenancy_Address',address);
                    variableMap.put('Payment_reference',dan); 
                    variableMap.put('Reg_link',selfRegister); 
                    
                    emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                            'TC_TT_raised_AA_LL_to_respond_AA_LL', 'Tenant changeover initiated by tenant – '+ address)); 
                    System.debug('Line no 233'+emailWrapperListEWC);
                    //For table 
                    outgoingTenant += '<table>';
                    List<Deposit_Allocation__c> newdepoAllocLIst = [select id,Istenantmoved__c,Tenencychangeoveramount__c,Contact__r.Name from Deposit_Allocation__c 
                    where deposit__c=:depositId ];
                    for(integer i=0; i< newdepoAllocLIst.size(); i++){   
                        Deposit_Allocation__c depAll =  newdepoAllocLIst[i];                                                          
                                                                   if(depAll.Istenantmoved__c){
                                                                    System.debug('depAll'+depAll);
                                                                    if(i==0){
                                                                        outgoingTenant += '<tr>';
                                                                        outgoingTenant += '<td> Number of tenant(s) <td>';
                                                                        outgoingTenant += '<td>'+ depAll.Contact__r.Name +'<td>';
                                                                        outgoingTenant += '</tr>';
                                                                       }else{
                                                                       outgoingTenant += '<tr>';
                                                                       outgoingTenant += '<td></td>';
                                                                       outgoingTenant += '<td></td>';
                                                                       outgoingTenant += '<td>'+ depAll.Contact__r.Name +'<td>';
                                                                       outgoingTenant += '</tr>';
                                                                         }                                             
                                                                       
                                                                   }
                                                               }
                    outgoingTenant += '</table>'; 

                    for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                       where deposit__c=:depositId ]){
                                                           toAddressTT = depAll.Contact__r.Email;
                                                           tenantName =  depAll.Contact__r.Name;
                                                           
                                                           List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                                                           
                                                           String email ;
                                                           if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                               email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                           }
                                                           if(email!=null){
                                                               emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depositId,depositAllocationList[0].Deposit__r.Customer__c,''));       
                                                           }
                                                           if(toAddressTT!=null){
                                                               emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depositId,depositAllocationList[0].Deposit__r.Customer__c,'')); 
                                                           }        
                                                           Map<String, String> variableMap1 = new Map<String, String>();
                                                           variableMap1.put('user_name',tenantName);
                                                           variableMap1.put('Tenancy_Address',address);
                                                           variableMap1.put('Payment_reference',dan);
                                                           //Table
                                                           variableMap1.put('TenantMovingOut',outgoingTenant);
                                                           System.debug('Line No 272 email');
                                                           System.debug('Line No 273 toAddressTT '+toAddressTT);
                                                           System.debug('Line No 274 tenantName '+tenantName);
                                                           
                                                           if(depAll.Istenantmoved__c){
                                                               emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                                                       'TC_TT_raised_conf_to_outgoing_TT', 'Tenant changeover initiated by tenant – ' + address));
                                                           }else{
                                                               emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                                                       'TC_TT_raised_conf_to_remaining_TTs', 'Tenant changeover initiated by tenant – ' + address));
                                                           }
                                                           
                                                       }
                } 
                */
             //   System.debug('Line no 284'+emailWrapperListEWC);
                if(emailWrapperList.size()>0) {
                    EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                }

                if(emailWrapperListEWC.size()>0) {
                    //      System.debug('Line no 292'+emailWrapperListEWC);
                    EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                }
                /* 
** Mailjet code END 
*/
                
            }
        }
        catch(Exception e) {
            System.debug('Line 86 error -> '+String.valueOf(e.getMessage()));
            return 'Error '+String.ValueOf(e.getMessage());
        }
        return 'Success'; 
    }
    
    // Agent raises or responds to changeover when no new tenant is moving in
    // SDS method -> createnewdeposit
    @AuraEnabled
    public static String submitAgllChangeoverWithNoNewTenants(String depositId, String depoAllocList, Decimal newdepositamount, 
                                                              Integer newtenantsnumber, Date newdepositstartdate,Date newdepositenddate, 
                                                              String changeoverInitiatedBy, String scheme) 
    {
//   system.debug('line 361');
        String message = '';
        List<User> loggedInUser = [SELECT Id, Name, ContactId, Contact.AccountId, AccountId FROM User WHERE Id=: Userinfo.getUserId() LIMIT 1];
        List<Deposit_Allocation__c> depositAllocationList = [SELECT Deposit_Holder__c,Deposit_Holder__r.Email__c, Deposit_Holder__r.PersonEmail,Deposit__r.Customer__c,Deposit__r.Contact__r.Name,Deposit__r.Contact__r.Email,Deposit__r.End_Date__c,
                                                             Istenantmoved__c,Deposit__r.Deposit_Amount__c,Deposit__r.Property_Address__c,Deposit__r.NI_Deposit_Number__c,Deposit__r.EWC_Deposit_Number__c,Deposit__r.Id,Deposit__r.First_line_of_address_with_postcode__c,
                                                             Deposit_Holder__r.Name,Deposit_Holder__r.Additional_Email__c,Contact__c,Contact__r.Email,Contact__r.Name, Deposit__r.Branch__c ,Tenencychangeoveramount__c, Is_Lead__c, Role__c, 
                                                             Deposit__r.Customer__r.Email__c, Deposit__r.Customer__r.Name
                                                             FROM Deposit_Allocation__c WHERE Deposit__c=:depositId /* AND Role__c='Tenant'*/];
        
        List<Deposit_Allocation__c> depAllocToUpdateList = new List<Deposit_Allocation__c>();
        
        if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
            depAllocToUpdateList = updateMovedTenantOnDepAllocation(depoAllocList, depositAllocationList);
        } 
        else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
            depAllocToUpdateList = depositAllocationList;
        }
        
        // System.debug('Line 165 -> '+depAllocToUpdateList);
        String BranchId = '';
        Deposit__c deprec = [Select id, Branch__c FROM Deposit__c WHERE Id =:depositId];
        if(deprec != null && deprec.Branch__c != null && !String.isBlank(deprec.Branch__c)){
            BranchId = deprec.Branch__c;
        }
        else{
            BranchId = null;
        }
        System.debug('Line 359 -> '+BranchId);
        //try {
            if(depAllocToUpdateList.size()>0) {
                update depAllocToUpdateList;
                
                message = createNewDeposit(depositId, '', new List<Account>(), newdepositamount, newtenantsnumber, newdepositstartdate, newdepositenddate,
                                           depAllocToUpdateList, changeoverInitiatedBy, scheme);
                
                if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
                    // Creating case           
                    String caseStatus = createCaseOnChangeOver(depositId, loggedInUser, 'agll', scheme, BranchId);
                  
                    /* 
** Mailjet code START 
*/
                    User usrRec = [SELECT Id, Name,Profile.Name, Account.Email__c, Account.Name, Contact.Email,Contact.Name,AccountId, ContactId, User_Type__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
                    List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                    List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();
                    String address ;
                    String dan;
                    String toName;
                    String toaddress;
                    String toAddressTT;
                    String tenantName;
                    String firstLineAdd;
                    // NN-58 AC-6
                    if(scheme.toUpperCase().contains('NI')) {
                        dan=depAllocToUpdateList[0].Deposit__r.NI_Deposit_Number__c;
                        address=depAllocToUpdateList[0].Deposit__r.Property_Address__c;
                        firstLineAdd=depositAllocationList[0].Deposit__r.First_line_of_address_with_postcode__c;
                        
                        system.debug('line 416'+BranchId);
                        
                        if(usrRec.Profile.Name=='NI_Agent' || usrRec.Profile.Name == 'NI_Landlord' || usrRec.Profile.Name == 'NI_Head_Office_User' || usrRec.Profile.Name == 'NI_ Branch Users'){
                               toName = usrRec.Account.Name;
                            if(BranchId != null){
                               toAddress = branchEmailMailjet(depositAllocationList[0].Deposit__r.Branch__c); 
                            } else {
                                toAddress = usrRec.Account.Email__c;
                            }
                                
                            
                            system.debug('line 419'+depositAllocationList[0].Deposit__r.Branch__c);
                            
                            List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                           
                            emailRecipientList.add(new EI_MailJetUtility.recipient(toAddress, toName, caseIdForMailjet,depAllocToUpdateList[0].Deposit__r.Customer__c,''));   
                                                                                 
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('user_name',toName);
                            variableMap.put('property_address',address);
                            variableMap.put('DAN',dan); 
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                                    'NN58AC6ChangeoverConfirmAgLL', 'Tenant changeover initiated - '+ firstLineAdd)); 
                        }
                        
                        for(Deposit_Allocation__c depAll :depAllocToUpdateList){
                            if(depAll.Istenantmoved__c){
                                toAddressTT = depAll.Contact__r.Email;
                                tenantName =  depAll.Contact__r.Name;
                                
                                List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                
                                String email;
                                if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                    email = depAll.Deposit_Holder__r.Additional_Email__c;
                                }
                                if(email!=null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id));       
                                }
                                if(toAddressTT!=null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id)); 
                                }if(email==null && toAddressTT==null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id)); 
                                }          
                                Map<String, String> variableMap = new Map<String, String>();
                                variableMap.put('user_name',tenantName);
                                variableMap.put('property_address',address);
                                variableMap.put('DAN',dan); 
                                
                                emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                                        'NN58AC6ChangeoverConfirmVacatingTT', 'Please confirm you have moved out - ' + address)); 
                            }
                            
                        }
                    } 
                     
                 /*   else if(scheme.toUpperCase().contains('EW')) {
                        dan=depAllocToUpdateList[0].Deposit__r.EWC_Deposit_Number__c;
                        address=depAllocToUpdateList[0].Deposit__r.Property_Address__c;
                        if(usrRec.Profile.Name=='EWC Agent' || usrRec.Profile.Name == 'EWC Landlord' ||  usrRec.Profile.Name == 'EWC Head Office User' ||  usrRec.Profile.Name == 'EWC Branch User'){
                            if(BranchId != null){
                               toAddress = branchEmailMailjet(depositAllocationList[0].Deposit__r.Branch__c); 
                            }
                            else{
                            toAddress = usrRec.Account.Email__c;
                            }
                            toName = usrRec.Account.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddress, toName, depAllocToUpdateList[0].Deposit__r.Id,depAllocToUpdateList[0].Deposit__r.Customer__c,''));   
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('Reciepient_Name',toName);
                            variableMap.put('Tenancy_Address',address);
                            variableMap.put('Payment_reference',dan); 
                            
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap, 
                                                                                    'TC_AA_LL_raised_TT_to_respond_AA_LL', 'Tenant changeover initiated by agent/landlord – '+ address)); 
                        }
                        
                        

                        for(Deposit_Allocation__c depAll :depAllocToUpdateList){
                            if(depAll.Istenantmoved__c){
                                toAddressTT = depAll.Contact__r.Email;
                                tenantName =  depAll.Contact__r.Name;
                                
                                List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                                
                                String email ;
                                if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                    email = depAll.Deposit_Holder__r.Additional_Email__c;
                                }
                                if(email!=null){
                                    emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,''));       
                                }
                                if(toAddressTT!=null){
                                    emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,'')); 
                                }        

                                Map<String, String> variableMap = new Map<String, String>();
                                String selfRegister = '<a href="'+System.Label.LoginPage+'">here</a>';
                                variableMap.put('user_name', tenantName);
                                variableMap.put('Tenancy_Address', address);
                                variableMap.put('Payment_reference', dan);
                                variableMap.put('Reg_link', selfRegister);

                                
                                // Query Case records to get the Respond_Date__c field value
                                 List<Case> cases = [SELECT Id, Respond_Date__c FROM Case WHERE Deposit_Account_Number__c=:depositId];
                                 System.debug('Line no 999 cases'+cases);
                                 System.debug('Line no 1000 depositId'+depositId);
                                 // Assuming you have the Case records and you want to retrieve the first one
                                if (!cases.isEmpty()) {
                                    System.debug('cases line no 998' + cases);
                                    Case caseRecord = cases[0];
                                    Date respondDate = caseRecord.Respond_Date__c;
                                    System.debug('respondDate line no 1001' + respondDate);
                                
                                    // Add 14 days to the Respond Date
                                   // Date fourteenWorkingDate = respondDate.addDays(14);
                                    Date fourteenWorkingDate = respondDate;

                                    // Convert the date to a string representation in dd/MM/yyyy format
                                    Datetime fourteenWorkingDatetime = Datetime.newInstance(fourteenWorkingDate.year(), fourteenWorkingDate.month(), fourteenWorkingDate.day());
                                    String fourteenWorkingDateString = fourteenWorkingDatetime.format('dd/MM/yyyy');
                                    System.debug('fourteenWorkingDateString line no 998' + fourteenWorkingDateString);
                                    variableMap.put('fourteen_working_date', fourteenWorkingDateString);
                                }
                                
 
                                emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap, 
                                                                                        'TC_AA_LL_raised_TT_to_respond_TT', 'Tenant changeover initiated by agent/landlord –' + address)); 
                                System.debug('variableMap line no 1013'+variableMap);
                            }
                            
                        }
                    } 
                   */ 
                    
                    if(emailWrapperList.size()>0) {
                        EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                    }
                    if(emailWrapperListEWC.size()>0) {
                        EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                    }
                    /* 
** Mailjet code END 
*/
                } 
                else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
                    System.debug('Line 200 -> ');
                    // Updating case
                    List<Case> updateCaseList = new List<Case>();
                    for(Case changeOverCase : [Select Id, Case_Statuses__c, ChangeOver_Status__c FROM Case WHERE Deposit_Account_Number__c=:depositId 
                                               AND Case_Statuses__c='Tenant changeover initiated - tenant' ORDER BY LastModifiedDate DESC LIMIT 1])        
                    {
                        changeOverCase.Case_Statuses__c = 'Tenant changeover accepted';
                        changeOverCase.ChangeOver_Status__c = 'Agent Approved';
                        updateCaseList.add(changeOverCase);
                    }
                    System.debug('Line 209 -> '+updateCaseList);
                    if(updateCaseList.size()>0) {
                        update updateCaseList;
                    }
                    // Creating installments for moving tenants and for the remaining deposit amount on new and old deposit 
                    acceptChangeover(depositId, updateCaseList[0].Id, true, scheme);
                    Set<Id> depoIDListForDPC = new Set<Id>();
                    depoIDListForDPC.add(Id.ValueOf(depositId));
                    Database.executeBatch(new EI_EWC_DPC_reserveSendEmail_Batch(depoIDListForDPC), 150); // EN-109
                    
                    /* 
** Mailjet code START 
*/
                    List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                    
                    // NN-57 AC-14
                    
                    
                    if(scheme.toUpperCase().contains('NI')) {
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        String address ;
                        String dan;
                        String remainingTT;
                        String outgoingTT;
                        String agLLName;
                        
                        address=depositAllocationList[0].Deposit__r.Property_Address__c;
                        dan=depositAllocationList[0].Deposit__r.NI_Deposit_Number__c;
                        agLLName = depositAllocationList[0].Deposit__r.Contact__r.Name;
                        // table creation loop
                        outgoingTT = '<table>';
                        
                        outgoingTT += '<tr>';
                        outgoingTT+=  '<th><b>Tenant(s) moving out</b>:</th>';
                       
                        remainingTT = '<table>';
                        remainingTT += '<tr>';
                        remainingTT+=  '<th><b>Remaining tenant(s)</b>:</th>';
                        id niCaseId=[select id from case where Deposit_Account_Number__c=:depositId].id;
                        for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Tenencychangeoveramount__c,Contact__r.Name from Deposit_Allocation__c 
                                                           where deposit__c=:depositId ]){                                                               
                                                               if(depAll.Istenantmoved__c){
                                                                   
                                                                  // outgoingTT += '<tr>';
                                                                   outgoingTT += '<td>'+ depAll.Contact__r.Name +'<td>' +'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
                                                                   outgoingTT += '<td>'+'Amount due:£'+ String.valueOf((depAll.Tenencychangeoveramount__c.setScale(2))) +'<td> <br>';
                                                                   outgoingTT += '</tr>';                                                  
                                                                   
                                                               }else{
                                                                  
                                                                  // remainingTT += '<tr>';
                                                                   remainingTT += '<td>'+ depAll.Contact__r.Name +'<td> <br>';
                                                                   remainingTT += '</tr>';
                                                                   
                                                               }
                                                               
                                                           }
                        outgoingTT += '</table><br/><br/>';
                        remainingTT += '</table><br/><br/>';
                        
                        List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                        for(Deposit_Allocation__c depAll :[select id,contact__c,Istenantmoved__c,Tenencychangeoveramount__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                           where deposit__c=:depositId ]){
                                                               toAddressTT = depAll.Contact__r.Email;
                                                               tenantName =  depAll.Contact__r.Name;
                                                              
                                                               List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                                               
                                                               String email ;
                                                               if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                                   email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                               }
                                                               if(email!=null){
                                                                   emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, niCaseId,depAll.Contact__c,depAll.Id));       
                                                               }
                                                               if(toAddressTT!=null){
                                                                   emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, niCaseId,depAll.Contact__c,depAll.Id)); 
                                                               }if(email==null && toAddressTT==null){
                                                                   emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, niCaseId,depAll.Contact__c,depAll.Id)); 
                                                               }        
                                                               Map<String, String> variableMap1 = new Map<String, String>();
                                                               variableMap1.put('user_name',tenantName);
                                                               variableMap1.put('property_address',address);
                                                               variableMap1.put('DAN',dan);
                                                               variableMap1.put('outgoing_tenant',outgoingTT);
                                                               variableMap1.put('remaining_tenant',remainingTT);
                                                               variableMap1.put('new_DAN',newNIDAN);
                                                               variableMap1.put('agll_name',agLLName);
                                                               
                                                               if(depAll.Istenantmoved__c){
                                                                   emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                           'NN57AC14ChangeoverAcceptOutgoingTT', 'Tenant changeover accepted - ' + address));
                                                               }else{
                                                                   emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                           'NN57AC14ChangeoverAcceptRemainingTT', 'Tenant changeover accepted - ' + address));
                                                               }
                                                               
                                                               
                                                               
                                                           }
                        
                        toAddress = depositAllocationList[0].Deposit__r.Customer__r.Email__c;
                        toName = depositAllocationList[0].Deposit__r.Customer__r.Name;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                        emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, niCaseId,depositAllocationList[0].Deposit__r.Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('user_name',toName);
                        variableMap.put('property_address',address);
                        variableMap.put('DAN',dan); 
                        variableMap.put('outgoing_tenant',outgoingTT);
                        variableMap.put('remaining_tenant',remainingTT);
                        variableMap.put('new_DAN',newNIDAN);
                        variableMap.put('agll_name',agLLName);
                        
                        emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                'NN57AC14ChangeoverAcceptAgLL', 'Tenant changeover accepted - '+ address)); 
                        
                        
                    } 
                    
                    if(emailWrapperList.size()>0) {
                        EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                    }
                    /* 
** Mailjet code END 
*/
                }
                return 'Success';
            }
            return 'Something went wrong';
       /*}
       catch(Exception e) {
           System.debug('Line 510 error -> '+String.valueOf(e.getMessage() + e.getLineNumber()));
           return 'Error '+String.ValueOf(e.getMessage()+ e.getLineNumber());
        } */
    }
    
    // Agent raises or responds to changeover when existing deposit is selected from the system
    // SDS Method -> changeoverrequest2
    public static String submitAgllChangeoverForSelectedDepositOld(String depositid, String Depolist, String selecteddeposit, String tenantChange) 
    {
        String DAN;
        Map<String,String> emailMembername = new Map<String,String>();
        Map<String,String> tenentAmount = new Map<String,String>();                                        
        List<String> emailDetails = new List<String>();    
        
        String message = 'Changeover request initiated';   
        List<Deposit_Allocation__c> depalllist = (List<Deposit_Allocation__c>) System.JSON.deserialize(Depolist, List<Deposit_Allocation__c>.class);
        // System.debug('line-->139' + depalllist);
        List<deposit__c> selecteddepositlist = (List<deposit__c>) System.JSON.deserialize(selecteddeposit, List<deposit__c>.class);  
        // System.debug('line-->141' + selecteddepositlist);
        List<Deposit_Allocation__c> depall = [select id,Is_Lead__c,Deposit__c,deposit_holder__r.name,deposit_holder__c,Role__c  from Deposit_Allocation__c where id not in:depalllist and  Deposit__c=:depositid and Role__c='Tenant'];  
        deposit__c deplist = [select id,Property__c,Deposit_Account_Number__c,Customer__c,Customer__r.name,Scheme__C,Status__c from Deposit__c where id=:depositid ];
        // System.debug('line-->143' + depall);
        // List<deposit__c> olddepositlist = [select id,Status__c from deposit__c where id=:depositid limit 1];
        // System.debug('line-->145' + olddepositlist);
        if(selecteddepositlist.size()>0 && depall.size()>0 ||Test.isRunningTest()) {
            List<Deposit_Allocation__c> newdepll = new List<Deposit_Allocation__c>();
            for(Deposit_Allocation__c dap :depall) {
                Deposit_Allocation__c putdepall = new Deposit_Allocation__c();
                putdepall.Deposit_Holder__c=dap.Deposit_Holder__c;
                putdepall.Is_Lead__c = dap.Is_Lead__c;
                putdepall.Deposit__c=selecteddepositlist[0].id;
                DAN =selecteddepositlist[0].Deposit_Account_Number__c;
                putdepall.Role__c ='Tenant';
                newdepll.add(putdepall);
            }
            insert newdepll;
        }
        
        if(depalllist.size()>0 && depositid!=null) {
            List<Deposit_Allocation__c> updatedlist = new List<Deposit_Allocation__c>();    
            for(Deposit_Allocation__c dac : depalllist) {
                Deposit_Allocation__c dact = new  Deposit_Allocation__c();
                dact.id = dac.id;
                dact.Istenantmoved__c=true;
                emailDetails.add(dac.Deposit_Holder__r.Name);
                emailMembername.put(dac.Deposit_Holder__r.Name,dac.Deposit_Holder__r.PersonEmail);
                if(dac.Tenencychangeoveramount__c !=null) {
                    dact.Tenencychangeoveramount__c=dac.Tenencychangeoveramount__c;    
                    tenentAmount.put(dac.Deposit_Holder__r.Name,String.valueOf(dac.Tenencychangeoveramount__c));
                    
                } else {
                    if(tenantChange == 'true') {
                        
                    } else {
                        dact.Tenencychangeoveramount__c=0; 
                    }
                }
                updatedlist.add(dact);   
            }   
            update updatedlist;
        }
        
        if(depositid !=null) {
            Deposit__c olddeposit = new  Deposit__c();
            olddeposit.id=depositid;
            olddeposit.Tenant_Changeover_Deposit__c=selecteddepositlist[0].id;
            olddeposit.Tenant_Changeover_Status__c='In Progress';   
            
            update olddeposit;                                        
        }
        if(tenantChange == 'true') {
            // AGLLagreeTTrequesremaildetails(depositid,depalllist);
            //  MailJetService.mailTenantToAcceptChangeOver(emailMembername,emailDetails,tenentAmount,DAN); 
            
        } else {
            // User us = [select id,accountid,contactid from user where accountid=:deplist.Customer__c];
            id caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Label.Support_Case).getRecordTypeId();
            Case newCase = new Case(AccountId = deplist.Customer__c,RecordTypeId = caseRecordType, 
                                    ChangeOver_Status__c = 'Agent Initiate', 
                                    Deposit_Account_Number__c = depositId,OwnerId = UserInfo.getUserId() ,Origin= 'Web', 
                                    Status='Tenant changeover initiated - agent/landlord',Scheme__c='EW Custodial',Subject = 'Tenant Changeover requested by '+UserInfo.getUserName(),Description=UserInfo.getUserName()+' has initiated Tenant Change Over');
            insert newCase;
            //System.debug('Line 606 newCase '+newCase);
            // tenancyinitiatedemaildetails(depositid,depalllist);
        }
        
        List<Case> caseList = new List<Case>();
        for(Case changeOverCase : [Select id,Status,ChangeOver_Status__c from Case where Deposit_Account_Number__c =: depositid and 
                                   Status = 'Tenant changeover initiated - tenant' and ChangeOver_Status__c = 'Tenant Initiate'])        
        {
            changeOverCase.ChangeOver_Status__c = 'Agent Approved';
            caseList.add(changeOverCase);
        }
        update caseList;
        if(tenantChange == 'true') {
            return 'Changeover Approved Successfully='+depositid;
            
        } else {
            return message;
        }
    }
    
    @AuraEnabled
    public static String submitAgllChangeoverForSelectedDeposit(String depositId, String depoAllocList, String selectedDeposit, 
                                                                Decimal newdepositamount, Integer newtenantsnumber, Date newdepositstartdate, 
                                                                String changeoverInitiatedBy, String scheme) 
    {
        EI_NI_utility.flagForCaseEmails = true;
        String message = '';
        List<User> loggedInUser = [SELECT Id, Name, ContactId, Contact.AccountId, AccountId FROM User WHERE Id=: Userinfo.getUserId() LIMIT 1];
        List<Deposit_Allocation__c> depositAllocationList = [SELECT Deposit_Holder__c,Deposit__r.Customer__c, Deposit_Holder__r.PersonEmail, 
                                                             Istenantmoved__c, Deposit__r.Deposit_Amount__c, Deposit__r.Id, Deposit_Holder__r.Name, 
                                                             Contact__c, Tenencychangeoveramount__c, Is_Lead__c,Role__c  
                                                             FROM Deposit_Allocation__c WHERE Deposit__c=:depositId /*AND Role__c='Tenant'*/];
        List<Deposit_Allocation__c> depAllocToUpdateList = new List<Deposit_Allocation__c>();
        // system.debug('depoAllocList' + depoAllocList);
        if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
            depAllocToUpdateList = updateMovedTenantOnDepAllocation(depoAllocList, depositAllocationList);
        } 
        else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
            depAllocToUpdateList = updateMovedTenantOnDepAllocation(depoAllocList, depositAllocationList);
        }
        
        //  System.debug('Line 165 -> '+depAllocToUpdateList);
        String BranchId = '';
        Deposit__c deprec = [Select id, Branch__c FROM Deposit__c WHERE Id =:depositId];
        if(deprec != null && deprec.Branch__c != null && !String.isBlank(deprec.Branch__c)){
            BranchId = deprec.Branch__c;
        }
       // try {
            if(depAllocToUpdateList.size()>0) {
                update depAllocToUpdateList;
               //  Map<String, Object> depositMap = (Map<String, Object>) JSON.deserializeUntyped(selectedDeposit);
                // Extract the Id value from the Map
               // String idValue = (String)depositMap.get('Id');
                 message = createNewDeposit(depositId, selectedDeposit, new List<Account>(), newdepositamount, newtenantsnumber, newdepositstartdate, null,
                                            depAllocToUpdateList, changeoverInitiatedBy, scheme);
                
                if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
                    // Creating case
                    String caseStatus = createCaseOnChangeOver(depositId, loggedInUser, 'agll', scheme, BranchId);
                } 
                else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
                    // Updating case
                    List<Case> updateCaseList = new List<Case>();
                    for(Case changeOverCase : [Select Id, Case_Statuses__c, ChangeOver_Status__c FROM Case WHERE Deposit_Account_Number__c=:depositId 
                                               AND Case_Statuses__c='Tenant changeover initiated - tenant' ORDER BY LastModifiedDate DESC LIMIT 1])        
                    {
                        changeOverCase.Case_Statuses__c = 'Tenant changeover accepted';
                        changeOverCase.ChangeOver_Status__c = 'Agent Approved';
                        updateCaseList.add(changeOverCase);
                    }
                    if(updateCaseList.size()>0) {
                        update updateCaseList;
                    }
                    // Creating installments for moving tenants and for the remaining deposit amount on new and old deposit 
                    acceptChangeover(depositId, updateCaseList[0].Id, true, scheme);
                    Set<Id> depoIDListForDPC = new Set<Id>();
                    depoIDListForDPC.add(Id.ValueOf(depositId));
                    Database.executeBatch(new EI_EWC_DPC_reserveSendEmail_Batch(depoIDListForDPC), 150); // EN-109
                    
                }
                return 'Success';
            }
            return 'Something went wrong';
       /* }
        catch(Exception e) {
            System.debug('Line 510 error -> '+String.valueOf(e.getMessage() + e.getLineNumber()));
            return 'Error '+String.ValueOf(e.getMessage());
        }*/
    }
    
    // Agll raises or responds to changeover when new tenant(s) are moving in
    @AuraEnabled
    public static String submitAgllChangeoverWithNewTenants(String depositId, String depoAllocList, String newtenantlist, 
                                                            Decimal newdepositamount, Integer newtenantsnumber, Date newdepositstartdate, Date newdepositenddate,
                                                            String changeoverInitiatedBy, String scheme) 
    {
        EI_NI_utility.flagForCaseEmails = true;
        String DAN;
        List<User> loggedInUser = [SELECT Id, Name, Account.Email__c, Account.Name, ContactId, Contact.AccountId, AccountId, Account.OwnerId,
                                   Profile.Name, Contact.Email,Contact.Name, User_Type__c
                                   FROM User WHERE Id=: Userinfo.getUserId() LIMIT 1];
        List<Deposit_Allocation__c> depositAllocationList = [SELECT Deposit_Holder__c,Deposit__r.Branch__c,Deposit__r.Customer__r.Email__c,Deposit__r.Customer__r.Name,Deposit_Holder__r.Email__c, Deposit_Holder__r.PersonEmail,Deposit__r.Customer__c,Deposit__r.Contact__r.Name,Deposit__r.Contact__r.Email, 
                                                             Istenantmoved__c,Deposit__r.Deposit_Amount__c,Deposit__r.Property_Address__c,Deposit__r.NI_Deposit_Number__c,Deposit__r.EWC_Deposit_Number__c,Deposit__r.Id,
                                                             Deposit_Holder__r.Name,Deposit_Holder__r.Additional_Email__c,Contact__c,Contact__r.Email,Contact__r.Name, Tenencychangeoveramount__c, Is_Lead__c, Role__c
                                                             FROM Deposit_Allocation__c WHERE Deposit__c=:depositId /* AND Role__c='Tenant'*/];
        List<Deposit_Allocation__c> depAllocToUpdateList = new List<Deposit_Allocation__c>();

        // Query Case records to get the Respond_Date__c field value
        //List<Case> cases = [SELECT Id, Respond_Date__c FROM Case WHERE Deposit_Account_Number__c=:depositId];
        
        if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
            depAllocToUpdateList = updateMovedTenantOnDepAllocation(depoAllocList, depositAllocationList);
        } 
        else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
            depAllocToUpdateList = depositAllocationList;
        }
        
        //try {
            if(depAllocToUpdateList.size()>0) {
                update depAllocToUpdateList;
                
                List<FinalWrapper> tenantRecList = (List<FinalWrapper>)System.JSON.deserialize(newtenantlist, List<FinalWrapper>.class);
                List<Account> tenantList = new List<Account>(); 
                List<Id> tenantid = new List<Id>();
                
                // Inserting new tenants START
                if(tenantRecList.size()>0) {  
                    String recordTypeName = '';
                    if(scheme.toUpperCase().contains('NI')) {
                        recordTypeName = 'NI_Tenant';
                    } 
                    else if(scheme.toUpperCase().contains('EW')) {
                        recordTypeName = 'EWC_Tenant';
                    }
                    Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId(); 
                    
                    List<string> fullNameForSearchlist = new List<string>();
                    Set<String> emailIds = new Set<String>();
                    Map<String,Id> mapOfemailVsAccId = new Map<String,Id>();
                    Map<String,String> mapOfemailVsAccName = new Map<String,String>();
                    List<Account> personAccExistList = new List<Account>();
                    
                    for(FinalWrapper t : tenantRecList) {
                        if(Boolean.valueOf(t.tenantYesCheck)) {
                            fullNameForSearchlist.add(t.tenantCompanyName);
                            //   system.debug('fullNameForSearchlist ISORG => ' + fullNameForSearchlist);
                        }
                        else if(Boolean.valueOf(t.tenantNoCheck)) {
                            fullNameForSearchlist.add(t.tenantFirstname + ' ' + t.tenantLastname);
                            //    system.debug('fullNameForSearchlist ISPerson => ' + fullNameForSearchlist);
                        }
                        if(String.isnotEmpty(t.tenantEmail)) {   
                            emailIds.add(t.tenantEmail.trim() );
                        }
                    }
                    
                    if(!emailIds.isEmpty()) {
                        /* search in tenant person Accpounts */
                        // system.debug('fullNameForSearchlist => ' + fullNameForSearchlist);
                        String searchTerms = '';
                        for(String searchByName : fullNameForSearchlist){
                            if(!String.isEmpty(searchByName)){
                                if(!String.isEmpty(searchTerms)){
                                    searchTerms += ' OR ';
                                }
                                searchTerms += '("' + searchByName + '")';
                            }
                        }
                        //  system.debug('searchTerms => ' + searchTerms);
                        personAccExistList = (List<Account>)[FIND :searchTerms in ALL FIELDS 
                                                             RETURNING Account(ID, Name, PersonContactId, PersonEmail, Company_Name__c
                                                                               WHERE (PersonEmail IN :emailIds)
                                                                               AND (RecordType.Name =:recordTypeName /*= 'Tenant'*/) )][0];
                        // system.debug('personAccExistList => ' + personAccExistList);
                        for(Account existAcc : personAccExistList){
                            if(!mapOfemailVsAccId.containsKey(existAcc.PersonEmail)) {  
                                for(FinalWrapper t : tenantRecList) {
                                    String tenantName = t.tenantFirstname +' '+t.tenantLastname;
                                    if(existAcc.PersonEmail == t.tenantEmail.trim() && (existAcc.Name == t.tenantCompanyName.trim() || existAcc.Name == tenantName)) 
                                    {
                                        mapOfemailVsAccId.put(existAcc.PersonEmail.trim(),existAcc.Id);
                                        mapOfemailVsAccName.put(existAcc.PersonEmail.trim(),(existAcc.Name).toLowercase());                            
                                    }
                                }
                            }
                        }
                    }
                    
                    for(FinalWrapper t : tenantRecList) {
                        String tenantName = t.tenantFirstname +' '+t.tenantLastname;
                        if(personAccExistList.size() > 0 && mapOfemailVsAccId.containsKey(t.tenantEmail.trim()) && 
                           (mapOfemailVsAccName.get(t.tenantEmail.trim())==tenantName.toLowercase() || 
                            mapOfemailVsAccName.get(t.tenantEmail.trim())==(t.tenantCompanyName).toLowercase()) ) 
                        {
                            tenantid.add(mapOfemailVsAccId.get(t.tenantEmail.trim())); 
                        }
                        else {
                            if(Boolean.valueOf(t.tenantYesCheck)) 
                            {    
                                Account acc = new account();
                                acc.LastName = t.tenantCompanyName;
                                //acc.FirstName = t.companyName;
                                acc.Email__c = t.tenantEmail;
                                acc.PersonEmail = t.tenantEmail;
                                acc.Phone_Code__pc = t.tenantPhoneCode;
                                acc.Phone = t.tenantPhone;
                                acc.RecordTypeId = AccountRecordTypeId;
                                acc.OwnerId = loggedInUser[0].Account.OwnerId;
                                acc.PersonMailingStreet = t.relevantcity;
                                acc.PersonMailingState = t.relevantTown;
                                acc.PersonMailingPostalCode = t.relevantPostcode;
                                acc.PersonMailingCountry = t.relevantCountry;
                        
                                tenantList.add(acc);     
                            } 
                            else if(Boolean.valueOf(t.tenantNoCheck)) 
                            {   
                                Account acc = new account();
                                acc.Salutation = t.tenantTitle;
                                acc.FirstName = t.tenantFirstname;
                                acc.LastName = t.tenantLastname;
                                acc.Email__c = t.tenantEmail;
                                acc.PersonEmail = t.tenantEmail;
                                acc.Phone_Code__pc = t.tenantPhoneCode;
                                acc.Phone = t.tenantPhone;
                                acc.RecordTypeId = AccountRecordTypeId;
                                acc.OwnerId = loggedInUser[0].Account.OwnerId;
                                acc.PersonMailingStreet = t.relevantcity;
                                acc.PersonMailingState = t.relevantTown;
                                acc.PersonMailingPostalCode = t.relevantPostcode;
                                acc.PersonMailingCountry = t.relevantCountry;
                          
                                tenantList.add(acc);
                            }
                        }
                    }
                    
                    if(tenantList.size() > 0) {
                        Database.SaveResult[] recid = Database.insert(tenantList);
                        for (Database.SaveResult sr : recid) {
                            if(sr.isSuccess()) {
                                tenantid.add(sr.getId());
                                
                            }
                        }
                    }
                }
                // Inserting new tenants END
                
                List<Account> acclist = [SELECT Id, PersonContactId FROM Account WHERE Id IN:tenantid]; 
                String message = createNewDeposit(depositId, '', acclist, newdepositamount, newtenantsnumber, newdepositstartdate, newdepositenddate, 
                                                  depAllocToUpdateList, changeoverInitiatedBy, scheme);
                
                String BranchId = null;
                Deposit__c deprec = [Select id, Branch__c FROM Deposit__c WHERE Id =:depositId];
                if(deprec != null && deprec.Branch__c != null && !String.isBlank(deprec.Branch__c)){
                                BranchId = deprec.Branch__c;
                }                                  
                if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
                    // Creating case
                    String caseStatus = createCaseOnChangeOver(depositId, loggedInUser, 'agll', scheme, BranchId);
                    
                    // Mailjet code START
                    
                    // NN-58 AC-6
                    
                    List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                    List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();
                    String address ;
                    // String dan;
                    String toName;
                    String toaddress;
                    String toAddressTT;
                    String tenantName;
                    
                    if(scheme.toUpperCase().contains('NI')) {
                        dan=depAllocToUpdateList[0].Deposit__r.NI_Deposit_Number__c;
                        address=depAllocToUpdateList[0].Deposit__r.Property_Address__c;
                        if(loggedInUser[0].Profile.Name=='NI_Agent' || loggedInUser[0].Profile.Name == 'NI_Landlord' || loggedInUser[0].Profile.Name == 'NI_Head_Office_User' || loggedInUser[0].Profile.Name == 'NI_ Branch Users'){
                            
                            //   system.debug('line 990'+BranchId);
                            // system.debug('line 991'+depositAllocationList[0].Deposit__r.Branch__c);
                            
                            if(BranchId != null){
                                toAddress = branchEmailMailjet(depositAllocationList[0].Deposit__r.Branch__c);
                            } else {
                                toAddress = loggedInUser[0].Account.Email__c;
                            }
                            
                            toName = loggedInUser[0].Account.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                            emailRecipientList.add(new EI_MailJetUtility.recipient(toAddress, toName, caseIdForMailjet,depAllocToUpdateList[0].Deposit__r.Customer__c,''));   
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('user_name',toName);
                            variableMap.put('property_address',address);
                            variableMap.put('DAN',dan); 
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                                    'NN58AC6ChangeoverConfirmAgLL', 'Tenant changeover initiated - '+ address)); 
                        }
                        
                        for(Deposit_Allocation__c depAll :depAllocToUpdateList){
                            if(depAll.Istenantmoved__c){
                                toAddressTT = depAll.Contact__r.Email;
                                tenantName =  depAll.Contact__r.Name;
                                
                                List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                
                                String email ;
                                if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                    email = depAll.Deposit_Holder__r.Additional_Email__c;
                                }
                                if(email!=null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id));       
                                }
                                if(toAddressTT!=null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id)); 
                                }if(email==null && toAddressTT==null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, caseIdForMailjet,depAll.Contact__c,depAll.Id)); 
                                }          
                                Map<String, String> variableMap = new Map<String, String>();
                                variableMap.put('user_name',tenantName);
                                variableMap.put('property_address',address);
                                variableMap.put('DAN',dan); 
                                
                                emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                                        'NN58AC6ChangeoverConfirmVacatingTT', 'Please confirm you have moved out - ' + address)); 
                            }
                            
                        }
                    } 
                    /* else if(scheme.toUpperCase().contains('EW')) {
                        dan=depAllocToUpdateList[0].Deposit__r.EWC_Deposit_Number__c;
                        address=depAllocToUpdateList[0].Deposit__r.Property_Address__c;
                        if(loggedInUser[0].Profile.Name=='EWC Agent' || loggedInUser[0].Profile.Name == 'EWC Landlord' || loggedInUser[0].Profile.Name == 'EWC Head Office User' || loggedInUser[0].Profile.Name == 'EWC Branch User'){
                            if(BranchId != null){
                                toAddress = branchEmailMailjet(depositAllocationList[0].Deposit__r.Branch__c);
                            }
                            else{
                                toAddress = loggedInUser[0].Account.Email__c;
                            }
                            toName = loggedInUser[0].Account.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddress, toName, depAllocToUpdateList[0].Deposit__r.Id,depAllocToUpdateList[0].Deposit__r.Customer__c,''));   
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('Reciepient_Name',toName);
                            variableMap.put('Tenancy_Address',address);
                            variableMap.put('Payment_reference',dan); 
                            
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap, 
                                                                                    'TC_AA_LL_raised_TT_to_respond_AA_LL', 'Tenant changeover initiated by agent/landlord – '+ address)); 
                        }
                        
                        

                        for(Deposit_Allocation__c depAll :depAllocToUpdateList){
                            if(depAll.Istenantmoved__c){
                                toAddressTT = depAll.Contact__r.Email;
                                tenantName =  depAll.Contact__r.Name;
                                
                                List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                                
                                String email ;
                                if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                    email = depAll.Deposit_Holder__r.Additional_Email__c;
                                }
                                if(email!=null){
                                    emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,''));       
                                }
                                if(toAddressTT!=null){
                                    emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,'')); 
                                }        

                                Map<String, String> variableMap = new Map<String, String>();
                                String selfRegister = '<a href="'+System.Label.LoginPage+'">here</a>';
                                variableMap.put('user_name', tenantName);
                                variableMap.put('Tenancy_Address', address);
                                variableMap.put('Payment_reference', dan);
                                variableMap.put('Reg_link', selfRegister);

                                
                                // Query Case records to get the Respond_Date__c field value
                                 List<Case> cases = [SELECT Id, Respond_Date__c FROM Case WHERE Deposit_Account_Number__c=:depositId];
                                 System.debug('Line no 999 cases'+cases);
                                 System.debug('Line no 1000 depositId'+depositId);
                                 // Assuming you have the Case records and you want to retrieve the first one
                                if (!cases.isEmpty()) {
                                    System.debug('cases line no 998' + cases);
                                    Case caseRecord = cases[0];
                                    Date respondDate = caseRecord.Respond_Date__c;
                                    System.debug('respondDate line no 1001' + respondDate);
                                
                                    // Add 14 days to the Respond Date
                                   // Date fourteenWorkingDate = respondDate.addDays(14);
                                    Date fourteenWorkingDate = respondDate;

                                    // Convert the date to a string representation in dd/MM/yyyy format
                                    Datetime fourteenWorkingDatetime = Datetime.newInstance(fourteenWorkingDate.year(), fourteenWorkingDate.month(), fourteenWorkingDate.day());
                                    String fourteenWorkingDateString = fourteenWorkingDatetime.format('dd/MM/yyyy');
                                    System.debug('fourteenWorkingDateString line no 998' + fourteenWorkingDateString);
                                    variableMap.put('fourteen_working_date', fourteenWorkingDateString);
                                }
                                
 
                                emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap, 
                                                                                        'TC_AA_LL_raised_TT_to_respond_TT', 'Tenant changeover initiated by agent/landlord –' + address)); 
                                System.debug('variableMap line no 1013'+variableMap);
                            }
                            
                        }
                    } 
                    */
                    
                    if(emailWrapperList.size()>0) {
                        EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                    }
                    if(emailWrapperListEWC.size()>0) {
                        EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                    }
                    // Mailjet code END
                    
                }
                else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
                    // Updating case
                    List<Case> updateCaseList = new List<Case>();
                    DateTime dueDateTime;
                    Date dueDate;
                    String respondDateString;
                    for(Case changeOverCase : [Select Id, Status, ChangeOver_Status__c FROM Case WHERE Deposit_Account_Number__c=:depositId 
                                               AND Case_Statuses__c = 'Tenant changeover initiated - tenant' ORDER BY LastModifiedDate DESC LIMIT 1])        
                    {
                        changeOverCase.Case_Statuses__c = 'Tenant changeover accepted';
                        changeOverCase.ChangeOver_Status__c = 'Agent Approved';
                        dueDate = EI_NI_UtilityClassForInstallment.dueDateMethod(System.today(), 5);
                        dueDateTime = DateTime.newInstance(dueDate.year(), dueDate.month(), dueDate.day(), 0, 0, 0);
                        respondDateString = dueDateTime.format('dd/MM/yyyy');
                        changeOverCase.Respond_Date__c = dueDate;
                        //changeOverCase.Respond_Date__c = EI_NI_UtilityClassForInstallment.dueDateMethod(System.today(), 5);
                        updateCaseList.add(changeOverCase);
                    }
                    if(updateCaseList.size()>0) {
                        update updateCaseList;
                        
                        // Creating installments for moving tenants and for the remaining deposit amount on new and old deposit 
                        acceptChangeover(depositId, updateCaseList[0].Id, true, scheme);
                        Set<Id> depoIDListForDPC = new Set<Id>();
                        depoIDListForDPC.add(Id.ValueOf(depositId));
                        Database.executeBatch(new EI_EWC_DPC_reserveSendEmail_Batch(depoIDListForDPC), 150); // EN-109
                        
                        // Mailjet code START
                        List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                        List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();
                        
                        // NN-57 AC-14
                        if(scheme.toUpperCase().contains('NI')) {
                            String toName;
                            String toaddress;
                            String toAddressTT;
                            String tenantName;
                            String address ;
                            //String dan;
                            string loginlink;
                            string outgoingTT;
                            string remainingTT;
                            string agLLName;
                            loginlink = '<a href="'+System.Label.Lightning_Component_URL_NI+'login/">link to login</a>';
                            address=depositAllocationList[0].Deposit__r.Property_Address__c;
                            dan=depositAllocationList[0].Deposit__r.NI_Deposit_Number__c;
                            agLLName = depositAllocationList[0].Deposit_Holder__r.Name;
                            
                            // table creation loop
                            outgoingTT = '<table>';
                            
                            outgoingTT += '<tr>';
                            outgoingTT+=  '<th><b>Tenant(s) moving out</b>:</th>';
                            
                            remainingTT = '<table>';
                            remainingTT += '<tr>';
                            remainingTT+=  '<th><b>Remaining tenant(s)</b>:</th>';
                            //id niCaseId=null;
                            id niCaseId=[select id from case where Deposit_Account_Number__c=:depositId limit 1].id;
                            for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Tenencychangeoveramount__c,Contact__r.Name from Deposit_Allocation__c 
                                                               where deposit__c=:depositId ]){                                                               
                                                                   if(depAll.Istenantmoved__c){
                                                                       
                                                                       // outgoingTT += '<tr>';
                                                                       outgoingTT += '<td>'+ depAll.Contact__r.Name +'<td>' +'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
                                                                       outgoingTT += '<td>'+'Amount due:£'+ String.valueOf((depAll.Tenencychangeoveramount__c.setScale(2))) +'<td> <br>';
                                                                       outgoingTT += '</tr>';                                                  
                                                                       
                                                                   }else{
                                                                       
                                                                       // remainingTT += '<tr>';
                                                                       remainingTT += '<td>'+ depAll.Contact__r.Name +'<td> <br>';
                                                                       remainingTT += '</tr>';
                                                                       
                                                                   }
                                                                   
                                                               }
                            outgoingTT += '</table><br/><br/>';
                            remainingTT += '</table><br/><br/>';
                            List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                            List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                            
                            toAddress = depositAllocationList[0].Deposit__r.Customer__r.Email__c;
                            toName = depositAllocationList[0].Deposit__r.Customer__r.Name;
                            
                            
                            emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, niCaseId,depositAllocationList[0].Deposit__r.Customer__c,''));   
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('user_name',toName);
                            variableMap.put('property_address',address);
                            variableMap.put('DAN',dan);
                            variableMap.put('outgoing_tenant',outgoingTT);
                            variableMap.put('remaining_tenant',remainingTT);
                            variableMap.put('new_DAN',newNIDAN);
                            variableMap.put('agll_name',agLLName);
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                    'NN57AC14ChangeoverAcceptAgLL', 'Tenant changeover accepted - '+ address)); 
                            
                            for(Deposit_Allocation__c depAll :[select id,contact__c,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                               where deposit__c=:depositId ]){
                                                                   toAddressTT = depAll.Contact__r.Email;
                                                                   tenantName =  depAll.Contact__r.Name;
                                                                   
                                                                   List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                                                   
                                                                   String email;
                                                                   if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                                       email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                                   }
                                                                   if(email!=null){
                                                                       emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, niCaseId,depAll.contact__c,depAll.Id));
                                                                   }
                                                                   if(toAddressTT!=null){
                                                                       emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, niCaseId,depAll.Contact__c,depAll.Id)); 
                                                                   }if(email==null && toAddressTT==null){
                                                                       emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, niCaseId,depAll.Contact__c,depAll.Id));       
                                                                   }        
                                                                   Map<String, String> variableMap1 = new Map<String, String>();
                                                                   variableMap1.put('user_name',tenantName);
                                                                   variableMap1.put('property_address',address);
                                                                   variableMap1.put('DAN',dan);
                                                                   variableMap1.put('outgoing_tenant',outgoingTT);
                                                                   variableMap1.put('remaining_tenant',remainingTT);
                                                                   variableMap1.put('new_DAN',newNIDAN);
                                                                   variableMap1.put('agll_name',agLLName);
                                                                   
                                                                   if(depAll.Istenantmoved__c){
                                                                       emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                               'NN57AC14ChangeoverAcceptOutgoingTT', 'Tenant changeover accepted - ' + address));
                                                                   }else{
                                                                       emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                               'NN57AC14ChangeoverAcceptRemainingTT', 'Tenant changeover accepted - ' + address));
                                                                   }
                                                                   
                                                                   
                                                                   
                                                               }
                            
                            for(account acc : [select id,Name,PersonEmail,Additional_Email__pc from account where id in:tenantid]){
                                toAddressTT = acc.PersonEmail;
                                tenantName =  acc.Name;
                                
                                List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                
                                String email ;
                                if(acc.Additional_Email__pc!=null){
                                    email = acc.Additional_Email__pc;
                                }
                                if(email!=null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName,niCaseId ,acc.id,''));       
                                }
                                if(toAddressTT!=null){
                                    emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, niCaseId,acc.Id,'')); 
                                }        
                                Map<String, String> variableMap1 = new Map<String, String>();
                                variableMap1.put('user_name',tenantName);
                                variableMap1.put('link_to_login',loginlink);
                                
                                emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                        'NN57AC14NewDepositNewTT', 'New Deposit Protected – Confirm to add to your account ' ));
                                
                            }
                        } 
                        
                        //EWC Mailjet Code
                   /*     else if(scheme.toUpperCase().contains('EW')) {
                            String toName;
                            String toaddress;
                            String toAddressTT;
                            String tenantName;
                            String address ;
                            String danewc;
                            string outgoingTenant='';
                            address=depositAllocationList[0].Deposit__r.Property_Address__c;
                            danewc=depositAllocationList[0].Deposit__r.EWC_Deposit_Number__c;
                            //agLLName = depositAllocationList[0].Deposit_Holder__r.Name;
                            
                            
                            List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                            List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                            //For Branch Code
                            if (depositAllocationList[0].Deposit__r.Branch__c != null){

                            toAddress = branchEmailMailjet(depositAllocationList[0].Deposit__r.Branch__c);
                            }
                            else{
                            toAddress = depositAllocationList[0].Deposit__r.Customer__r.Email__c;
                            }
                            //toAddress = depositAllocationList[0].Deposit__r.Customer__r.Email__c;
                            toName = depositAllocationList[0].Deposit__r.Customer__r.Name;
                            
                            
                            emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, depositId,depositAllocationList[0].Deposit__r.Customer__c,''));   
                            Map<String, String> variableMap = new Map<String, String>();
                            variableMap.put('Reciepient_Name',toName);
                            variableMap.put('Tenancy_Address',address);
                            variableMap.put('Payment_reference',danewc);
                            variableMap.put('old_deposit_acc',danewc);
                            variableMap.put('new_deposit_acc',newEWCDAN);
                            variableMap.put('five_working_date',respondDateString);

                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                    'TC_TT_raised_accepted_conf_to_AA_LL', 'Tenant changeover accepted –'+ address)); 
                            

                                //For table 
                                outgoingTenant += '<table>';
                                List<Deposit_Allocation__c> newdepoAllocLIst = [select id,Istenantmoved__c,Tenencychangeoveramount__c,Contact__r.Name from Deposit_Allocation__c 
                                where deposit__c=:depositId ];
                                for(integer i=0; i< newdepoAllocLIst.size(); i++){   
                                    Deposit_Allocation__c depAll =  newdepoAllocLIst[i];                                                          
                                                                            if(depAll.Istenantmoved__c){
                                                                                System.debug('depAll'+depAll);
                                                                                if(i==0){
                                                                                    outgoingTenant += '<tr>';
                                                                                    outgoingTenant += '<td> Number of tenant(s) <td>';
                                                                                    outgoingTenant += '<td>'+ depAll.Contact__r.Name +'<td>';
                                                                                    outgoingTenant += '</tr>';
                                                                                }else{
                                                                                outgoingTenant += '<tr>';
                                                                                outgoingTenant += '<td></td>';
                                                                                outgoingTenant += '<td></td>';
                                                                                outgoingTenant += '<td>'+ depAll.Contact__r.Name +'<td>';
                                                                                outgoingTenant += '</tr>';
                                                                                    }                                             
                                                                                
                                                                            }
                                                                        }
                                outgoingTenant += '</table>'; 

                            for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                               where deposit__c=:depositId ]){
                                                                   toAddressTT = depAll.Contact__r.Email;
                                                                   tenantName =  depAll.Contact__r.Name;
                                                                   address=depositAllocationList[0].Deposit__r.Property_Address__c;
                                                                   dan=depositAllocationList[0].Deposit__r.EWC_Deposit_Number__c;
                                                                   List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                                                                   
                                                                   String email;
                                                                   if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                                       email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                                   }
                                                                   if(email!=null){
                                                                       emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depositId,depositAllocationList[0].Deposit__r.Customer__c,''));       
                                                                   }
                                                                   if(toAddressTT!=null){
                                                                       emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depositId,depositAllocationList[0].Deposit__r.Customer__c,'')); 
                                                                   }        
                                                                   Map<String, String> variableMap1 = new Map<String, String>();
                                                                   variableMap1.put('user_name',tenantName);
                                                                   variableMap1.put('Tenancy_Address',address);
                                                                   variableMap1.put('Payment_reference',dan);
                                                                   variableMap1.put('old_deposit_acc',dan);
                                                                   variableMap1.put('new_deposit_acc',newEWCDAN);
                                                                   variableMap1.put('TenantMovingOut',outgoingTenant);
                                                                   variableMap1.put('five_working_date', respondDateString);
                                                                   
                                                                   if(depAll.Istenantmoved__c){
                                                                       emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                                                               'TC_accepted_conf_to_outgoing_TT', 'Tenant changeover accepted - ' + address));
                                                                   }else{
                                                                       emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                                                               'TC_accepted_conf_to_remaining_TT', 'Tenant changeover accepted - ' + address));
                                                                   }
                                                                   
                                                                   
                                                                   
                                                               }
                            
                            for(account acc : [select id,Name,PersonEmail,Additional_Email__pc from account where id in:tenantid]){
                                toAddressTT = acc.PersonEmail;
                                tenantName =  acc.Name;
                                
                                List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                                
                                String email ;
                                if(acc.Additional_Email__pc!=null){
                                    email = acc.Additional_Email__pc;
                                }
                                if(email!=null){
                                    emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName,'' ,acc.id,''));       
                                }
                                if(toAddressTT!=null){
                                    emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, '',acc.Id,'')); 
                                }        
                                Map<String, String> variableMap1 = new Map<String, String>();
                                variableMap1.put('user_name',tenantName);
                                variableMap1.put('Payment_reference',danewc);
                                variableMap1.put('Tenancy_Address',address);
                                
                                emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                       'TC_accepted_conf_to_new_TT', 'Tenant changeover accepted –' + address));

                            }
                        } 
                     */   
                        if(emailWrapperList.size()>0) {
                            EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                        }
                        if(emailWrapperListEWC.size()>0) {
                            EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                        }
                        // Mailjet code END
                        
                    }
                }
                return 'Success';
            }
            return 'Something went wrong';
        //}
        //catch(Exception e) {
        //    System.debug('Line 510 error -> '+String.valueOf(e.getMessage()));
        //    return 'Error '+String.ValueOf(e.getMessage());
        //}
        
    }
    
    // Tenant accepts changeover
    @AuraEnabled(cacheable=false)
    public static String approveChangeoverByTenant(String caseId, String scheme,List<Id> tenantid) 
    {    
        EI_NI_utility.flagForCaseEmails = true;
        List<Case> getCaseDetails = [SELECT Id, Case_Statuses__c,Deposit_Account_Number__r.Branch__c,Deposit_Account_Number__r.New_Changeover_Deposit__c,ChangeOver_Status__c, Deposit_Account_Number__c, AccountId,Deposit_Account_Number__r.New_Changeover_Deposit__r.EWC_Deposit_Number__c, 
                                     Deposit_Account_Number__r.Property_Address__c,Deposit_Account_Number__r.NI_Deposit_Number__c,Deposit_Account_Number__r.EWC_Deposit_Number__c,Deposit_Account_Number__r.Customer__c,
                                     Deposit_Account_Number__r.Id,Deposit_Account_Number__r.Customer__r.Email__c,Respond_Date__c, Deposit_Account_Number__r.Customer__r.Name,Deposit_Account_Number__r.Contact__r.Name,Deposit_Account_Number__r.Contact__r.Email
                                     FROM Case WHERE Id=:CaseId AND Case_Statuses__c='Tenant changeover initiated - agent/landlord' LIMIT 1]; 
        //List<Case> cases = [SELECT Id, Respond_Date__c FROM Case WHERE Id=:CaseId];
                              
        try {
            if(getCaseDetails.size()>0) {
                acceptChangeover(getCaseDetails[0].Deposit_Account_Number__c, caseId, false, scheme);
                
                // Updating case
                getCaseDetails[0].Case_Statuses__c = 'Tenant changeover accepted';      
                getCaseDetails[0].Respond_Date__c = EI_NI_UtilityClassForInstallment.dueDateMethod(System.today(), 5);          
                getCaseDetails[0].ChangeOver_Status__c = 'Tenant Approved';
                
                List<Deposit_Allocation__c> newDepositTenantList = [SELECT Id, Deposit__c, Deposit_Holder__c, Deposit_Holder__r.PersonContactId, 
                                                               Deposit_Holder__r.PersonEmail, Deposit_Holder__r.Name, Istenantmoved__c, 
                                                               Deposit__r.Property_Address_WO_Country__c, Tenencychangeoveramount__c,
                                                               Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c
                                                               FROM Deposit_Allocation__c WHERE Role__c='Tenant' 
                                                               AND Deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.New_Changeover_Deposit__c ];
                
                Set<Id> tenantAcctSet = new Set<Id>();
                Set<Id> newTenantAcctSet = new Set<Id>();

                for(Deposit_Allocation__c depAlloc : newDepositTenantList) {
                    if(!tenantAcctSet.contains(depAlloc.Deposit_Holder__c)){
                        newTenantAcctSet.add(depAlloc.Deposit_Holder__c);
                    }
                }
                
                update getCaseDetails;
                
                // Mailjet code START 
                // List<Id> tenantid = new List<Id>();
                List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();
                // NN-58 AC-11
                if(scheme.toUpperCase().contains('NI')) 
                {
                    String address ;
                    String dan;
                    String toName;
                    String toaddress;
                    String toAddressTT;
                    String tenantName;
                    address=getCaseDetails[0].Deposit_Account_Number__r.Property_Address__c;
                    dan=getCaseDetails[0].Deposit_Account_Number__r.NI_Deposit_Number__c;
                    List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                    List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                    
                    if (getCaseDetails[0].Deposit_Account_Number__r.Branch__c != null){

                        toAddress = branchEmailMailjet(getCaseDetails[0].Deposit_Account_Number__r.Branch__c);
                    }
                    else{
                        toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        }
                    
                   // toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                    toName = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Name;
                    
                    
                    emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, caseId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));   
                    Map<String, String> variableMap = new Map<String, String>();
                    variableMap.put('user_name',toName);
                    variableMap.put('property_address',address);
                    variableMap.put('DAN',dan); 
                    
                    emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                            'NN58AC11ChangeoverAcceptAgLL', 'Tenant changeover accepted - '+ address)); 
                    
                    for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,contact__c,Contact__r.Email,Contact__r.Name,Deposit__r.Customer__c,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c where deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.Id ]){
                        if(depAll.Istenantmoved__c){
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, caseId,depAll.Contact__c,depAll.Id));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                            }if(email==null && toAddressTT==null){
                                emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, caseId,depAll.Contact__c,depAll.Id));       
                            }        
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('property_address',address);
                            variableMap1.put('DAN',dan); 
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                    'NN58AC11AmendDepositOutgoingTT', 'Thank you for confirming you have moved out - ' + address)); 
                        }
                        
                    }
                    
                    
                } 
                else if(scheme.toUpperCase().contains('EW')) 
                {
                    String address ;
                    String dan;
                    String toName;
                    String toaddress;
                    String toAddressTT;
                    String tenantName;
                    address=getCaseDetails[0].Deposit_Account_Number__r.Property_Address__c;
                    dan=getCaseDetails[0].Deposit_Account_Number__r.EWC_Deposit_Number__c;
                    newEWCDAN=getCaseDetails[0].Deposit_Account_Number__r.New_Changeover_Deposit__r.EWC_Deposit_Number__c;
                    List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                    List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                    List<Case> cases = [SELECT Id, Respond_Date__c FROM Case WHERE Id=:CaseId];
                    if (getCaseDetails[0].Deposit_Account_Number__r.Branch__c != null){

                        toAddress = branchEmailMailjet(getCaseDetails[0].Deposit_Account_Number__r.Branch__c);
                    }
                    else{
                        toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        }
                    
                    //toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                    toName = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Name;
                    
                    System.debug('newdepdan' + newEWCDAN);
                    emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, getCaseDetails[0].Deposit_Account_Number__r.Id,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));   
                    Map<String, String> variableMap = new Map<String, String>();
                    variableMap.put('Reciepient_Name',toName);
                    variableMap.put('Tenancy_Address',address);
                    variableMap.put('Payment_reference',dan); 
                    variableMap.put('old_deposit_acc',dan); 
                    variableMap.put('new_deposit_acc',newEWCDAN); 

                    
                    if (!cases.isEmpty()) {
                        System.debug('cases line no 1605' + cases);
                        Case caseRecord = cases[0];
                        Date respondDate = caseRecord.Respond_Date__c;
                        System.debug('respondDate line no 1608' + respondDate);
                    
                        // Add 14 days to the Respond Date
                       // Date fourteenWorkingDate = respondDate.addDays(14);
                        Date fiveWorkingDate = respondDate;

                        // Convert the date to a string representation in dd/MM/yyyy format
                        Datetime fiveWorkingDatetime = Datetime.newInstance(fiveWorkingDate.year(), fiveWorkingDate.month(), fiveWorkingDate.day());
                        String fiveWorkingDateString = fiveWorkingDatetime.format('dd/MM/yyyy');
                        System.debug('fiveWorkingDateString line no 998' + fiveWorkingDateString);
                        variableMap.put('five_working_date', fiveWorkingDateString);
                    }
                    
                    emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                            'TC_AA_LL_raised_TT_accepted_AA_LL', 'Tenant changeover accepted – '+ address)); 
                    
                    for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit__r.Customer__c,Deposit_Holder__r.Additional_Email__c,Role__c from Deposit_Allocation__c where deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.Id]){
                        if(depAll.Istenantmoved__c){
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,''));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,'')); 
                            }        
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('Tenancy_Address',address);
                            variableMap1.put('Payment_reference',dan);  
                            variableMap1.put('old_deposit_acc',dan); 
                            
                                 //      System.debug('Line no 1601 cases'+cases);
                                 //System.debug('Line no 1602 depositId'+depositId);
                                 // Assuming you have the Case records and you want to retrieve the first one
                                if (!cases.isEmpty()) {
                                    //         System.debug('cases line no 1605' + cases);
                                    Case caseRecord = cases[0];
                                    Date respondDate = caseRecord.Respond_Date__c;
                                    //      System.debug('respondDate line no 1608' + respondDate);
                                
                                   
                                    Date fiveWorkingDate = respondDate;

                                    // Convert the date to a string representation in dd/MM/yyyy format
                                    Datetime fiveWorkingDatetime = Datetime.newInstance(fiveWorkingDate.year(), fiveWorkingDate.month(), fiveWorkingDate.day());
                                    String fiveWorkingDateString = fiveWorkingDatetime.format('dd/MM/yyyy');
                                    //     System.debug('fiveWorkingDateString line no 998' + fiveWorkingDateString);
                                    variableMap1.put('five_working_date', fiveWorkingDateString);
                                }
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                    'TC_AA_LL_raised_accepted_outgoing_TT', 'Tenant changeover accepted – ' + address)); 
                        }
                        if(depAll.Role__c=='Relevant Person'){
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            //  System.debug('Line No 1589 toAddressTT'+toAddressTT);
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,''));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depAll.Deposit__r.Id,depAll.Deposit__r.Customer__c,'')); 
                            }

                            
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('Tenancy_Address',address);
                            variableMap1.put('Payment_reference',dan);  
                            variableMap1.put('old_deposit_acc',dan); 
                            
                            //     System.debug('Line no 1601 cases'+cases);
                            //System.debug('Line no 1602 depositId'+depositId);
                            // Assuming you have the Case records and you want to retrieve the first one
                            if (!cases.isEmpty()) {
                               //     System.debug('cases line no 1605' + cases);
                               Case caseRecord = cases[0];
                               Date respondDate = caseRecord.Respond_Date__c;
                               //   System.debug('respondDate line no 1608' + respondDate);
                           
                        
                               Date fiveWorkingDate = respondDate;

                               // Convert the date to a string representation in dd/MM/yyyy format
                               Datetime fiveWorkingDatetime = Datetime.newInstance(fiveWorkingDate.year(), fiveWorkingDate.month(), fiveWorkingDate.day());
                               String fiveWorkingDateString = fiveWorkingDatetime.format('dd/MM/yyyy');
                               //   System.debug('fiveWorkingDateString line no 998' + fiveWorkingDateString);
                               variableMap1.put('five_working_date', fiveWorkingDateString);
                           }

                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                    'TC_AA_LL_raised_accepted_relevant_per', 'Tenant changeover accepted – ' + address)); 
                            System.debug('Line no 1625 emailWrapperListEWC'+emailWrapperListEWC);
                        }
                        
                    }
                    //for new tenant after accept
                        /*for(account acc : [select id,Name,PersonEmail,Additional_Email__pc from account where id in:newTenantAcctSet]){
                            toAddressTT = acc.PersonEmail;
                            tenantName =  acc.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(acc.Additional_Email__pc!=null){
                                email = acc.Additional_Email__pc;
                            }
                            if(email!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName,'' ,acc.id,''));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, '',acc.Id,'')); 
                            }        
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('Payment_reference',dan);
                            variableMap1.put('Tenancy_Address',address);
                            
                            
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                   'TC_AA_LL_raised_accepted_incoming_TT', 'Tenant changeover accepted –'+address));

                        }*/

                }
                

                if(emailWrapperList.size()>0) {
                    EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                }
                if(emailWrapperListEWC.size()>0) {
                    EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                }
                // Mailjet code END
                
                return 'Success';
            }
            else {
                return 'Case not found';
            }
        } 
        catch(DMLException e) {
            return 'Error '+e.getMessage(); 
        }
    }
    
    // Tenant rejects changeover
    @AuraEnabled 
    public static String rejectChangeoverByTenant(String depositId, String caseId, String scheme) 
    {
        try {
            
            List<Case> getCaseDetails = [SELECT Id, Case_Statuses__c, ChangeOver_Status__c, Deposit_Account_Number__c, AccountId FROM Case 
                                         WHERE Id=:caseId AND (Case_Statuses__c='Tenant changeover initiated - agent/landlord' OR 
                                                               Case_Statuses__c='Tenant changeover initiated - tenant') ORDER BY LastModifiedDate DESC LIMIT 1];
            
            if(!getCaseDetails.isEmpty()) {
                String message = 'Tenant changeover cancelled';
                List<Deposit__c > deplist = [SELECT Id,Branch__c,NI_Deposit_Number__c,EWC_Deposit_Number__c,Property_Address__c,Tenant_Changeover_Status__c,Customer__r.Name,Customer__c,Customer__r.PersonContactId, 
                                             Customer__r.Email__c,Customer__r.PersonEmail,Customer__r.IsPersonAccount, Property_Address_WO_Country__c, 
                                             Tenant_Changeover_Deposit__c, New_Changeover_Deposit__c,Contact__r.Email,Contact__r.Name FROM Deposit__c 
                                             WHERE Id=:getCaseDetails[0].Deposit_Account_Number__c /*Id=:depositId in (Select Deposit_Account_Number__c FROM Case WHERE Id=:caseId) */
                                             LIMIT 1 ];      
                
                List<Deposit_Allocation__c > oldDepositAllocList = [SELECT Id,contact__c,Deposit__c, Deposit_Holder__c, Deposit_Holder__r.PersonContactId, 
                                                                    Deposit_Holder__r.PersonEmail,Deposit_Holder__r.Additional_Email__c, Deposit_Holder__r.Name, Istenantmoved__c, 
                                                                    Deposit__r.Property_Address_WO_Country__c,Deposit__r.Property_Address__c, Tenencychangeoveramount__c,Contact__r.Email,Contact__r.Name,Deposit__r.Contact__c 
                                                                    FROM Deposit_Allocation__c WHERE /*Istenantmoved__c =true AND */ Role__c='Tenant' 
                                                                    AND Deposit__c=:getCaseDetails[0].Deposit_Account_Number__c];
                
                if(deplist.size()>0) {
                    List<Deposit__c> deleteNewDepositList = [SELECT Id,Tenant_Changeover_Status__c,Status__c, Tenant_Changeover_Deposit__c FROM Deposit__c 
                                                             WHERE Id=:deplist[0].New_Changeover_Deposit__c LIMIT 1 ];  
                    if(deleteNewDepositList.size()>0) {
                        delete deleteNewDepositList;
                    }
                }  
                
                if(oldDepositAllocList.size()>0) {
                    List<Deposit_Allocation__c> updateMovingOutTenants = new List<Deposit_Allocation__c> (); 
                    for(Deposit_Allocation__c dept : oldDepositAllocList) {                        
                        if(dept.Istenantmoved__c) {
                            Deposit_Allocation__c dac = new Deposit_Allocation__c();
                            dac.Id = dept.Id;
                            dac.Istenantmoved__c = false;
                            dac.Tenencychangeoveramount__c = 0;
                            updateMovingOutTenants.add(dac);
                        }
                    }
                    if(updateMovingOutTenants.size()>0) {
                        update updateMovingOutTenants;
                    }
                }
                
                if(deplist.size()>0) {
                    List<Deposit__c> updateDepositList = new List<Deposit__c> ();
                    for(Deposit__c  deposit : deplist) {
                        Deposit__c dep = new Deposit__c();
                        // dep.Id = deposit.Id; 
                        dep.Id = getCaseDetails[0].Deposit_Account_Number__c;
                        dep.ChangeOver_CaseStatus__c = 'Tenant changeover cancelled';
                        dep.Tenant_Changeover_Status__c = 'Reject';
                        dep.Tenant_Changeover_Deposit__c = null;   
                        updateDepositList.add(dep); 
                    }
                    if(updateDepositList.size()>0) {
                        update updateDepositList;
                    }
                }
                
                // Updating Case
                Case updateCase = new Case(Id=caseId, Case_Statuses__c='Tenant changeover cancelled', ChangeOver_Status__c='Tenant Rejected', 
                                           Respond_Date__c=System.today());
                update updateCase;
                
                // Mailjet code START
                
                List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();
                String address ;
                String dan;
                
                if(scheme.toUpperCase().contains('NI')) 
                {
                    dan=deplist[0].NI_Deposit_Number__c;
                    address=deplist[0].Property_Address__c;
                    // NN-58 AC-8.5
                    if(getCaseDetails[0].Case_Statuses__c=='Tenant changeover initiated - agent/landlord'){
                        
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        
                         //For Branch code
                        if (deplist[0].Branch__c != null){

                        toAddress = branchEmailMailjet(deplist[0].Branch__c);
                        }
                        else{
                        toAddress = deplist[0].Customer__r.Email__c;
                        }
                        
                        // toAddress = deplist[0].Customer__r.Email__c;
                        toName = deplist[0].Customer__r.Name;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                        emailRecipientList.add(new EI_MailJetUtility.recipient(toAddress, toName, caseId,deplist[0].Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('user_name',toName);
                        variableMap.put('property_address',address);
                        variableMap.put('DAN',dan); 
                        
                        emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                                'NN58AC85ChangeoverCancelAgLL', 'Tenant changeover cancelled - '+ address)); 
                        
                        
                        for(Deposit_Allocation__c depAll :oldDepositAllocList){
                            if(depAll.Istenantmoved__c){
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListTT = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient(email, tenantName, caseId,depAll.Contact__c,depAll.Id));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                            }if(email==null && toAddressTT==null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient('', tenantName,caseId,depAll.Contact__c,depAll.Id));       
                            }        
                            Map<String, String> variableMapTT = new Map<String, String>();
                            variableMapTT.put('user_name',tenantName);
                            variableMapTT.put('property_address',address);
                            variableMapTT.put('DAN',dan); 
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListTT), variableMapTT, 
                                                                                    'NN58AC85ChangeoverCancelTT', 'Tenant changeover cancelled - ' + address)); 
                            
                            }
                            
                        }
                        
                    }
                    
                    // NN-57 AC-19.3
                    else if(getCaseDetails[0].Case_Statuses__c=='Tenant changeover initiated - tenant'){
                        
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        string ChangeoverTT;
                        // Branch Code For NI
                        if (deplist[0].Branch__c != null){

                        toAddress = branchEmailMailjet(deplist[0].Branch__c);
                        }
                        else{
                        toAddress = deplist[0].Customer__r.Email__c;
                        }
                        
                       // toAddress = deplist[0].Customer__r.Email__c;
                        toName = deplist[0].Customer__r.Name;
                        
                        User userRec = [SELECT Id, Name FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
                        ChangeoverTT= userRec.Name.capitalize();
                        List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                        emailRecipientList.add(new EI_MailJetUtility.recipient(toAddress, toName, caseId,deplist[0].Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('user_name',toName);
                        variableMap.put('property_address',address);
                        variableMap.put('DAN',dan); 
                        
                        emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap, 
                                                                                'NN57AC193ChangeoverCancelAgLL', 'Tenant changeover cancelled - '+ address)); 
                        
                        
                        for(Deposit_Allocation__c depAll :oldDepositAllocList){
                            
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListTT = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient(email, tenantName, caseId,depAll.Contact__c,depAll.Id));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                            }if(email==null && toAddressTT==null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient('', tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                            }         
                            Map<String, String> variableMapTT = new Map<String, String>();
                            variableMapTT.put('user_name',tenantName);
                            variableMapTT.put('property_address',address);
                            variableMapTT.put('DAN',dan); 
                            variableMapTT.put('changeover_tenant',ChangeoverTT);
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListTT), variableMapTT, 
                                                                                    'NN57AC193ChangeoverCancelTT', 'Tenant changeover cancelled - ' + address)); 
                            
                            // system.debug('line 1217 emailRecipientListTT-->'+emailRecipientListTT);
                            
                        }
                        
                        //    system.debug('line 1217 emailWrapperList-->'+emailWrapperList);
                        //  system.debug('line 1217 emailRecipientList-->'+emailRecipientList);
                        
                    }
                }
               /* else if(scheme.toUpperCase().contains('EW')) 
                {
                    dan=deplist[0].EWC_Deposit_Number__c;
                    address=deplist[0].Property_Address__c;
                    List<Id> tenantid = new List<Id>();
                    
                    if(getCaseDetails[0].Case_Statuses__c=='Tenant changeover initiated - agent/landlord'){
                        
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        //For Branch code
                        if (deplist[0].Branch__c != null){

                        toAddress = branchEmailMailjet(deplist[0].Branch__c);
                        }
                        else{
                        toAddress = deplist[0].Customer__r.Email__c;
                        }
                        
                        //toAddress = deplist[0].Customer__r.Email__c;
                        toName = deplist[0].Customer__r.Name;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                        emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddress, toName, deplist[0].Id,deplist[0].Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('Reciepient_Name',toName);
                        variableMap.put('Tenancy_Address',address);
                        variableMap.put('Payment_reference',dan); 
                        
                        emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap, 
                                                                                'TC_AA_LL_raised_TT_cancelled_AA_LL', 'Tenant changeover cancelled–'+ address)); 
                        
                        
                        for(Deposit_Allocation__c depAll :oldDepositAllocList){
                            if(depAll.Istenantmoved__c){
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListTT = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient(email, tenantName, deplist[0].Id,deplist[0].Customer__c,''));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListTT.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, deplist[0].Id,deplist[0].Customer__c,'')); 
                            }        
                            Map<String, String> variableMapTT = new Map<String, String>();
                            variableMapTT.put('user_name',tenantName);
                            variableMapTT.put('Tenancy_Address',address);
                            variableMapTT.put('Payment_reference',dan); 
                            
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListTT), variableMapTT, 
                                                                                    'TC_AA_LL_raised_TT_cancelled_TT', 'Tenant changeover cancelled–' + address)); 
                            
                            }
                            
                        }

                        
                    }
                    
                }
*/
                if(emailWrapperList.size()>0) {
                    EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                }
                
                if(emailWrapperListEWC.size()>0) {
                    EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                }
                // Mailjet code END
                
                return 'Success';
            }
            else {
                return 'Case not found';
            }
        }
        catch(DmlException e) {
            return 'Failed in Update: ' + e.getMessage();
        }
    }
    
    // Agll rejects changeover  
    @AuraEnabled 
    public static String rejectChangeoverByAgll(String depositId, String caseId, String scheme) 
    {
        try {   
            
            List<Case> getCaseDetails = [SELECT Id, Case_Statuses__c,Deposit_Account_Number__r.Branch__c,ChangeOver_Status__c, Deposit_Account_Number__c,Deposit_Account_Number__r.Old_Changeover_Deposit__c, AccountId,Deposit_Account_Number__r.New_Changeover_Deposit__c,
                                         Deposit_Account_Number__r.Property_Address__c,Deposit_Account_Number__r.NI_Deposit_Number__c,Deposit_Account_Number__r.EWC_Deposit_Number__c,Deposit_Account_Number__r.Customer__c,
                                         Deposit_Account_Number__r.Id,Deposit_Account_Number__r.Customer__r.Email__c,Deposit_Account_Number__r.Customer__r.Name,Deposit_Account_Number__r.Contact__r.Name,Deposit_Account_Number__r.Contact__r.Email
                                         FROM Case WHERE Id=:caseId AND Case_Statuses__c IN ('Tenant changeover initiated - tenant', 
                                                                                             'Tenant changeover initiated - agent/landlord') 
                                         ORDER BY LastModifiedDate LIMIT 1];
            
            if(!getCaseDetails.isEmpty()) {
                List<Deposit_Allocation__c> depAllocToUpdate = new List<Deposit_Allocation__c>();
                List<Deposit_Allocation__c> movedTenantList = [SELECT Id, Deposit__c, Deposit_Holder__c, Deposit_Holder__r.PersonContactId, 
                                                               Deposit_Holder__r.PersonEmail, Deposit_Holder__r.Name, Istenantmoved__c, 
                                                               Deposit__r.Property_Address_WO_Country__c, Tenencychangeoveramount__c,
                                                               Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c
                                                               FROM Deposit_Allocation__c WHERE Istenantmoved__c =true AND Role__c='Tenant' 
                                                               AND Deposit__c=:depositId AND Deposit__r.ChangeOver_CaseStatus__c IN
                                                               ('Tenant changeover initiated - tenant', 'Tenant changeover initiated - agent/landlord') ];
                
                /*for(Deposit_Allocation__c depAlloc : movedTenantList) {
                    depAllocToUpdate.add(new Deposit_Allocation__c(Id=depAlloc.Id, Istenantmoved__c=false, Tenencychangeoveramount__c=0));
                }*/
                Set<Id> oldDepositTenantIds = new Set<Id>();
                Set<Id> tenantAcctSet = new Set<Id>();
                Set<Id> newTenantAcctSet = new Set<Id>();
                for(Deposit_Allocation__c old : [SELECT Deposit_Holder__c  
                                                 FROM Deposit_Allocation__c 
                                                 WHERE Deposit__c = :depositId 
                                                 AND Role__c = 'Tenant']) {
                                                     oldDepositTenantIds.add(old.Deposit_Holder__c); 
                                                 }
                
                List<Deposit_Allocation__c> newDepositTenantList = [
                    SELECT Id, Deposit_Holder__r.Name,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c
                    FROM Deposit_Allocation__c
                    WHERE Deposit__c = :getCaseDetails[0].Deposit_Account_Number__r.New_Changeover_Deposit__c
                    AND Role__c = 'Tenant'
                    AND Deposit_Holder__c NOT IN :oldDepositTenantIds
                ];
                
                for(Deposit_Allocation__c depAlloc : movedTenantList) {
                    depAllocToUpdate.add(new Deposit_Allocation__c(Id=depAlloc.Id, Istenantmoved__c=false, Tenencychangeoveramount__c=0));
                    tenantAcctSet.add(depAlloc.Deposit_Holder__c);
                }


                for (Deposit_Allocation__c depAlloc : newDepositTenantList) {
                    newTenantAcctSet.add(depAlloc.Deposit_Holder__c);
                }
                
                // Updating Deposit Allocation
                if(depAllocToUpdate.size()>0) {
                    update depAllocToUpdate;
                }
                
                // Updating Deposit
                Deposit__c updateDeposit = new Deposit__c(Id=depositId, ChangeOver_CaseStatus__c='Tenant changeover cancelled', Tenant_Changeover_Status__c='Reject');
                update updateDeposit;
                
                // Updating Case
                Case updateCase = new Case(Id=CaseId, Case_Statuses__c = 'Tenant changeover cancelled', ChangeOver_Status__c = 'Agent Rejected', 
                                           Respond_Date__c=System.today());
                update updateCase;
                
                // Mailjet code START
                List<EI_MailJetUtility.EmailWrapper> emailWrapperList = new List<EI_MailJetUtility.EmailWrapper>();
                List<EI_MailJetUtility.EmailWrapper> emailWrapperListEWC = new List<EI_MailJetUtility.EmailWrapper>();
                if(scheme.toUpperCase().contains('NI')) 
                {
                    String address ;
                    String dan;
                    address=getCaseDetails[0].Deposit_Account_Number__r.Property_Address__c;
                    dan=getCaseDetails[0].Deposit_Account_Number__r.NI_Deposit_Number__c;
                    // NN-57 AC-10.2
                    if(getCaseDetails[0].Case_Statuses__c == 'Tenant changeover initiated - tenant') {
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                        List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                        
                        // Branch code
                        if (getCaseDetails[0].Deposit_Account_Number__r.Branch__c != null){

                        toAddress = branchEmailMailjet(getCaseDetails[0].Deposit_Account_Number__r.Branch__c);
                        }
                        else{
                        toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        }
                        
                        //toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        toName = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Name;
                        
                        
                        emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, caseId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('user_name',toName);
                        variableMap.put('property_address',address);
                        variableMap.put('DAN',dan); 
                        
                        emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                'NN57AC102ChangeoverCancellAgLL', 'Tenant changeover cancelled - '+ address)); 
                        
                        for(Deposit_Allocation__c depAll :[select id,contact__c,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                           where deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.Id ]){
                                                               toAddressTT = depAll.Contact__r.Email;
                                                               tenantName =  depAll.Contact__r.Name;
                                                               
                                                               List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                                                               
                                                               String email ;
                                                               if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                                   email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                               }
                                                               if(email!=null){
                                                                   emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, caseId,depAll.Contact__c,depAll.Id));       
                                                               }
                                                               if(toAddressTT!=null){
                                                                   emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                                                               }if(email==null && toAddressTT==null){
                                                                   emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                                                               }         
                                                               Map<String, String> variableMap1 = new Map<String, String>();
                                                               variableMap1.put('user_name',tenantName);
                                                               variableMap1.put('property_address',address);
                                                               variableMap1.put('DAN',dan); 
                                                               
                                                               emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                                                       'NN57AC102ChangeoverCancelTT', 'Tenant changeover cancelled - ' + address)); 
                                                               
                                                               
                                                           }
                    } 

                    // NN-58 AC-12.1
                    else if(getCaseDetails[0].Case_Statuses__c == 'Tenant changeover initiated - agent/landlord') {
                        
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                        List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                        // Branch Code
                        if (getCaseDetails[0].Deposit_Account_Number__r.Branch__c != null){

                        toAddress = branchEmailMailjet(getCaseDetails[0].Deposit_Account_Number__r.Branch__c);
                        }
                        else{
                        toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        }
                        
                        //toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        toName = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Name;
                        
                        
                        emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, caseId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('user_name',toName);
                        variableMap.put('property_address',address);
                        variableMap.put('DAN',dan); 
                        
                        emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                'NN58AC121ChangeoverCancelAgLL', 'Tenant changeover cancelled - '+ address)); 
                        
                        for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,contact__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c where deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.Id ]){
                            
                            toAddressTT = depAll.Contact__r.Email;
                            tenantName =  depAll.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientList = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAll.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientList.add(new EI_MailJetUtility.recipient(email, tenantName, caseId,depAll.Contact__c,depAll.Id));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientList.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                            } if(email==null && toAddressTT==null){
                                emailRecipientList.add(new EI_MailJetUtility.recipient('', tenantName, caseId,depAll.Contact__c,depAll.Id)); 
                            }         
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('property_address',address);
                            variableMap1.put('DAN',dan); 
                            
                            emailWrapperList.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientList), variableMap1, 
                                                                                    'NN58AC121ChangeoverCancelTT', 'Tenant changeover cancelled - ' + address)); 
                            
                            
                        } 
                        
                    }
                    
                } 
                // EN 33 Code Tenant Changeover cancelled
               /* else if(scheme.toUpperCase().contains('EW')) 
                {
                    String address ;
                    String dan;
                    address=getCaseDetails[0].Deposit_Account_Number__r.Property_Address__c;
                    dan=getCaseDetails[0].Deposit_Account_Number__r.EWC_Deposit_Number__c;
                    //List<Id> tenantid = new List<Id>();
                   
                    if(getCaseDetails[0].Case_Statuses__c == 'Tenant changeover initiated - tenant') {
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                        List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                        // for Branch code
                        if (getCaseDetails[0].Deposit_Account_Number__r.Branch__c != null){

                        toAddress = branchEmailMailjet(getCaseDetails[0].Deposit_Account_Number__r.Branch__c);
                        }
                        else{
                        toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        }
                        //toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        toName = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Name;
                        
                        
                        emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('Reciepient_Name',toName);
                        variableMap.put('Tenancy_Address',address);
                        variableMap.put('Payment_reference',dan); 
                        
                        emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                'TC_TT_raised_cancelled_by_AA_LL_AA_LL', 'Tenant changeover cancelled –'+ address)); 
                        
                        for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c 
                                                           where deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.Id ]){
                                                               toAddressTT = depAll.Contact__r.Email;
                                                               tenantName =  depAll.Contact__r.Name;
                                                               
                                                               List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                                                               
                                                               String email ;
                                                               if(depAll.Deposit_Holder__r.Additional_Email__c!=null){
                                                                   email = depAll.Deposit_Holder__r.Additional_Email__c;
                                                               }
                                                               if(email!=null){
                                                                   emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));       
                                                               }
                                                               if(toAddressTT!=null){
                                                                   emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,'')); 
                                                               }        
                                                               Map<String, String> variableMap1 = new Map<String, String>();
                                                               variableMap1.put('user_name',tenantName);
                                                               variableMap1.put('Tenancy_Address',address);
                                                               variableMap1.put('Payment_reference',dan); 
                                                               
                                                               emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                                                       'TC_TT_raised_cancelled_by_AA_LL_TT', 'Tenant changeover cancelled –' + address)); 
                                                               
                                                               
                                                           }
                    } 
                    

                    // NN-58 AC-12.1
                       if(getCaseDetails[0].Case_Statuses__c == 'Tenant changeover initiated - agent/landlord') {
                        
                        String toName;
                        String toaddress;
                        String toAddressTT;
                        String tenantName;
                        
                        List<EI_MailJetUtility.recipient> emailRecipientAgLl = new List<EI_MailJetUtility.recipient>();
                        List<EI_MailJetUtility.recipient> emailRecipientTT = new List<EI_MailJetUtility.recipient>();
                        //for Branch code
                        if (getCaseDetails[0].Deposit_Account_Number__r.Branch__c != null){

                        toAddress = branchEmailMailjet(getCaseDetails[0].Deposit_Account_Number__r.Branch__c);
                        }
                        else{
                        toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        }
                        //toAddress = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Email__c;
                        toName = getCaseDetails[0].Deposit_Account_Number__r.Customer__r.Name;
                        
                        
                        emailRecipientAgLl.add(new EI_MailJetUtility.recipient(toAddress, toName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));   
                        Map<String, String> variableMap = new Map<String, String>();
                        variableMap.put('Reciepient_Name',toName);
                        variableMap.put('Tenancy_Address',address);
                        variableMap.put('Payment_reference',dan); 
                        
                        emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientAgLl), variableMap, 
                                                                                'TC_AA_LL_raised_cancelled_AA_LL', 'Tenant changeover cancelled –  '+ address)); 
                        
                        //for(Deposit_Allocation__c depAll :[select id,Istenantmoved__c,Contact__r.Email,Contact__r.Name,Deposit_Holder__r.Additional_Email__c from Deposit_Allocation__c where deposit__c=:getCaseDetails[0].Deposit_Account_Number__r.Id ]){
                         for(Deposit_Allocation__c depAlloc : movedTenantList) {
                            toAddressTT = depAlloc.Contact__r.Email;
                            tenantName =  depAlloc.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAlloc.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAlloc.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,'')); 
                            }        
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('Tenancy_Address',address);
                            variableMap1.put('Payment_reference',dan); 
                            
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                    'TC_AA_LL_raised_cancelled_incoming_TT', 'Tenant changeover cancelled - ' + address)); 
                            
                            
                        } 
                       
                         for (Deposit_Allocation__c depAlloc : newDepositTenantList) {
                            
                            toAddressTT = depAlloc.Contact__r.Email;
                            tenantName =  depAlloc.Contact__r.Name;
                            
                            List<EI_MailJetUtility.recipient> emailRecipientListEWC = new List<EI_MailJetUtility.recipient>();
                            
                            String email ;
                            if(depAlloc.Deposit_Holder__r.Additional_Email__c!=null){
                                email = depAlloc.Deposit_Holder__r.Additional_Email__c;
                            }
                            if(email!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(email, tenantName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,''));       
                            }
                            if(toAddressTT!=null){
                                emailRecipientListEWC.add(new EI_MailJetUtility.recipient(toAddressTT, tenantName, depositId,getCaseDetails[0].Deposit_Account_Number__r.Customer__c,'')); 
                            }        
                            Map<String, String> variableMap1 = new Map<String, String>();
                            variableMap1.put('user_name',tenantName);
                            variableMap1.put('Tenancy_Address',address);
                            variableMap1.put('Payment_reference',dan); 
                            variableMap1.put('Reciepient_Name',toName);
                            emailWrapperListEWC.add(new EI_MailJetUtility.EmailWrapper(JSON.serialize(emailRecipientListEWC), variableMap1, 
                                                                                    'TC_AA_LL_raised_cancel_new_TT', 'Tenant changeover cancelled - ' + address)); 
                            
                            
                        } 
                        
                    }
                    
                }
                */
                if(emailWrapperList.size()>0) {
                    EI_MailJetUtility.sendEmailForNI(JSON.serialize(emailWrapperList));
                }

                if(emailWrapperListEWC.size()>0) {
                    EI_MailJetUtility.sendEmailForEWC(JSON.serialize(emailWrapperListEWC));
                }
                // Mailjet code END
                
                return 'Success';
            }
            else {
                return 'Case not found';
            }
        }
        catch(DmlException e) {
            return 'Failed in Update: ' + e.getMessage();
        }
    }
    
    // Reusable method for accepting the tenant changeover
    public static void acceptChangeover(String depositId, String caseId, Boolean isAcceptedByAgll, String scheme) 
    {
        List<EI_SDS_MailJetUtilityCls.EmailWrapper> emailWrapperList = new List<EI_SDS_MailJetUtilityCls.EmailWrapper>();
        
        List<Installment__c> insertInstallments = new List<Installment__c>();
        
        List<Deposit__c> oldDepositList = [SELECT Id, Name, Customer__r.Email__c, Customer__c, Property_Address_WO_Country__c, Customer__r.Name, 
                                           Property_Address__c,Customer__r.IsPersonAccount, Customer__r.PersonEmail, Tenant_Changeover_Deposit__c, New_Changeover_Deposit__c, 
                                           Final_Protected_Amount__c, Actual_Protected_Amount__c, Change_Overamount_Sum__c, Remaining_Deposit_Amount__c, Payment_Received_By_Scheme__c, 
                                           (SELECT Id, Deposit__c, Deposit__r.Customer__c, Deposit_Holder__r.PersonEmail, Istenantmoved__c, 
                                            Deposit__r.Deposit_Amount__c, Deposit__r.Id, Deposit_Holder__r.Name, Tenencychangeoveramount__c, 
                                            Deposit_Holder__c, Deposit_Holder__r.PersonContactId FROM Deposit_Allocations__r /* WHERE Role__c = 'Tenant' */)
                                           FROM Deposit__c WHERE Id=:depositId  // AND (ChangeOver_CaseStatus__c='Tenant changeover initiated - agent/landlord' OR ChangeOver_CaseStatus__c='Tenant changeover initiated - tenant') 
                                           LIMIT 1];
        
        // System.debug('Line 892 -> '+oldDepositList[0]);
        //  System.debug('Line 893 -> '+oldDepositList[0].New_Changeover_Deposit__c);
        if(!oldDepositList.isEmpty()) 
        {
            Decimal remainingProtectedAmount = oldDepositList[0].Final_Protected_Amount__c - oldDepositList[0].Change_Overamount_Sum__c;
            List<Deposit__c> newdepositlist = [SELECT Id, status__c, Protected_Amount__c FROM deposit__c 
                                               WHERE Id=:oldDepositList[0].New_Changeover_Deposit__c LIMIT 1 ];
            
            Set<Id> tenantAcctSet = new Set<Id>();
            List<Deposit_Allocation__c> oldDepositAllocList = oldDepositList[0].Deposit_Allocations__r;
            for(Deposit_Allocation__c depAlloc : oldDepositAllocList) {
                tenantAcctSet.add(depAlloc.Deposit_Holder__c);
            }
            List<Account> tenantAcctList = [SELECT Id, Name, PersonContactId, Bank_Account_Holder_Name__c, Account_Number__c, Sort_Code__c, Bank_Name__c, 
                                            ValidInternationBankDetails__c, International_Bank_Account_Holder_Name__c, International_Bank_Name__c, 
                                            International_Account_Number__c, BIC__c, Swift_Code__c, IBAN__c, Beneficiary_home_address__c
                                            FROM Account WHERE Id IN:tenantAcctSet];
            System.debug('Line 2457 -> '+tenantAcctSet);
            Map<Id, Account> mapOfTenantAccount = new Map<Id, Account>(tenantAcctList);
            System.debug('Line 2458 -> '+tenantAcctList);
            System.debug('Line 2459 -> '+mapOfTenantAccount);
            // oldDepositList[0].Remaining_Deposit_Amount__c
            if(oldDepositAllocList.size()>0) {
                for(Deposit_Allocation__c dall : oldDepositAllocList) {
                    
                    if(mapOfTenantAccount.containsKey(dall.Deposit_Holder__c))
                    {
                        Account acc = mapOfTenantAccount.get(dall.Deposit_Holder__c);
                        //  System.debug('Line 926 - '+acc);
                        if(dall.Tenencychangeoveramount__c>0) {
                            
                            Installment__c instRec = 
                                EI_NI_UtilityClassForInstallment.getChangeoverInstallments(acc, dall.Tenencychangeoveramount__c, 
                                                                                           oldDepositList[0].Id, caseId, 
                                                                                           oldDepositList[0].Payment_Received_By_Scheme__c, null, 
                                                                                           null, 'Payable', 'Pending Processing', 'Tenant changeover', null, 
                                                                                           null, scheme);
                            
                            if(instRec != null) {
                                insertInstallments.add(instRec);
                            }
                            
                        }
                    }
                }
            }
            
            // Shifting remaining amount from Old Deposit to New Deposit START
            if(remainingProtectedAmount>0 ||Test.isRunningTest()) 
            {
                //      system.debug('Line 967');
                Installment__c instRecForOldDeposit = 
                    EI_NI_UtilityClassForInstallment.getChangeoverInstallments(new Account(), remainingProtectedAmount, 
                                                                               oldDepositList[0].Id, caseId, 
                                                                               oldDepositList[0].Payment_Received_By_Scheme__c, null, 
                                                                               null, 'Payable', 'Paid','Tenant changeover', null, 
                                                                               null, scheme);
                if(instRecForOldDeposit != null) {
                    insertInstallments.add(instRecForOldDeposit);
                }
                
                Installment__c instRecForNewDeposit = 
                    EI_NI_UtilityClassForInstallment.getChangeoverInstallments(new Account(), remainingProtectedAmount, 
                                                                               newdepositlist[0].Id, null, null, null, 
                                                                               null, 'Receivable', 'Collected', 'Tenant changeover', null, 
                                                                               null, scheme);
                if(instRecForNewDeposit != null) {
                    insertInstallments.add(instRecForNewDeposit);
                }
                
            }
            // Shifting remaining amount from Old Deposit to New Deposit END
            
            //  System.debug('Line 765 -> '+insertInstallments.size());
            //System.debug('Line 766 -> '+insertInstallments);
            // Inserting Installments
            if(!insertInstallments.isEmpty()) {
                insert insertInstallments;
                List<Payment__c> insertPaymentList = new List<Payment__c>();
                Id paymentRecordTypeId;
                if(scheme.toUpperCase().contains('NI')) {
                    paymentRecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('NI Custodial Payment').getRecordTypeId();
                } 
                else if(scheme.toUpperCase().contains('EW')) {
                    paymentRecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('EWC Payment').getRecordTypeId();
                }
                
                for(Installment__c inst : insertInstallments) 
                {
                    if(inst.Deposit__c==newdepositlist[0].Id && inst.Deposit__c!=null)
                    {
                        insertPaymentList.add(new Payment__c(Installment__c=inst.Id, DAN__c=inst.Deposit__c, 
                                                             RecordTypeId=paymentRecordTypeId, Amount__c=inst.Amount__c, 
                                                             Payment_Status__c='Paid', Payment_Type__c='Receivable'));
                    }
                    else if(inst.Deposit__c==oldDepositList[0].Id && inst.Deposit__c!=null && inst.Account__c==null && inst.Contact__c==null) 
                    {
                         insertPaymentList.add(new Payment__c(Installment__c=inst.Id, DAN__c=inst.Deposit__c, 
                                                             RecordTypeId=paymentRecordTypeId, Amount__c=inst.Amount__c, 
                                                             Payment_Status__c='Paid', Payment_Type__c='Payable'));
                    }
                }
                if(!insertPaymentList.isEmpty()) {
                    insert insertPaymentList;
                }
            }
            
            List<Deposit__c> updateDepositList = new List<Deposit__c>(); 
            if(oldDepositList.size()>0) {
                Deposit__c newdeposit = new Deposit__c();
                newdeposit.Id = newdepositlist[0].id;
                newdeposit.Status__c = 'Deposits held by scheme';
                newdeposit.Protected_Amount__c = oldDepositList[0].Remaining_Deposit_Amount__c;
                newdeposit.Tenant_Changeover_Status__c = '';
                newdeposit.Previous_Protected_Amount__c = oldDepositList[0].Remaining_Deposit_Amount__c;
                newdeposit.Date_Received_by_Scheme__c = System.today();
                newdeposit.Protection_Start_Date__c = System.today();
                updateDepositList.add(newdeposit);
            }
            
            Set<Id> depoIDListForDPC = new Set<Id>();
            // sprint 3 code change end
            if(!isAcceptedByAgll) {                
                if(oldDepositList.size()>0) {
                    Deposit__c olddeposit = new  Deposit__c(); 
                    olddeposit.Id = oldDepositList[0].id;
                    olddeposit.Status__c = 'Deposit Closed';
                    olddeposit.ChangeOver_CaseStatus__c = 'Tenant changeover accepted'; 
                    olddeposit.Tenant_Changeover_Status__c = 'Approved';
                    olddeposit.Date_Moved__c = System.today();
                    // Create Close_date__c field in dev org
                    olddeposit.Close_date__c = System.today();
                    updateDepositList.add(olddeposit);
                    depoIDListForDPC.add(oldDepositList[0].id);
                }
            }
            
            if(updateDepositList.size()>0) {
                update updateDepositList;
            }
            // En-109
            if(depoIDListForDPC.size()>0) {
                Database.executeBatch(new EI_EWC_DPC_reserveSendEmail_Batch(depoIDListForDPC), 150);
            }
        }
        
    }
    
    // Reusable method for creating updating moved tenants
    public static List<Deposit_Allocation__c> updateMovedTenantOnDepAllocation(String depoAllocList, List<Deposit_Allocation__c> depositAllocationList) 
    {
        List<Deposit_Allocation__c> jsDepAllocList = (List<Deposit_Allocation__c>) System.JSON.deserialize(depoAllocList, List<Deposit_Allocation__c>.class);
        // System.debug('Line 60 -> '+jsDepAllocList);
        
        Map<String, Deposit_Allocation__c> jsDepAllocMap = new Map<String, Deposit_Allocation__c>();
        for(Deposit_Allocation__c depAllocObj : jsDepAllocList) {
            jsDepAllocMap.put(depAllocObj.Id, depAllocObj);
        }
        
        List<Deposit_Allocation__c> updateDepoAllocList = new List<Deposit_Allocation__c>();    
        for(Deposit_Allocation__c dac : depositAllocationList) {
            if(jsDepAllocMap.containsKey(dac.Id)) {
                Deposit_Allocation__c depAlloc = jsDepAllocMap.get(dac.Id);
                if(depAlloc.Istenantmoved__c==true) {
                    dac.Istenantmoved__c = true;
                    dac.Tenencychangeoveramount__c = depAlloc.Tenencychangeoveramount__c;  
                    updateDepoAllocList.add(dac);
                }
                else {
                    dac.Istenantmoved__c = false;
                    dac.Tenencychangeoveramount__c = 0;  
                    updateDepoAllocList.add(dac);
                }
                // Deposit_Allocation__c depAlloc = new Deposit_Allocation__c(Id=dac.Id, );
            }
else if(dac.Role__c=='Relevant Person') {
                updateDepoAllocList.add(dac);
            }
        }
        return updateDepoAllocList;
    }
    
    // Reusable method for creating new Deposit
    @AuraEnabled
    public static String createNewDeposit(String depositId, String newDepositId, List<Account> newTenantAcctList, 
                                          Decimal newdepositamount, Integer newtenantsnumber,
                                          Date newdepositstartdate, Date newdepositenddate, List<Deposit_Allocation__c> updatedDepAllocList, 
                                          String changeoverInitiatedBy, String scheme)
    {
        //   System.debug('Line 1009 -> '+newTenantAcctList+' -> '+newTenantAcctList.size());
        String DAN;
        Map<String,String> emailMembername = new Map<String,String>();
        Map<String,String> tenentAmount = new Map<String,String>();                                        
        List<String> emailDetails = new List<String>();                                        
        
        String message = 'Record created';           
        
        List<Deposit_Allocation__c> newDepAllocList = new list<Deposit_Allocation__c>();
        Deposit__c deplist = [SELECT Id, Name, Branch__c, Property__c, Deposit_Account_Number__c,Customer__c,Contact__c, Customer__r.name,Scheme__C,Status__c,End_Date__c,NI_Deposit_Number__c,
                              Old_Deposit_Number__c, Rent_Amount__c, User_reference_for_the_deposit__c, Protected_Amount__c, Remaining_Deposit_Amount__c,Date_Deposit_Received__c
                              FROM Deposit__c WHERE Id=:depositId LIMIT 1];
        
        DAN = deplist.Deposit_Account_Number__c;
        Deposit__c newdeposit = new Deposit__c();
        
        String schemeType = '';
        if(scheme.toUpperCase().contains('NI')) {
            schemeType = 'NI Custodial Deposit';
        } 
        else if(scheme.toUpperCase().contains('EW')) {
            schemeType = 'EWC Custodial Deposit';
        }
        Id depositRecordTypeId = Schema.SObjectType.Deposit__c.getRecordTypeInfosByName().get(schemeType).getRecordTypeId();
        
        // For inserting or updating the new Deposit
        if(deplist.Property__c !=null && deplist.Customer__c!=null) 
        {
            newDeposit.RecordTypeId = depositRecordTypeId;
            newdeposit.Branch__c = deplist.Branch__c;
            newdeposit.Customer__c = deplist.Customer__c;
            newdeposit.Contact__c = deplist.Contact__c;
            newdeposit.Property__c = deplist.Property__c;
            newdeposit.Scheme__c = deplist.Scheme__c;
            newdeposit.User_reference_for_the_deposit__c = deplist.User_reference_for_the_deposit__c;
            newdeposit.Rent_Amount__c = deplist.Rent_Amount__c;
            newdeposit.Status__c = null;
            newdeposit.Tenant_Changeover_Status__c='In Progress';
            newdeposit.Tenant_Changeover_Deposit__c = depositId;
            newdeposit.Old_Deposit_Number__c = deplist.Name;
            newdeposit.Old_Changeover_Deposit__c = depositId;
            newdeposit.Previous_Protected_Amount__c = deplist.Protected_Amount__c;
            newdeposit.Number_of_Tenants__c = newtenantsnumber;
            newdeposit.Deposit_Amount__c = newdepositamount;
            newdeposit.Start_Date__c = newdepositstartdate;
            newdeposit.End_Date__c = newdepositenddate;
            newdeposit.Status_change_count__c = 0;
            newdeposit.Date_Deposit_Received__c = deplist.Date_Deposit_Received__c;
            newdeposit.Scheme_Type__c = 'Custodial';
            
            if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
                newdeposit.Status__c = '';
                newdeposit.Protected_Amount__c = deplist.Remaining_Deposit_Amount__c;
                newdeposit.Tenant_Changeover_Status__c = '';
            }
            
            // Check if already a deposit for changeover is selected or not
            //system.debug('newDepositId' + newDepositId);
            if(newDepositId != '' && newDepositId != null) {
                newdeposit.Id = newDepositId;
            } 
            upsert newdeposit;
        }
        
        // For creating Deposit Allocations for the new Deposit
        
        if(newdeposit.Id!=null) {
            newNIDAN = [Select id,NI_Deposit_Number__c from Deposit__c where id=:newdeposit.id].NI_Deposit_Number__c;
            newEWCDAN = [Select id,EWC_Deposit_Number__c from Deposit__c where id=:newdeposit.id].EWC_Deposit_Number__c;
            for(Deposit_Allocation__c depAlloc : updatedDepAllocList) {
                //    System.debug('Line 1068 -> '+depAlloc.Deposit_Holder__c);
                if(depAlloc.Role__c=='Tenant' && depAlloc.Istenantmoved__c == false) {
                    Deposit_Allocation__c dact = new  Deposit_Allocation__c();   
                    dact.Deposit_Holder__c = depAlloc.Deposit_Holder__c;
                    dact.Contact__c = depAlloc.Contact__c;
                    dact.Deposit__c = newdeposit.Id;
                    dact.Role__c = 'Tenant';
                    dact.Is_Lead__c = depAlloc.Is_Lead__c;
                    dact.Istenantmoved__c = false;
                    /* Deposit_Allocation__c dactrel = new  Deposit_Allocation__c();   
                    dactrel.Deposit_Holder__c = depAlloc.Deposit_Holder__c;
                    dactrel.Contact__c = depAlloc.Contact__c;
                    dactrel.Deposit__c = newdeposit.Id;
                    dactrel.Role__c = 'Relevant Person';
                    dactrel.Is_Lead__c = depAlloc.Is_Lead__c;
                    dactrel.Istenantmoved__c = false;
                    newDepAllocList.add(dactrel); */
                    newDepAllocList.add(dact);
                }
                else if(depAlloc.Role__c=='Relevant Person') {
                    Deposit_Allocation__c dactrel = new  Deposit_Allocation__c();   
                    dactrel.Deposit_Holder__c = depAlloc.Deposit_Holder__c;
                    dactrel.Contact__c = depAlloc.Contact__c;
                    dactrel.Deposit__c = newdeposit.Id;
                    dactrel.Role__c = 'Relevant Person';
                    dactrel.Is_Lead__c = depAlloc.Is_Lead__c;
                    dactrel.Istenantmoved__c = false;
                    newDepAllocList.add(dactrel);
                }
            }
            // Adding Deposit Allocation for newly created tenants
            if(newTenantAcctList!=null && newTenantAcctList.size()>0) {
                //     System.debug('Line 1080');
                for(Account newTenantAcct : newTenantAcctList) {
                    Deposit_Allocation__c dact = new  Deposit_Allocation__c();                                          
                    dact.Deposit_Holder__c = newTenantAcct.Id;
                    dact.Contact__c = newTenantAcct.PersonContactId;
                    dact.Deposit__c = newdeposit.Id;
                    dact.Role__c = 'Tenant';
                    dact.Is_Lead__c = false;
                    dact.Istenantmoved__c = false;
                    newDepAllocList.add(dact);
                }
            }
            //   System.debug('Line 1091 -> '+newDepAllocList);
            insert newDepAllocList;
        }     
        
        // For updating new Deposit details on the old deposit
        if(newdeposit.id !=null ) {
            Deposit__c olddeposit = new  Deposit__c();
            olddeposit.Id = depositId;
            olddeposit.Tenant_Changeover_Deposit__c=newdeposit.id;
            olddeposit.New_Changeover_Deposit__c=newdeposit.id;
            if(DAN == '') 
            {
                DAN = olddeposit.Deposit_Account_Number__c;
            }
            
            if(changeoverInitiatedBy.toLowerCase().contains('agll')) {
                olddeposit.ChangeOver_CaseStatus__c = 'Tenant changeover initiated - agent/landlord';
                olddeposit.Tenant_Changeover_Status__c='In Progress'; 
            }
            else if(changeoverInitiatedBy.toLowerCase().contains('tenant')) {
                olddeposit.Status__c = 'Deposit Closed';
                olddeposit.ChangeOver_CaseStatus__c = 'Tenant changeover accepted';
                olddeposit.Tenant_Changeover_Status__c = 'Approved';
                olddeposit.Date_Moved__c = System.today();
            } 
            
            update olddeposit;                                        
        }
        
        return message +'='+newdeposit.id; 
    }
    
    // Reusable method for creating new Case and Updating Deposit
    public static String createCaseOnChangeOver(String depositId, List<User> loggedInUser, String partyInitiated, String scheme, String BranchId) 
    {   
        String schemeType = '';
        String caseStatus = '';
        String changeOverStatus = '';
        if(scheme.toUpperCase().contains('NI')) {
            schemeType = 'Dispute NI Custodial';
        } 
        else if(scheme.toUpperCase().contains('EW')) {
            schemeType = 'Dispute EW Custodial';
        }
        
        if(partyInitiated.toLowerCase().contains('agll')) {
            caseStatus = 'Tenant changeover initiated - agent/landlord';
            changeOverStatus = 'Agent Initiate';
        }
        else if(partyInitiated.toLowerCase().contains('tenant')) {
            caseStatus = 'Tenant changeover initiated - tenant';
            changeOverStatus = 'Tenant Initiate';
        }
        // String branchNameId = '';
        // If(BranchId != null){
        //     branchNameId = BranchId;
        // }
        Id caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get(schemeType).getRecordTypeId();
        Case newCase; 
        if(BranchId != null && !String.isBlank(BranchId)){
            
        
        newCase = new Case(Deposit_Account_Number__c=depositId, RecordTypeId=caseRecordType, 
                                AccountId=loggedInUser[0].AccountId, OwnerId=UserInfo.getUserId(), 
                                Case_Statuses__c=caseStatus, ChangeOver_Status__c=changeOverStatus, 
                                Subject='Tenant Changeover request for '+loggedInUser[0].Name, 
                                Description=loggedInUser[0].Name+' has initiated Tenant Changeover', 
                                Scheme__c=scheme, Respond_Date__c=EI_NI_UtilityClassForInstallment.dueDateMethod(System.today(),14), 
                                Origin='Web', Agent_Branch__c = BranchId);
        }
        else{
            newCase = new Case(Deposit_Account_Number__c=depositId, RecordTypeId=caseRecordType, 
            AccountId=loggedInUser[0].AccountId, OwnerId=UserInfo.getUserId(), 
            Case_Statuses__c=caseStatus, ChangeOver_Status__c=changeOverStatus, 
            Subject='Tenant Changeover request for '+loggedInUser[0].Name, 
            Description=loggedInUser[0].Name+' has initiated Tenant Changeover', 
            Scheme__c=scheme, Respond_Date__c=EI_NI_UtilityClassForInstallment.dueDateMethod(System.today(),14), 
            Origin='Web');
        }
        try {
            insert newCase;
            caseIdForMailjet= newCase.Id;
            return caseStatus;
        }
        catch(Exception e) {
                 System.debug('Line 158 error -> '+String.valueOf(e.getMessage()));
            return 'Error '+String.ValueOf(e.getMessage());
        }
    }
    
    @Auraenabled
    public static List<Deposit__c> getDeposit(String searchField,string olddepositid) {
        string houseNo;
        string streetStr;
        string cityStr;
        string countyStr;
        string PostalCodeStr;

        List<String> searchTerms = searchField.split(',');
        if(searchTerms.size() >= 5){
            houseNo = '%' + searchTerms[0] + '%';
            StreetStr = '%' + searchTerms[1] + '%';
            cityStr = '%' + searchTerms[2] + '%';
            countyStr = '%' + searchTerms[3] + '%';
            PostalCodeStr = '%' + searchTerms[4] + '%';
        }else if(searchTerms.size() == 4){
            houseNo = '%' + searchTerms[0] + '%';
            StreetStr = '%' + searchTerms[1] + '%';
            cityStr = '%' + searchTerms[2] + '%';
            countyStr = '%' + searchTerms[3] + '%';
        }else if(searchTerms.size() == 3){
            houseNo = '%' + searchTerms[0] + '%';
            StreetStr = '%' + searchTerms[1] + '%';
            cityStr = '%' + searchTerms[2] + '%';
        }
        else if(searchTerms.size() == 2){
            houseNo = '%' + searchTerms[0] + '%';
            StreetStr = '%' + searchTerms[1] + '%';
        }
        Id accountid = [Select id,Contact.AccountId from User where id=:Userinfo.getUserId()].Contact.AccountId;
        Id contactid = [Select id,ContactId from User where id=:Userinfo.getUserId()].ContactId;
        user u = [select id, accountid, name
        from user
        where id = :UserInfo.getUserId()];
        List<Deposit__c> depositList = new List<Deposit__c>();
        //list<Property__c> prt = new list<Property__c>();
        if((searchField.startsWith('DAN') || searchField.startsWith('dan') || searchField.startsWith('EWC')) && searchTerms.size() == 1){
            string searchkey  = '%' + searchField + '%';
            depositList = [SELECT Id,Name,Status__c,Deposit_Amount__c,Property_Address__c from Deposit__c where  Contact__c =:contactid and id !=:olddepositid and Active__c = true  and (Name like :searchkey) and (Status__c = 'Registered (not paid)' OR Status__c = 'Awaiting payment' OR Status__c = 'Awaiting top-up payment' OR Status__c = 'Deposits held by scheme')];
            // system.debug('+++++++depositList++'+depositList);
            return depositList;
        }else{
            
            system.debug('houseNo->'+houseNo);
            system.debug('StreetStr->'+StreetStr);
            system.debug('cityStr->'+cityStr);
            system.debug('PostalCodeStr->'+PostalCodeStr);
            system.debug('countyStr->'+countyStr);
            
            //searchkey = '%' + searchkeyWithoutCommas + '%';
            /*Map<id, Property__c> propertyMap = new Map<id, Property__c>(
                [select id,Property_status__c, Name,House_No__c,
                 Street__c, City__c, Town__c, No_of_bedrooms__c,
                 Is_Furnished__c, No_of_living_rooms__c, County__c,
                 Country__c, Property_Owner__c, Postal_Code__c                  
                 from Property__c
                 where Property_status__c = 'Active' AND
                 (
                     House_No__c like: houseNo or
                     Street__c like: StreetStr or                 
                     City__c like : cityStr or    
                     Postal_Code__c like : PostalCodeStr or
                     County__c like : countyStr
                 )]);*/
            
            
            String PropertyStatus = 'Active';
            
            //' Property_status__c = \''+PropertyStatus+'\' AND'+
            String bindQuery = 'select id,Property_status__c, Name,House_No__c,'+
                ' Street__c, City__c,'+
                ' County__c,'+
                ' Country__c, Property_Owner__c, Postal_Code__c'+                  
                ' from Property__c where ';
            
            if(houseNo != null){
                bindQuery += ' House_No__c Like ' + '\'%' + String.escapeSingleQuotes(houseNo) + '%\'';
            }
            if(StreetStr != null){
                bindQuery += ' OR Street__c Like ' + '\'%' + String.escapeSingleQuotes(StreetStr) + '%\'';
            }
            if(countyStr != null){
                bindQuery += ' OR County__c Like ' + '\'%' + String.escapeSingleQuotes(countyStr) + '%\'';
            }
            if(cityStr != null){
                bindQuery += ' OR City__c Like ' + '\'%' + String.escapeSingleQuotes(cityStr) + '%\'';
            }
            if(PostalCodeStr != null){
                bindQuery += ' OR Postal_Code__c Like ' + '\'%' + String.escapeSingleQuotes(PostalCodeStr) + '%\'';
            }
            
            system.debug('bindQuery-->'+bindQuery);
            
            Map<id, Property__c> propertyMap = new Map<Id, Property__c>((List<Property__c>)Database.query(  bindQuery));
            
            
            /*for (Property__c property : prt) {
                depositList.addAll(property.Deposits__r);
            }*/
            //   system.debug('depositList' + depositList);
            // system.debug('prt' + prt);
            // 

            depositList = [SELECT Id,Name,Status__c,Deposit_Amount__c,
                           Property_Address__c from Deposit__c 
                           where  Property__c in: propertyMap.keyset() and
                           Contact__c =:contactid and 
                           id !=:olddepositid and
                           Active__c = true and
                           (Status__c = 'Registered (not paid)' OR
                            Status__c = 'Awaiting payment' OR 
                            Status__c = 'Awaiting top-up payment' OR
                            Status__c = 'Deposits held by scheme')];
            
            return depositList;
        }
    }
    
    
    @Auraenabled
    public static List<Deposit__c> getselectedDeposit(string selecteddepositid) {
        List<Deposit__c> depositList = new List<Deposit__c>();
        depositList = [SELECT Id,Name,Status__c,Deposit_Amount__c,Property_Address__c from Deposit__c where  id =:selecteddepositid and Active__c = true and (Status__c = 'Registered (not paid)' OR Status__c = 'Awaiting payment' OR Status__c = 'Awaiting top-up payment' OR Status__c = 'Deposits held by scheme')];
        //  system.debug('+++++++depositList++'+depositList);
        return depositList;
    }
    
    public static String branchEmailMailjet(String branchId) {
    String branchEmail = '';
    if(branchId != null){
    List<Branch__c> branchList =[Select Id, Name, Account__c, Branch_ID__c, Branch_Id2__c, Branch_Name__c, Dispute_resolution_e_mail__c,Finance_e_mail__c, General_correspondence_e_mail__c, Branch_Id3__c from Branch__c where Id =:branchId limit 1];

     branchEmail = branchList[0].General_correspondence_e_mail__c;

        }
        return branchEmail;

    }
    
    // Wrapper classes  
    public class depositwrapper {
        @AuraEnabled public  Deposit__c Depositobject{get; set;}
        @AuraEnabled public  Deposit_Allocation__c Depallobject{get; set;}
        
        public depositwrapper(Deposit__c Depositobject) {
            this.Depositobject = Depositobject;
        }
        
        public depositwrapper(Deposit_Allocation__c Depallobject) {
            this.Depallobject = Depallobject;
        }
        
    }
    
    public class DepositAllocWrapper {
        @AuraEnabled
        public User userRec{get;set;}
        @AuraEnabled
        public Deposit__c depositRec{get;set;}
        @AuraEnabled
        public List<Deposit_Allocation__c> depAllocList{get;set;}
        @AuraEnabled
        public List<Account> acctBankDetailsRec{get;set;}
        @AuraEnabled
        public List<Case> depCaseList{get;set;}
    }
    
    public class FinalWrapper {
        
        @AuraEnabled
        public string tenantYesCheck{get;set;}
        
        @AuraEnabled
        public string tenantNoCheck{ get; set; }
        
        @AuraEnabled
        public String tenantCompanyName{ get; set; }
        
        @AuraEnabled
        public String tenantTitle{ get; set; }
        
        @AuraEnabled
        public String tenantFirstname{ get; set; }
        
        @AuraEnabled
        public String tenantLastname{ get; set; }
        
        @AuraEnabled
        public String tenantEmail{ get; set; }
        
        @AuraEnabled
        public String tenantPhoneCode{ get; set; }
        
        @AuraEnabled
        public String tenantPhone{ get; set; }
        
        @AuraEnabled
        public string currentTenant{ get; set; }
        
        @AuraEnabled
        public string isSaveClick{ get; set; }

        @AuraEnabled
        public string relevantcity{ get; set; }
            
        @AuraEnabled
        public string relevantTown{ get; set; }
            
        @AuraEnabled
        public string relevantPostcode{ get; set; }
            
        @AuraEnabled
        public string relevantCountry{ get; set; }
        
    } 
    
}