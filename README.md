
# Asset-History
Salesforce package to recreate Asset History using custom objects and triggers to allow reporting

Salesforce has a standard feature which logs changes to records.

You can select certain fields to track and display the field history in the History related list of an object. When Field Audit Trail isn't enabled, field history data is retained for up to 18 months, and up to 24 months via the API. If Field Audit Trail is enabled, field history data is retained until manually deleted. You can manually delete field history data at any time. Field history tracking data doesn’t count against your data storage limits.

Modifying any of these fields adds an entry to the History related list. All entries include the date, time, nature of the change, and who made the change. Not all field types are available for historical trend reporting. Certain changes, such as case escalations, are always tracked.

Salesforce stores an object’s tracked field history in an associated object called StandardObjectNameHistory or CustomObjectName__History. For example, AccountHistory represents the history of changes to the values of an Account record’s fields. Similarly, MyCustomObject__History tracks field history for the MyCustomObject__c custom object.

Asset seems to be an object where you can track history and can view the change history on a related list on the Asset detail page, but no report type is available to allow you to report on it

This package creates a custom AssetHistory object, manages adding records to the AssetHistory object when the source Asset record is created or edited and allows reporting using a standard report Assets with Histories.

Because it's supposed to be emulating audit history, editing history records is prevented.

By default inserting records is prevented (but can be allowed if a custom permission called "Insert Asset History Records" is assigned to the user). This permission will allow you to load in history if you have already enabled field tracking on the Asset object and can extract existing history using the Salesforce API

Standard history field tracking record do not count towards storage limits, but because this is a custom solution, these records are counted as storage. Since this is intended to be an audit function, by default deleting history records is prevented unless the source Asset is delete (in which case the standard cascade delete process is carried out. If a custom permission called "Delete Asset History Records" is assigned to the user, then history records can be deleted, for example if your retention policies allow you to delete history records after a certain time or if you want to save storage space
