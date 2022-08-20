@isTest
public class AssetTriggerTest {
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
                                  Description = 'Initial description for this asset',
                                  IsCompetitorProduct=FALSE,
                                  IsInternal  =TRUE,
                                  InstallDate = date.today()
                                  );
            AssetList.add(Ass);
        }
        Insert AssetList;
    }
    
    @isTest static void checkInsert() {
        test.startTest();
        test.stopTest();
        // validate correct count of asset records were inserted
        List<Asset> assetList = [Select ID from Asset];
        system.assertEquals (assetRecordCount,assetList.size(),
                             assetList.size()+ ' Inserted Asset records found.  Expected ' + assetRecordCount);
        // validate that the correct count of history record were created to log the assert insertions
        List<Asset_History__c> assetHistoryList = [Select ID from Asset_History__c
                                                   where Field__c = 'Created.'];
        system.assertEquals (assetRecordCount,assetHistoryList.size(),
                             assetHistoryList.size()+ ' Inserted Asset History records found.  Expected ' + assetRecordCount);
        
    }
    
    @isTest static void checkUpdate() {
        test.startTest();
        string newContact = 'my New Contact';
        string newAccount = 'my New Account';
        string newAssetName = 'Edited Asset Name';
        string newSerialNumber = 'Edited Serial Number';
        string newDescription = 'Edited description for this asset and made much longer so we can test the ' +
            'abbreviation of the description field.  Lets repeat that text to make sure that the '+
            'total length of the field is well over 255 characters. ' +
            'Edited description for this asset and made much longer so we can test the ' +
            'abbreviation of the description field. Lets repeat that text to make sure that the '+
            'total length of the field is well over 255 characters Lets repeat that text to make ' + 
            'sure that the total length of the field is well over 255 characters. ' +
            'Making the field length to be 475 characters long.';
        
        //Create an account and a contact to change the lookups for
        account acc = new Account(Name = newAccount);
        insert acc;
        contact con = new Contact(Lastname = newContact,
                                  accountID = acc.ID);
        insert con;
        
        // get half the Asset records so we can do updates to them
        integer updRecCount = (integer)math.floor(assetRecordCount/2);
        List<Asset> assetList = [Select ID,ContactID,AccountID,name,SerialNumber,Description,
                                 InstallDate,IsCompetitorProduct 
                                 from Asset 
                                 order by ID ASC 
                                 limit :updRecCount];
        for (Asset ass:assetList){
            ass.AccountID = acc.ID;
            ass.ContactID = con.ID;
            ass.name = newAssetName;
            ass.SerialNumber = newSerialNumber;
            ass.Description = newDescription;
            ass.IsCompetitorProduct=TRUE;
            ass.IsInternal =FALSE;
            ass.InstallDate=date.today().addDays(-1);
        }
        update assetList;
        
        test.stopTest();
        // validate updRecCount asset records were updated
        List<Asset> updRecChk = [Select ID from Asset 
                                 Where ContactID = :con.ID
                                 and AccountID = :acc.ID
                                 and Name = :newAssetName
                                 and SerialNumber = :newSerialNumber];
        
        system.assertEquals (updRecCount,updRecChk.size(),
                             updRecChk.size() + ' Edited Asset records found.  Expected ' + updRecCount);
        //Check Account Lookup edits        
        List<Asset_History__c> assetHistoryChk = [Select ID from Asset_History__c
                                                  where Field__c = 'Account'
                                                  and oldValue__c = 'my Account'
                                                  and newValue__c = :newAccount];
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Account lookup edit.  Expected ' + updRecCount);
        
        //Check Contact Lookup edits
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Contact'
                           and oldValue__c = 'my Contact'
                           and newValue__c = :newContact];
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Contact lookup edit.  Expected ' + updRecCount);
        
        //Check Name edits        
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Asset Name'
                           and oldValue__c = 'Initial Asset Name'
                           and newValue__c = :newAssetName];
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Name field edit.  Expected ' + updRecCount);
        
        
        Asset_History__c verify = [Select Field__c,oldValue__c,newValue__c from Asset_History__c
                                   order by LastModifiedDate  desc
                                   limit 1];
        system.debug(verify.Field__c + '-' + verify.oldValue__c + '-' +verify.newValue__c);
        //Check SerialNumber edits
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Serial Number'
                           and oldValue__c = 'Initial Serial Number'
                           and newValue__c = :newSerialNumber];
        
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for SerialNumber field edit.  Expected ' + updRecCount);
        
        //Check Install Date edits
        string today = string.valueOf(date.today()).left(10);
        string yesterday = string.valueOf(date.today().adddays(-1)).left(10);
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Install Date'
                           and oldValue__c = :today
                           and newValue__c = :yesterday];
        
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Install Date field edit.  Expected ' + updRecCount);

        //Check Competitor Asset edits
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Competitor Asset'
                           and oldValue__c = '\u2610'
                           and newValue__c = '\u2611'];
        
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Competitor Asset field edit.  Expected ' + updRecCount);

        //Check Internal Asset edits
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Internal Asset'
                           and oldValue__c = '\u2611'
                           and newValue__c = '\u2610'];
        
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Internal Asset field edit.  Expected ' + updRecCount);

        
        //Check Description edits
        assetHistoryChk = [Select ID from Asset_History__c
                           where Field__c = 'Description'
                           and oldValue__c = 'Initial description for this asset'
                           and newValue__c = :newDescription.abbreviate(255)];
        
        system.assertEquals (updRecCount,assetHistoryChk.size(),
                             assetHistoryChk.size()+ ' Inserted Asset History records found for Description field edit.  Expected ' + updRecCount);
        
    }
    
}