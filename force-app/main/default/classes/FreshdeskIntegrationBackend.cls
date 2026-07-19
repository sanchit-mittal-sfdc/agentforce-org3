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
    
    


    /**
     * To test this method execute the below in anonymous window
     
    Map<String, Object> response =
        FreshdeskIntegrationBackend.getAllTickets();

    System.debug('Freshdesk response: ' + JSON.serializePretty(response));

     */
    @AuraEnabled
    public static Map<String, Object> getAllTickets()
    {
        String ENDPOINT = 'https://sanchit4010.freshdesk.com/api/v2/tickets?include=description';
        String API_KEY = API_KEY_Integrations__mdt.getInstance('Freshdesk_Integration').API_Key__c;
        String authorizationHeaderValue = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(API_KEY + ':' + 'X'));
        
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        List<Object> mappedRes;
        req.setEndpoint(ENDPOINT);
        req.setmethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', authorizationHeaderValue);
        
        try
        {
            Http h = new Http();
            res = h.send(req);

            mappedRes = (List<Object>)JSON.deserializeUntyped(res.getBody());
            
            Integer statusCode = res.getStatusCode();
            String status = res.getStatus();

            if(statusCode < 200 || statusCode >= 300)
            {
                throw new AuraHandledException('Error fetching tickets from Freshdesk. Status Code: ' + statusCode + ', Status: ' + status + ', Response: ' + JSON.serializePretty(mappedRes));
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
        result.put('ticketsCount', mappedRes.size());
        result.put('tickets', new List<Map<String, Object>>());

        Map<Integer, String> statusIntToString = new Map<Integer, String>{
            2 => 'Open',
            3 => 'Pending',
            4 => 'Resolved',
            5 => 'Closed'
        };

        Map<Integer, String> priorityIntToString = new Map<Integer, String>{
            1 => 'Low',
            2 => 'Medium',
            3 => 'High',
            4 => 'Urgent'
        };

        List<Map<String, object>> listOfTicketsWithFewFields = new List<Map<String, Object>>();
        for(Object ticketObj: mappedRes)
        {   
            Map<String, Object> ticketObjMap = (Map<String, Object>)ticketObj;

            Map<String, Object> ticketObjWithFewFields = new Map<String, Object>();
            
            ticketObjWithFewFields.put('id', ticketObjMap.get('id'));
            ticketObjWithFewFields.put('status', statusIntToString.get((Integer)ticketObjMap.get('status')));
            ticketObjWithFewFields.put('priority', priorityIntToString.get((Integer)ticketObjMap.get('priority')));
            ticketObjWithFewFields.put('subject', ticketObjMap.get('subject'));
            ticketObjWithFewFields.put('description', ticketObjMap.get('description_text'));
            ticketObjWithFewFields.put('created_at', ticketObjMap.get('created_at'));

            //((List<Map<String, Object>>)result.get('tickets')).add(ticketObjWithFewFields);
            listOfTicketsWithFewFields.add(ticketObjWithFewFields);
        }
        result.put('tickets', listOfTicketsWithFewFields);
        return result;
    }
}