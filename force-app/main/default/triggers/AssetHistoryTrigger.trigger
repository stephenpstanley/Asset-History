trigger AssetHistoryTrigger on Asset_History__c (before insert, before update, before delete) {
    // prevent any modification to history records other than by the AssetTrigger
    if (!AssetHistory.inTrigger){// Unless this trigger has been fired because of the Asset trigger causing insert or deletion
        if (Trigger.isDelete && !FeatureManagement.checkPermission('Delete_Asset_History_Records')) { // only allow deletion if custom perm is assigned
            for (Asset_History__c records:Trigger.old) records.addError('Deleting history is not permitted except when the source asset is deleted'); 
        }
        if (Trigger.isInsert && !FeatureManagement.checkPermission('Insert_Asset_History_Records')) {// only allow insert if custom perm is assigned
            for (Asset_History__c records:Trigger.new) records.addError('Inserting history records is not permitted other than by editing the source asset'); 
        }
        if (Trigger.isUpdate) // never allow standalone editing of audit history
            for (Asset_History__c records:Trigger.new) records.addError('Editing history records manually is not permitted'); 
    }
}