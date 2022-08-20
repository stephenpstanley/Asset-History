trigger AssetTrigger on Asset (after insert, after update) {
    //Set the public class variable to show that we are running this trigger
    AssetHistory.inTrigger = true; 

    if (Trigger.isInsert && Trigger.isAfter) {// This should really be extracted into a separate insert records class
        // Holding collection for Asset Change History records
        List<Asset_History__c> newHistories = new List<Asset_History__c>();
        // Iterate through each new Asset record and write a 'Created.' record to the Asset History            
        for (Asset newRec:Trigger.new){
            Asset_History__c newAsset = new Asset_History__c();
            newAsset.Name = newRec.Name;
            newAsset.Field__c = 'Created.';
            newAsset.Asset__c = newRec.Id;
            newHistories.add(newAsset);
        }
        if (newHistories.size() > 0) insert newHistories;
        system.debug (newHistories.size() + ' Asset history records added as a result of ' + Trigger.new.size() + ' new Asset records');
    } // end of separate insert records class
    
    if (Trigger.isUpdate && Trigger.isAfter) {// This should really be extracted into a separate update records class
        // Holding collection for Asset Change History records
        List<Asset_History__c> updHistories = new List<Asset_History__c>();
        // Get the list of editable fields on the Asset Object and save in the collection called editableFields
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get('Asset').getDescribe().fields.getMap();
        List<String> editableFields = new List<String>();
        // Create a Map of fieldname to field label so you can lookup and use the Field label in the history record
        Map<String, String> fieldLabelsMap = new Map<String,String>();
        // Create a Map of fieldname to field type so you can lookup and use the Field type when writing the history
        Map<String, String> fieldTypesMap = new Map<String,String>();  
        // Create a List of all the objects that lookup fields on the Asset Object can refer to
        Map<String,String> LookupObjectsMap = new Map<String,String>();
        for(Schema.SObjectField fieldRef : fields.values()) {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            if(fieldResult.isUpdateable() ) {
                String thisField = fieldResult.getName();
                editableFields.add(thisField);
                fieldLabelsMap.put(thisField,fieldResult.getLabel());
                string fieldType = String.valueOf(fieldResult.getType());
                fieldTypesMap.put(thisField,fieldType);
                system.debug(thisField + ' : ' + fieldResult.getLabel() + ' : ' + fieldType);
                if (fieldType == 'REFERENCE' && !fieldResult.isNamePointing()){
                    string lookupObject = String.valueOf(fieldResult.getReferenceTo());
                    // the object name comes enclosed in parentheses to remove them when saving to LookupObjectsMap
                    LookupObjectsMap.put(thisField,lookupObject.remove('(').remove(')'));
                }
            }
        }
        // Build a map of IDs to Name so you can find the name field from the record ID and save it in the history record 
        // Id's are unique, so you can use a single map for all fields that are looked up
        map<String,String> lookupMap = new map<String,String>();
        // iterate over each lookup field in our LookupObjectsMap and generate and execute a  
        // a dynamic SOQL statement to retrieve the ID and name into our lookupMap
        for (String lookupField:lookupObjectsMap.keyset()){
            // create a set of all the ID's that appear in this lookup field from trigger.old 
            // and trigger.new and add them to a set to use in a where clause in our dynamic query
            Set<ID> idSet = new Set<ID>();
            for (Asset rec:trigger.New) idSet.add(string.valueOf(rec.get(lookupField)));
            for (Asset rec:trigger.Old) idSet.add(string.valueOf(rec.get(lookupField)));
            string SOQLquery = 'Select ID, Name from ' + lookupObjectsMap.get(lookupField) +' Where ID in :idSet' ;
            System.Debug('SOQL statement:' + SOQLquery);
            // execute the query and put the resuts in a list
            list<sObject> sobjList = Database.query(SOQLquery);
            // run through the list and add the ID and Name to lookupMap
            for (sObject sobjRecord:sobjList) lookupMap.put(sobjRecord.ID,string.valueOf(sobjRecord.get('Name')));
        }
        //check the results
        for (string lookupName:lookupMap.keyset()) system.debug(lookupName + ' ; ' + lookupMap.get(lookupName));
        
        // Create Map of new records so that you can identify the changed version of the old record
        // from the old record's ID. You can't rely on the order in oldRecords and newRecords being the same
        Map<Id, Asset> newRecordsMap = new Map<Id, Asset>(Trigger.new);
        //Create set of fields that are part of a Compount Address field as these need to be handled differently
        Set<String> AddressFields = new Set<String>{'Street','City','State','StateCode','PostalCode',
            'Longitude','Latitude','CountryCode','Country',' Accuracy'};
                // Iterate through each Asset record as it was before the update operation            
                for (Asset oldRec:Trigger.old){
                    // for each editable field on the Asset
                    for (string field:editableFields){
                        // check to see if the field has been changed in this record
                        if (oldRec.get(field) != newRecordsMap.get(oldRec.id).get(field)) {
                            system.debug('field tracked: ' + field);
                            system.debug('old value:' + oldRec.get(field) + ' new value: ' + newRecordsMap.get(oldRec.id).get(field));
                            Asset_History__c newAsset = new Asset_History__c();
                            newAsset.Asset__c = oldRec.Id;
                            newAsset.Name = oldRec.Name;
                            // The field label depends on the type of field
                            if (fieldTypesMap.get(field) == 'REFERENCE') {
                                newAsset.Field__c = lookupObjectsMap.get(field); // return the name of the object referred to 
                            } else {
                                newAsset.Field__c = fieldLabelsMap.get(field); // return the label of the field referred to
                            }
                            // The logged changed values depends on the type of field
                            if (fieldTypesMap.get(field) == 'DATE'){ //otherwise it diplays as a date-time
                                newAsset.OldValue__c = string.valueOf(oldRec.get(field)).left(10);
                                newAsset.NewValue__c = string.valueOf(newRecordsMap.get(oldRec.id).get(field)).left(10);
                            } else if (fieldTypesMap.get(field) == 'ENCRYPTEDSTRING'){ // just log it as changed
                                newAsset.OldValue__c = 'XXXXX - ENCRYPTED FIELD - XXXXX';
                                newAsset.NewValue__c = 'XXXXX - ENCRYPTED FIELD - XXXXX';
                            } else if (fieldTypesMap.get(field) == 'BOOLEAN'){
                                if (string.valueOf(oldRec.get(field)) == 'false'){
                                    newAsset.OldValue__c = '\u2610'; // Empty checkbox
                                    newAsset.NewValue__c = '\u2611'; // Checked checkbox
                                } else {
                                    newAsset.OldValue__c = '\u2611'; // Checked checkbox
                                    newAsset.NewValue__c = '\u2610'; // Empty checkbox
                                }
                            } else if (fieldTypesMap.get(field) == 'REFERENCE'){ // get the Name from ID using lookupMap
                                newAsset.OldValue__c = lookupMap.get(string.valueOf(oldRec.get(field)));
                                newAsset.NewValue__c = lookupMap.get(string.valueOf(newRecordsMap.get(oldRec.id).get(field))); 
                            } else {
                                string original = string.valueOf(oldRec.get(field));
                                if (original != NULL){
                                    original = string.valueOf(oldRec.get(field)).abbreviate(255);
                                }
                                string newval = string.valueOf(newRecordsMap.get(oldRec.id).get(field));
                                if (newval != NULL){
                                    newval = string.valueOf(newRecordsMap.get(oldRec.id).get(field)).abbreviate(255);
                                }
                                newAsset.OldValue__c = original;
                                newAsset.NewValue__c = newval;
                            }
                            updHistories.add(newAsset);
                        }
                    } 
                }
        if (updHistories.size() > 0) insert updHistories;
        system.debug (updHistories.size() + ' Asset history records added as a result of ' + Trigger.new.size() + ' updated Asset records');
    }// end of separate update records class
    
}