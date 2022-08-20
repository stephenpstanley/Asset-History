@isTest
public class AssetHistoryTriggerTest {
    private static final Integer assetRecordCount = 300;
    
    @testSetup static void setup() {
        // Create an account and a contact to use to populate lookup fields
        account acc = new Account(Name = 'my Account');
        insert acc;
        contact con = new Contact(Lastname = 'my Contact',
                                  accountID = acc.ID);
        insert con;
        // Create recordCount assets
        list<Asset> AssetList = new list<Asset>();
        for (integer i = 0; i< assetRecordCount; i++){
            Asset Ass = new Asset(Name = 'Initial Asset Name',
                                  AccountId  = acc.ID,
                                  ContactId = con.ID,
                                  Quantity  = 1,
                                  SerialNumber = 'Initial Serial Number',
                                  Description = 'Initial description for this asset');
            AssetList.add(Ass);
        }
        Insert AssetList;
    }
    
    private static boolean insertAssetHistory() {
        // Get a parent asset ID
        Asset parentAsset = [Select ID, name from Asset Limit 1];
        // Create a history record
        try {
            Insert new Asset_History__c(Name = parentAsset.Name,
                                        Asset__c = parentAsset.ID,
                                        Field__c = 'Serial Number',
                                        OldValue__c = 'Some Number',
                                        NewValue__c = 'Some Other Number');
            Return TRUE;
        } catch (DmlException ex){
            Boolean correctMessage = ex.getMessage().contains('Inserting history records is not permitted other than by editing the source asset');
            System.assert(correctMessage,'We got an unexpected Exception message'); 
            Return FALSE;
        }
    }
    
    private static boolean updateAssetHistory() {
        // Query a history record
        Asset_History__c histRec = [Select ID, Name, Asset__c, Field__c, OldValue__c, NewValue__c
                                    FROM Asset_History__c LIMIT 1];
        system.assertNotEquals(NULL, histRec,'Unable to find a history record to try to update');
        
        try {
            histRec.Name = histRec.Name + 'edit';
            histRec.Field__c = histRec.Field__c + 'edit';
            histRec.OldValue__c = histRec.OldValue__c + 'edit';
            histRec.NewValue__c = histRec.NewValue__c + 'edit';
            update histRec;
            System.debug('Einsteins relativity theory has been broken. We managed to alter history!');
            Return TRUE;
        } catch (DmlException ex){
            Boolean correctMessage = ex.getMessage().contains('Editing history records manually is not permitted');
            System.assert(correctMessage,'We got an unexpected Exception message');
            System.debug('The world is safe, we could not change history!');
            Return FALSE;
        }
    }
    
    private static boolean deleteAssetHistory() {
        // Query a history record
        Asset_History__c histRec = [Select ID, Name, Asset__c, Field__c, OldValue__c, NewValue__c
                                    FROM Asset_History__c LIMIT 1];
        system.assertNotEquals(NULL, histRec,'Unable to find a history record to try to delete');
        
        try {
            delete histRec;
            Return TRUE;
        } catch (DmlException ex){
            Boolean correctMessage = ex.getMessage().contains('Deleting history is not permitted except when the source asset is deleted');
            System.assert(correctMessage,'We got an unexpected Exception message');
            Return FALSE;
        }
    }
    
    public static void activateCustomPerm(Id userId, String permissionName) {
        PermissionSet ps = new PermissionSet(Name = 'CustomPermissionEnabled', Label = 'Custom Permisison Enabled');
        insert ps;
        
        SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id,
                                                      SetupEntityId = [SELECT Id
                                                                       FROM CustomPermission
                                                                       WHERE DeveloperName = :permissionName
                                                                       LIMIT 1].Id);
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId,
                                                                  PermissionSetId = ps.Id);
        insert new List<SObject>{ sea, psa };
     }
    
    @isTest static void insertWithPermission() {
        string insertPermissionDeveloperName = 'Insert_Asset_History_Records'; 
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        insert u;
        // Add the insert custom permission to our user
        activateCustomPerm(u.ID,insertPermissionDeveloperName);
        // now verify that we can insert a history record
        System.runAs(u) {
            system.assert(insertAssetHistory(),'Failed to insert an Asset History record despite having permission to do so');
        }
    }
    
    @isTest static void insertWithoutPermission() {
        system.assert(!insertAssetHistory(),'Succeeded in inserting an Asset History record despite NOT having permission to do so');
    }
    
    @isTest static void deleteWithPermission() {
        string deletePermissionDeveloperName = 'Delete_Asset_History_Records'; 
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        insert u;

        // Add the insert custom permission to our user
        activateCustomPerm(u.ID,deletePermissionDeveloperName);
        // now verify that we can insert a history record
        System.runAs(u) {
            system.assert(deleteAssetHistory(),'Failed to delete an Asset History record despite having permission to do so');
        }
    }
    
    @isTest static void deleteWithoutPermission() {
        system.assert(!deleteAssetHistory(),'Succeeded in deleting an Asset History record despite NOT having permission to do so');
    }
    
    @isTest static void updateHistory() {
        system.assert(!updateAssetHistory(),'Succeeded in updating an Asset History record despite NOT having permission to do so');
    }
}