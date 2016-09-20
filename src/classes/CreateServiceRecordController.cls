public with sharing class CreateServiceRecordController {

    public ServiceDto record {get;set;}
    public WorkOrder currentWorkOrder {get;set;}
    
    
    
    public CreateServiceRecordController(ApexPages.StandardController st) {
        record = new ServiceDto();
        currentWorkOrder = (WorkOrder)st.getRecord();
        
    }
    
    public List<SelectOption> getItems() {
            
        List<CKSW_BASE__Service_Type__c> serviceTypes = [SELECT Name FROM CKSW_BASE__Service_Type__c];
        List<SelectOption> options = new List<SelectOption>();
        for (CKSW_BASE__Service_Type__c serviceType: serviceTypes) {    
            options.add(new SelectOption(serviceType.Id,serviceType.Name));
        }    
        return options;
     }
    
    
    public PageReference doCreate(){
        
        List<CKSW_BASE__Service__c> services = new List<CKSW_BASE__Service__c>();
        
        // Query modified by Felipe
        List<WorkOrder> childWorkOrders = [select Territory_Description__c, Street, City, State, 
                                           Country, AccountId, 
                                           Geolocation_for_Services__Longitude__s, Geolocation_for_Services__Latitude__s,
                                           StartDate, EndDate, Subject                                     
                                           from WorkOrder 
                                           where ParentWorkOrderId =:currentWorkOrder.Id];
		
        // Felipe add location, hard coded to Sydney
        List<CKSW_BASE__Location__c> loc = [select Id, Name from CKSW_BASE__Location__c Where Name = 'Sydney' limit 1];
        CKSW_BASE__Location__c loca = loc.get(0);
        
        System.debug('number: '+ record.numberOfAgents);
        System.debug('service type: '+ record.serviceTypeId);
        
        for (WorkOrder childWorkOrder: childWorkOrders) {
            
            for (Integer i=0 ; i<record.numberOfAgents; i++) {
                
                CKSW_BASE__Service__c tempService = new CKSW_BASE__Service__c();
                tempService.CKSW_BASE__Service_Type__c = record.serviceTypeId;
                tempService.Work_Order__c = childWorkOrder.Id;
             	tempService.CKSW_BASE__Location__c = loca.Id;

                // Following changes added by Felipe	
                tempService.CKSW_BASE__Street__c = childWorkOrder.Street;
                tempService.CKSW_BASE__City__c = childWorkOrder.City;
                tempService.CKSW_BASE__State__c = childWorkOrder.State;
                tempService.CKSW_BASE__Country__c = childWorkOrder.Country;
                tempService.CKSW_BASE__Auto_Geocode__c = True;
                tempService.CKSW_BASE__Account__c = childWorkOrder.AccountId;
                tempService.CKSW_BASE__Geolocation__Latitude__s = childWorkOrder.Geolocation_for_Services__Latitude__s;
                tempService.CKSW_BASE__Geolocation__Longitude__s = childWorkOrder.Geolocation_for_Services__Longitude__s;
                tempService.CKSW_BASE__Early_Start__c = childWorkOrder.StartDate;
                tempService.CKSW_BASE__Due_Date__c = childWorkOrder.EndDate;
                tempService.CKSW_BASE__Description__c = childWorkOrder.Subject;
                tempService.Assigned_to_Repeatable_Work_Order__c = True;
                
                services.add(tempService);
            }
        }
        
        System.debug('services: '+ services);
        
        if (services.size()>0) {    
            insert services;
        }
        
        return new PageReference('/'+currentWorkOrder.Id);
    }
    
    
    public class ServiceDto{
        public Integer numberOfAgents {get;set;}
        public String serviceTypeId {get;set;}
    }
}