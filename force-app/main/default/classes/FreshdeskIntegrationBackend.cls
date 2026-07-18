public with sharing class FreshdeskIntegrationBackend
{
    @AuraEnabled
    public static Map<String, Object> createTicket(Map<String, Object> ticketData)
    {
        String ENDPOINT = 'https://sanchit4010.freshdesk.com/api/v2/tickets';
        String API_KEY = API_KEY_Integrations__mdt.getInstance('Freshdesk_Integration').API_Key__c;
        String authorizationHeaderValue = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(API_KEY + ':' + 'X'));
        
        HttpRequest req = new HttpRequest();
        Map<String, Object> mappedRes;
        req.setEndpoint(ENDPOINT);
        req.setmethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', authorizationHeaderValue);
        req.setBody(JSON.serialize(ticketData));
        
        try
        {
            Http h = new Http();
            HttpResponse res = h.send(req);

            mappedRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            System.debug(res.getStatusCode());
            System.debug(res.getStatus());
            System.debug(mappedRes);
        } 
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
        finally
        {
            
        }
        return mappedRes;
    }    
}