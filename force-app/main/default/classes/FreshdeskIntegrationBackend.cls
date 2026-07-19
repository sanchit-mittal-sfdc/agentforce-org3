public with sharing class FreshdeskIntegrationBackend
{
    /**
     * To test this method execute the below in anonymous window
     
    Map<String, Object> ticketData = new Map<String, Object>{
        'email' => 'your-email@example.com',
        'subject' => 'Test ticket from Salesforce',
        'description' => 'This Freshdesk ticket was created through Anonymous Apex.',
        'priority' => 1,
        'status' => 2
    };

    Map<String, Object> response =
        FreshdeskIntegrationBackend.createTicket(ticketData);

    System.debug('Freshdesk response: ' + JSON.serializePretty(response));

     */
    @AuraEnabled
    public static Map<String, Object> createTicket(Map<String, Object> ticketData)
    {
        System.debug('ticketData = '+ticketData);
        String ENDPOINT = 'https://sanchit4010.freshdesk.com/api/v2/tickets';
        String API_KEY = API_KEY_Integrations__mdt.getInstance('Freshdesk_Integration').API_Key__c;
        String authorizationHeaderValue = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(API_KEY + ':' + 'X'));
        
        HttpRequest req = new HttpRequest();
        HttpResponse res;
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
            res = h.send(req);

            mappedRes = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            
            Integer statusCode = res.getStatusCode();
            String status = res.getStatus();

            if(statusCode < 200 || statusCode >= 300)
            {
                throw new AuraHandledException('Error creating ticket in Freshdesk. Status Code: ' + statusCode + ', Status: ' + status + ', Response: ' + JSON.serializePretty(mappedRes));
            }   
            
            System.debug(res.getStatusCode());
            System.debug(res.getStatus());            
            System.debug(mappedRes);
        } 
        catch(AuraHandledException e)
        {
            throw e;
        }
        catch (Exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
        finally
        {
            
        }
        Map<String, Object> result = new Map<String, Object>();
        result.put('statusCode', res.getStatusCode());
        result.put('status', res.getStatus());
        result.put('response', mappedRes);
        return result;
    }    
}