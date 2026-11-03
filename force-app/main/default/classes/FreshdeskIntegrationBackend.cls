public with sharing class FreshdeskIntegrationBackend {
  private static final String PROMPT_TEMPLATE = 'Generate_TicketDetails_From_Transcript';

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
  public static Map<String, Object> createTicket(
    Map<String, Object> ticketData
  ) {
    System.debug('ticketData = ' + ticketData);
    String ENDPOINT = 'https://sanchit4010.freshdesk.com/api/v2/tickets';
    String API_KEY = API_KEY_Integrations__mdt.getInstance(
        'Freshdesk_Integration'
      )
      .API_Key__c;
    String authorizationHeaderValue =
      'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(API_KEY + ':' + 'X'));

    Map<String, Object> result = new Map<String, Object>();
    HttpRequest req = new HttpRequest();
    HttpResponse res;
    Map<String, Object> mappedRes;
    req.setEndpoint(ENDPOINT);
    req.setmethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setHeader('Authorization', authorizationHeaderValue);
    req.setBody(JSON.serialize(ticketData));

    Integer statusCode;

    try {
      Http h = new Http();
      res = h.send(req);

      mappedRes = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

      statusCode = res.getStatusCode();
      String status = res.getStatus();

      if (statusCode < 200 || statusCode >= 300) {
        //throw new AuraHandledException('Error creating ticket in Freshdesk. Status Code: ' + statusCode + ', Status: ' + status + ', Response: ' + JSON.serializePretty(mappedRes));

        //If ticket creation in freshdesk is not successfuly then we will create it in sf itself as a fallback mechanism. So we will not throw an exception here. Instead we will return the response to the LWC and handle it there.
        Case c = new Case();
        system.debug('statussss=' + ticketData.get('status'));
        Decimal statusVal = (Decimal) ticketData.get('status');
        system.debug('status = ' + statusVal);
        c.Status = (statusVal == 2
          ? 'New'
          : statusVal == 3 ? 'Working' : statusVal == 4 ? 'Closed' : 'New');
        c.Subject = (String) ticketData.get('subject');
        c.Description = (String) ticketData.get('description');
        c.Origin = 'Web';
        c.Priority = (Decimal) ticketData.get('priority') == 1
          ? 'Low'
          : (Decimal) ticketData.get('priority') == 2
              ? 'Medium'
              : (Decimal) ticketData.get('priority') == 3 ? 'High' : 'High';
        insert c;

        result.put('statusCode', 200); // we are returning 200 here because we have created the ticket in sf as a fallback mechanism. So we want to return 200 to the LWC so that it can show a success message to the user. If we return the actual status code from freshdesk, then the LWC will show an error message to the user even though the ticket has been created in sf.
        result.put('status', 'Created in Salesforce as fallback');
        Id caseId = c.Id;
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :caseId][0]
        .CaseNumber;
        system.debug('caseNumber=' + caseNumber);
        result.put(
          'response',
          new Map<String, Object>{ 'id' => caseId, 'caseNumber' => caseNumber }
        );
      }

      System.debug(res.getStatusCode());
      System.debug(res.getStatus());
      System.debug('mappedresponse11 is' + mappedRes);
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    } finally {
    }

    if (statusCode >= 200 && statusCode < 300) {
      result.put('statusCode', statusCode);
      result.put('status', res.getStatus());
      result.put('response', mappedRes);
    }

    return result;
  }

  /**
     * To test this method execute the below in anonymous window
     
    Map<String, Object> response =
        FreshdeskIntegrationBackend.getAllTickets();

    System.debug('Freshdesk response: ' + JSON.serializePretty(response));

     */
  @AuraEnabled
  public static Map<String, Object> getAllTickets() {
    String ENDPOINT = 'https://sanchit4010.freshdesk.com/api/v2/tickets?include=description';
    String API_KEY = API_KEY_Integrations__mdt.getInstance(
        'Freshdesk_Integration'
      )
      .API_Key__c;
    String authorizationHeaderValue =
      'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(API_KEY + ':' + 'X'));

    HttpRequest req = new HttpRequest();
    HttpResponse res;
    List<Object> mappedRes;
    req.setEndpoint(ENDPOINT);
    req.setmethod('GET');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setHeader('Authorization', authorizationHeaderValue);

    try {
      Http h = new Http();
      res = h.send(req);

      mappedRes = (List<Object>) JSON.deserializeUntyped(res.getBody()); // cant use List<Map<String, Object>> because the response is a list of objects, not a list of maps. You might be thinking that obj itself is a map, but it is not. It is an object that can be cast to a map. So we need to cast it to a list of objects first, and then cast each object to a map when we need to access its fields.

      Integer statusCode = res.getStatusCode();
      String status = res.getStatus();

      if (statusCode < 200 || statusCode >= 300) {
        //throw new AuraHandledException('Error fetching tickets from Freshdesk. Status Code: ' + statusCode + ', Status: ' + status + ', Response: ' + JSON.serializePretty(mappedRes));
        //If fetching tickets from freshdesk is not successfuly then we will fetch it from sf itself as a fallback mechanism. So we will not throw an exception here. Instead we will return the response to the LWC and handle it there.
        List<Case> cases = [
          SELECT
            Id,
            CaseNumber,
            Status,
            Subject,
            Description,
            Priority,
            CreatedDate
          FROM Case
          ORDER BY CreatedDate DESC
        ];
        List<Map<String, Object>> listOfCasesWithFewFields = new List<Map<String, Object>>();
        for (Case c : cases) {
          Map<String, Object> caseObjWithFewFields = new Map<String, Object>();
          caseObjWithFewFields.put('id', c.Id);
          caseObjWithFewFields.put('caseNumber', c.CaseNumber);
          caseObjWithFewFields.put('status', c.Status);
          caseObjWithFewFields.put('subject', c.Subject);
          caseObjWithFewFields.put('description', c.Description);
          caseObjWithFewFields.put('priority', c.Priority);
          caseObjWithFewFields.put('created_at', c.CreatedDate);
          listOfCasesWithFewFields.add(caseObjWithFewFields);
        }
        Map<String, Object> result = new Map<String, Object>();
        result.put('statusCode', 200); // we are returning 200 here because we have fetched the tickets from sf as a fallback mechanism. So we want to return 200 to theLWC so that it can show a success message to the user. If we return the actual status code from freshdesk, then the LWC will show an error message to the user even though the tickets have been fetched from sf.
        result.put('status', 'Fetched from Salesforce as fallback');
        result.put('ticketsCount', listOfCasesWithFewFields.size());
        result.put('tickets', listOfCasesWithFewFields);
        return result;
      }

      System.debug(res.getStatusCode());
      System.debug(res.getStatus());
      System.debug(mappedRes);
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      //throw new AuraHandledException(e.getMessage()); // we are specially throwing AuraHandledException here because we want to handle this exception in the LWC and show a toast message to the user. If we throw a generic exception, it will be handled by the platform and the user will see a generic error message. if we throw normal Exception then in lwc inisde .then. catch block we will not be able to catch it and show a toast message to the user. So we are throwing AuraHandledException here so that we can catch it in the LWC and show a toast message to the user.
      List<Case> cases = [
        SELECT
          Id,
          CaseNumber,
          Status,
          Subject,
          Description,
          Priority,
          CreatedDate
        FROM Case
        ORDER BY CreatedDate DESC
      ];
      List<Map<String, Object>> listOfCasesWithFewFields = new List<Map<String, Object>>();
      for (Case c : cases) {
        Map<String, Object> caseObjWithFewFields = new Map<String, Object>();
        caseObjWithFewFields.put('id', c.Id);
        caseObjWithFewFields.put('caseNumber', c.CaseNumber);
        caseObjWithFewFields.put('status', c.Status);
        caseObjWithFewFields.put('subject', c.Subject);
        caseObjWithFewFields.put('description', c.Description);
        caseObjWithFewFields.put('priority', c.Priority);
        caseObjWithFewFields.put('created_at', c.CreatedDate);
        listOfCasesWithFewFields.add(caseObjWithFewFields);
      }
      Map<String, Object> result = new Map<String, Object>();
      result.put('statusCode', 200); // we are returning 200 here because we have fetched the tickets from sf as a fallback mechanism. So we want to return 200 to theLWC so that it can show a success message to the user. If we return the actual status code from freshdesk, then the LWC will show an error message to the user even though the tickets have been fetched from sf.
      result.put('status', 'Fetched from Salesforce as fallback');
      result.put('ticketsCount', listOfCasesWithFewFields.size());
      result.put('tickets', listOfCasesWithFewFields);
      return result;
    } finally {
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
    for (Object ticketObj : mappedRes) {
      Map<String, Object> ticketObjMap = (Map<String, Object>) ticketObj;

      Map<String, Object> ticketObjWithFewFields = new Map<String, Object>();

      ticketObjWithFewFields.put('id', ticketObjMap.get('id'));
      ticketObjWithFewFields.put(
        'status',
        statusIntToString.get((Integer) ticketObjMap.get('status'))
      ); // why am i not using Integer.valueOf(ticketObjMap.get('status')) here? Because ticketObjMap.get('status') returns an Object, and we need to cast it to Integer before we can use it as a key in the map. If we use Integer.valueOf(ticketObjMap.get('status')), it will throw a ClassCastException because ticketObjMap.get('status') is not a String, it is an Object. So we need to cast it to Integer first, and then use it as a key in the map. diff between casting i.e (Integer)ticketObjMap.get('status') and Integer.valueOf(ticketObjMap.get('status')) is that the former is a cast, and the latter is a method call. The cast will throw a ClassCastException if the object is not of the specified type, while the method call will throw a NumberFormatException if the object cannot be converted to an Integer. In this case, we are sure that ticketObjMap.get('status') will return an Integer, so we can safely cast it to Integer. For eg, if ticketObjMap.get('status') returns 2, then (Integer)ticketObjMap.get('status') will return 2, while Integer.valueOf(ticketObjMap.get('status')) will throw a NumberFormatException because it cannot convert an Object to an Integer. So we are using the cast here instead of the method call. Integer.value of accepts an argument of type String, and returns an Integer. It does not accept an argument of type Object. So we cannot use Integer.valueOf(ticketObjMap.get('status')) here because ticketObjMap.get('status') returns an Object, not a String. We need to cast it to Integer first, and then use it as a key in the map. So we are using (Integer)ticketObjMap.get('status') here instead of Integer.valueOf(ticketObjMap.get('status')).
      ticketObjWithFewFields.put(
        'priority',
        priorityIntToString.get((Integer) ticketObjMap.get('priority'))
      );
      ticketObjWithFewFields.put('subject', ticketObjMap.get('subject'));
      ticketObjWithFewFields.put(
        'description',
        ticketObjMap.get('description_text')
      );
      ticketObjWithFewFields.put('created_at', ticketObjMap.get('created_at'));

      //((List<Map<String, Object>>)result.get('tickets')).add(ticketObjWithFewFields);
      listOfTicketsWithFewFields.add(ticketObjWithFewFields);
    }
    result.put('tickets', listOfTicketsWithFewFields);
    return result;
  }

  /**
     * To test this method execute the below in anonymous window
     * 
        String voiceTranscript = 'Hello, I am facing an issue with my account. I cannot log in and I need help to reset my password.';
        String ticketDetails = FreshdeskIntegrationBackend.generateTicketDetailsFromVoiceTranscriptUsingAi(voiceTranscript);
        System.debug('Generated Ticket Details: ' + ticketDetails);
     * */
  @AuraEnabled
  public static AiOutputWrapper generateTicketDetailsFromVoiceTranscriptUsingAi(
    String voiceTranscript
  ) {
    // Create inputs
    //Map<String, String> inputMap = new Map<String, String>();
    //inputMap.put('voiceTranscript', voiceTranscript); // Imp this wont work

    /**
     * VV Imp concept: If you are just using free text as input in Flex Prompt template with no sobject, then you can directly pass the string as input to the template. But if you are using sobject in the template, then you need to pass the sobject as input to the template. In that case, you need to create a map of sobject fields and values and pass it as input to the template. The key in the map should be the field name and the value should be the field value. The key should match with the field name in the sobject used in the template. If you are using a custom sobject, then you need to pass the API name of the custom sobject as key in the map and the value should be a map of field names and values. The key in the inner map should be the field name and the value should be the field value. The key should match with the field name in the custom sobject used in the template.
     */

    ConnectApi.WrappedValue voiceTranscriptValue = new ConnectApi.WrappedValue();
    //voiceTranscriptValue.value = inputMap;
    voiceTranscriptValue.value = voiceTranscript;

    Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
    inputParams.put('Input:voiceTranscript', voiceTranscriptValue);

    // Configure invocation parameters
    ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
    //set temperature to 0.7 for more creative responses, you can adjust this value as needed
    executeTemplateInput.additionalConfig.temperature = 2.0;
    executeTemplateInput.isPreview = false;
    executeTemplateInput.inputParams = inputParams;

    try {
      // Call the service
      ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
        PROMPT_TEMPLATE,
        executeTemplateInput
      );
      ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];

      String jsonResponseString = response.text;

      System.debug(JSON.serializePretty(jsonResponseString));

      AiOutputWrapper aiOutput = (AiOutputWrapper) JSON.deserialize(
        jsonResponseString,
        AiOutputWrapper.class
      );

      return aiOutput;
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw new AuraHandledException(
        'Error generating ticket details from voice transcript using AI: ' +
        e.getMessage()
      );
    }
  }

  public class AiOutputWrapper {
    @AuraEnabled
    public String subject { get; set; }

    @AuraEnabled
    public String description { get; set; }

    @AuraEnabled
    public ConfidenceWrapper confidence { get; set; }
  }

  public class ConfidenceWrapper {
    @AuraEnabled
    public String level { get; set; }

    @AuraEnabled
    public String reason { get; set; }
  }
}
