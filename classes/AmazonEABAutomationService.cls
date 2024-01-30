/*
    Purpose         :   This class AmazonEABAutomationService is written to make amazone webcallout
                    
    Create By       :   Neha Sharma 
    
    Created Date    :   3/2/2023
    
    Current Version :   V1.0
    
    Revision Log    :   V_1.0 Created - CR-20230116-16885 source 27-12-2023
*/
public without sharing class AmazonEABAutomationService {
    
    //this commented line is for testing purpose only Source 19-12-2023.
    @Future(callout=true)
    public static void makeAmazonServiceEventCallout(List<Id> changeRequestIds, Set<Id> releaseIds,List<String> changeRequestName,String sandboxName)
    {
        /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
        String NAMED_CREDENTIALS_URL_PREFIX = 'callout:';
        String NAMED_CREDENTIALS_API_NAME = 'EABDeploymentAutoAmazonEvent';
        String AmazonEvent_CALLOUT_PREFIX = NAMED_CREDENTIALS_URL_PREFIX + NAMED_CREDENTIALS_API_NAME;
        List<SFDC_Change_Request__c> changeRequsetTobeUpdate = new List<SFDC_Change_Request__c>();
        List<String> toEmailAddress = Label.Deployment_Prcoess_Email_Addresses.split(',');
        system.debug('toEmailAddress-- ' + toEmailAddress);
        
        Http h = new Http();
        HttpResponse res;
        
        try{
            if(changeRequestIds.size() > 0 || releaseIds.size() > 0) 
            {
                HttpRequest req = new HttpRequest();
                req.setMethod(Constants.HTTP_REQUEST_POST_TYPE);
                req.setEndpoint(AmazonEvent_CALLOUT_PREFIX);
                req.setBody( createBody(changeRequestIds,releaseIds));
                req.setHeader(Constants.CONTENT_TYPE, Constants.AMAZON_JSON_CONTENT_TYPE); 
                req.setHeader(Constants.AMZ_TARGET, Constants.AWSEVENTS);
                res = h.send(req);
                System.debug('response ======================'+res);
                if(res.getStatusCode() != 200)
                {
                    
                    /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
                    //create web service log
                    Web_Service_Log__c wsl = new Web_Service_Log__c(RecordTypeId = Schema.SObjectType.Web_Service_Log__c.RecordTypeInfosByDeveloperName.get('Change_Request').RecordTypeId,
                                                                    Status_Code__c = res.getStatusCode() + '  Failure',
                                                                    Web_Service_Class__c = 'AmazonEABAutomationService',
                                                                    Web_Service_Method__c = 'makeAmazonServiceEventCallout',
                                                                    Response_Message__c = 'failed',
                                                                    Change_Request__c = changeRequestIds[0],
                                                                    Request_Sent__c = system.now(),
                                                                    Request_Message_Log__c = req.getBody(),
                                                                    Requested_By__c = UserInfo.getFirstName() + UserInfo.getLastName(),
                                                                    Response_Message_Log__c = String.valueOf(res.getBody()));
                    insert wsl;
                    
                    if(wsl.Id != null)
                    {
                        Web_Service_Log__c webServiceLog = [Select id, name from Web_Service_Log__c where id =: wsl.Id];
                        /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
                        String subject = sandboxName + ' ' + changeRequestName[0] + ' - Deployment Process Failed';
                        String body = '';
                        String emailBody = 'All details related to deployment failure are as follows :';
                        emailBody   += '</br><br><b>Web Service Log : '+ '<a href="'+ URL.getSalesforceBaseUrl().toExternalForm()+ '/' + webServiceLog.Id +'">'+webServiceLog.name+'</a> </b>';
                        emailBody += '</br><b>Change Request Number: </b>'+ changeRequestName[0];
                        emailBody += '</br><b>Target Sandbox Name : </b>' + sandboxName;
                        emailBody += '</br></br>Please connect to the system administrator for more details.';
                        emailBody += '</br></br>Thanks';
                        
                        //EmailHandler.sendEmail(Label.Salesforce_Admin_Email, Label.Amazon_EAB_Automation_Service_Subject,emailBody);
                        EmailHandler.createEmail(toEmailAddress,subject,body,emailBody,true);
                        
                        for(Id changReqId : changeRequestIds)
                        {
                            SFDC_Change_Request__c chngReq = new SFDC_Change_Request__c();
                        	chngReq.Id = changReqId;
                        	chngReq.Stage__c = 'Unable to Execute Automated Deployment';
                            changeRequsetTobeUpdate.add(chngReq);
                        }
                        
                        if(changeRequsetTobeUpdate.size() > 0)
                        {
                            update changeRequsetTobeUpdate;
                        }
                        
                    }
                 
                }
                
        	}
        }
        /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
        catch(Exception exp)
        {
             //create web service log
             Web_Service_Log__c wsl = new Web_Service_Log__c(RecordTypeId = Schema.SObjectType.Web_Service_Log__c.RecordTypeInfosByDeveloperName.get('Change_Request').RecordTypeId,
                                                                    Status_Code__c = res.getStatusCode() + '  Failure',
                                                                    Web_Service_Class__c = 'AmazonEABAutomationService',
                                                                    Web_Service_Method__c = 'makeAmazonServiceEventCallout',
                                                                    Response_Message__c = 'failed',
                                                                    Change_Request__c = changeRequestIds[0],
                                                                    Request_Sent__c = system.now(),
                                                                   // Request_Message_Log__c = req.getBody(),
                                                                    Requested_By__c = UserInfo.getFirstName() + UserInfo.getLastName(),
                                                                    Response_Message_Log__c = String.valueOf(res.getBody()));
                    insert wsl;
                    
                    if(wsl.Id != null)
                    {
                        Web_Service_Log__c webServiceLog = [Select id, name from Web_Service_Log__c where id =: wsl.Id];
                        
                        String subject = sandboxName +' - Deployment process get failed';
                        String body = '';
                        String emailBody = 'All details related to deployment failure are as follows :';
                        emailBody   += '</br><br><b>Web Service Log : '+ '<a href="'+ URL.getSalesforceBaseUrl().toExternalForm()+ '/' + webServiceLog.Id +'">'+webServiceLog.name+'</a> </b>';
                        emailBody += '</br><b>Change Request Number: </b>'+ changeRequestName[0];
                        emailBody += '</br><b>Target Sandbox Name : </b>' + sandboxName;
                        emailBody += '</br></br>Please connect to the system administrator for more details.';
                        emailBody += '</br></br>Thanks';
                        
                        //EmailHandler.sendEmail(Label.Salesforce_Admin_Email, Label.Amazon_EAB_Automation_Service_Subject,emailBody);
                        EmailHandler.createEmail(toEmailAddress, subject,body,emailBody,true);
                        
                        for(Id changReqId : changeRequestIds)
                        {
                            SFDC_Change_Request__c chngReq = new SFDC_Change_Request__c();
                        	chngReq.Id = changReqId;
                        	chngReq.Stage__c = 'Unable to Execute Automated Deployment';
                            changeRequsetTobeUpdate.add(chngReq);
                        }
                        
                        /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
                        
                        if(changeRequsetTobeUpdate.size() > 0)
                        {
                            update changeRequsetTobeUpdate;
                        }
                        
                    }
                
        }
    }
   
    public static string createBody(List<Id> setOfCRIds, Set<Id> setOfReleaseIds)
    {
        String cRIds = '';
        String releaseIds = '';
        
        if(setOfCRIds.size() > 0)
        {
            for(String cRId : setOfCRIds)
            {
                cRIds += '"'+ cRId+ '", ';
            }
             cRIds =  cRIds.remove(',');
        }
        if(setOfReleaseIds.size() > 0)
        {
            for(String releaseId : setOfReleaseIds)
            {
                releaseIds += '"'+ releaseId+ '", ';
            }
            releaseIds =  releaseIds.remove(',');
        }
        /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
        String str = '{ "CR": ['+ cRIds +'], "ReleaseId": ['+ releaseIds +']}';
        JSONGenerator gent = JSON.createGenerator(true);   
        gent.writeStartObject();    
        gent.writeFieldName('Entries'); 
        gent.writeStartArray();
        gent.writeStartObject();      
        gent.writeStringField('Source', 'salesforceevent');
        gent.writeStringField('DetailType','triggerdeployment');
        gent.writeStringField('Detail',str);
        gent.writeStringField('EventBusName','automation-deployment-production');
        gent.writeEndObject();  
        gent.writeEndArray();
        gent.writeEndObject(); 
        String body = gent.getAsString();
        /*V_1.5 - Modified By - Dipesh Gupta - CR-20170907-11182 - 09/13/2017  Updated rollUpDataOnSFDCRelease Method.
			V_1.6 - Modified By - Abhinav Sharma - CR-20170420-10865 - 02/13/2018 - Added a new Method - relateCaseWithCR
			V_1.7 - Modified By - Rajeev Jain - CR-20160809-10094 - 05/30/2018 - method rollUpStorySizeDataOnSFDCRelease modified to rollup story size on Change Request object
			V_1.8 - Modified By - Neha Sharma - 8/3/2014 - CR-20201208-14728 - notifyUserOnCRCancelled - Notify User when CR gets cancelled
			V_1.9 - Modified By - Mahendra Swarnkar - 09/14/2022 - CR-20220901-16526
			V_2.0 - Modified By - Neha Sharma - CR-20230116-16885 - Create New methods - updateEligibleForAutomationDeploymentFieldAccordingToStatus & makeHttpCalloutOnChangeOfStatus
			V_2.1 - Modified By - Chitresh Bhargava - Comment out logic validationOnCRStatusChange and move to validation rule
            		V_2.1 - Modified By - Chirag Soni - 13-04-2023 - CR-20230424-17232 - Removed Commented Code in rollUpDataOnSFDCRelease method - Apex refactoring Phase - 2*/
        return body;
    }  
}