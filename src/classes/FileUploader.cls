public class FileUploader 
{
    public string nameFile{get;set;}
    public Blob contentFile{get;set;}
    String[] filelines = new String[]{};
    List<WorkOrder> workorderupload;
    
    private final WorkOrder parent;
    
    public FileUploader(ApexPages.StandardController st) {    
        WorkOrder wo = (WorkOrder)st.getRecord();
        this.parent = [Select AccountId, Subject, Id FROM WorkOrder Where Id = :wo.Id];
    }
    
    /***This function reads the CSV file and inserts records into the Account object. ***/
    public Pagereference ReadFile()
    {
        try {
                //Convert the uploaded file which is in BLOB format into a string
                nameFile =blobToString( contentFile,'ISO-8859-1');
                
                workorderupload = new List<WorkOrder>();
                List<List<String>> model = parseCSV(nameFile, true);
            
                for (List<String> lineModel: model) {
                  WorkOrder newWorkOrder = new WorkOrder();
                    
                  newWorkOrder.Street = lineModel.get(1) +' '+lineModel.get(2);
                  newWorkOrder.City = lineModel.get(3);
                  newWorkOrder.Country = lineModel.get(4);
                  newWorkOrder.PostalCode = lineModel.get(5);
                  
                  if (String.isBlank(lineModel.get(8))) {
                      newWorkOrder.StartDate = DateTime.now();
                  }
                  else{
                   //  String[] strDate = lineModel.get(8).split('/');
                   //  Integer myIntDate = integer.valueOf(strDate[0]);
                   //  Integer myIntMonth = integer.valueOf(strDate[1]);
                   //  Integer myIntYear = integer.valueOf(strDate[2]);
                   //  newWorkOrder.StartDate  = DateTime.newInstance(myIntYear, myIntMonth, myIntDate);
                       System.debug(lineModel.get(8));
                       newWorkOrder.StartDate = DateTime.parse(lineModel.get(8));
                  }
                    
                  if (String.isBlank(lineModel.get(9))) {
                     
                      newWorkOrder.EndDate =  newWorkOrder.StartDate.addDays(14);
                  }else {
                    //  String[] endDate = lineModel.get(9).split('/');
                    //  Integer myIntDate = integer.valueOf(endDate[0]);
                    //  Integer myIntMonth = integer.valueOf(endDate[1]);
                    //  Integer myIntYear = integer.valueOf(endDate[2]);
                    //  newWorkOrder.EndDate  = DateTime.newInstance(myIntYear, myIntMonth, myIntDate);
                        System.debug(lineModel.get(9));
                        newWorkOrder.EndDate = DateTime.parse(lineModel.get(9));
                      
                  }
                  newWorkOrder.Territory_Description__c =  lineModel.get(10);
                    
                    // Felipe getting geo from Spreadsheet
					newWorkOrder.Geolocation_for_Services__latitude__s = Double.valueOf(lineModel.get(11));
            		newWorkOrder.Geolocation_for_Services__longitude__s = Double.valueOf(lineModel.get(12));
                    
                  Integer recordIndex= Integer.valueOf(lineModel.get(0));
                  if (recordIndex<10) {
                      newWorkOrder.Subject = parent.Subject+' - 0' + lineModel.get(0);
                  }
                  else{
                      newWorkOrder.Subject = parent.Subject+' - ' + lineModel.get(0);  
                  }
                  newWorkOrder.RecordTypeId = '01228000000mHCl';
                  newWorkOrder.ParentWorkOrderId = parent.Id;
                  
                    // added by Felipe
                  newWorkOrder.AccountId = parent.AccountId;
                  	// end of added by Felipe

                  workorderupload.add(newWorkOrder);
                
                }
                
            
                
         }
			catch(Exception e){
			ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured reading the CSV file'+e.getMessage());
            ApexPages.addMessage(errormsg);
            system.debug('Error: ' + errormsg);
         }       
        //Finally, insert the collected records
        try{
            insert workorderupload;
        }
        catch (Exception e)
        {
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured inserting the records'+e.getMessage());
            ApexPages.addMessage(errormsg);
            system.debug('Error: ' + errormsg);
        }    
       PageReference returnPage = new PageReference('/'+parent.Id);  
       return returnPage;
    }
    
    
    public static List<List<String>> parseCSV(String contents,Boolean skipHeaders) {
            List<List<String>> allFields = new List<List<String>>();
        
            // replace instances where a double quote begins a field containing a comma
            // in this case you get a double quote followed by a doubled double quote
            // do this for beginning and end of a field
            contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
            // now replace all remaining double quotes - we do this so that we can reconstruct
            // fields with commas inside assuming they begin and end with a double quote
            contents = contents.replaceAll('""','DBLQT');
            // we are not attempting to handle fields with a newline inside of them
            // so, split on newline to get the spreadsheet rows
            List<String> lines = new List<String>();
            try {
                lines = contents.split('\n');
            } catch (System.ListException e) {
                System.debug('Limits exceeded?' + e.getMessage());
            }
            Integer num = 0;
            for(String line : lines) {
                // check for blank CSV lines (only commas)
                if (line.replaceAll(',','').trim().length() == 0) break;
                
                List<String> fields = line.split(',');	
                List<String> cleanFields = new List<String>();
                String compositeField;
                Boolean makeCompositeField = false;
                for(String field : fields) {
                    if (field.startsWith('"') && field.endsWith('"')) {
                        cleanFields.add(field.replaceAll('DBLQT','"'));
                    } else if (field.startsWith('"')) {
                        makeCompositeField = true;
                        compositeField = field;
                    } else if (field.endsWith('"')) {
                        compositeField += ',' + field;
                        cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                        makeCompositeField = false;
                    } else if (makeCompositeField) {
                        compositeField +=  ',' + field;
                    } else {
                        cleanFields.add(field.replaceAll('DBLQT','"'));
                    }
                }
                
                allFields.add(cleanFields);
            }
            if (skipHeaders) allFields.remove(0);
            return allFields;		
        }

        /**
         This function converts the input CSV file in BLOB format into a string
        @param input    Blob data representing correct string in @inCharset encoding
        @param inCharset    encoding of the Blob data (for example 'ISO 8859-1')
     */
    public static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }         
}