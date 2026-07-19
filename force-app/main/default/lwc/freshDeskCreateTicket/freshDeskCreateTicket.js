import { api, track, LightningElement } from 'lwc';
import createTicketInFreshdesk from '@salesforce/apex/FreshdeskIntegrationBackend.createTicket';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const STATUS_OPTIONS = [
    {
        label: "Open", value: 2
    },
    {
        label: "Pending", value: 3
    },
    {
        label: "Resolved", value: 4
    },
    {
        label: "Closed", value: 5
    }
];

const PRIORITY_OPTIONS = [
    
    {
        label: "Low", value: 1
    },
    {
        label: "Medium", value: 2
    },
    {
        label: "High", value: 3
    },
    {
        label: "Urgent", value: 4
    }
];

export default class FreshDeskCreateTicket extends LightningElement {
    isLoading = false;
    @api pageTitle = 'Create Freshdesk Ticket';
    statusOptions = STATUS_OPTIONS;
    priorityOptions = PRIORITY_OPTIONS;
    @track ticketData = {
        email: null,
        subject: null,
        description: null,
        status: null,
        priority: null
    }


    handleInputChange(event)
    {
        debugger;
        const { name, value } = event.target;
        const numericFields = ['status', 'priority'];
        this.ticketData[name] = numericFields.includes(name) ? parseInt(value) : (value.trim() === '' ? null: value.trim());
    }


    validateFields(event)
    {
        debugger;
        // If the event is passed, it means we are validating a single field on blur
        if(event)
        {
            const { name, value } = event.target;
            if(value === null || value === undefined || (typeof value === 'string' && value.trim() === '') )
            {
                event.target.setCustomValidity('This field is required');
            }
            else
            {
                event.target.setCustomValidity(''); // Clear any previous error message
            }
            
            event.target.reportValidity(); // this will show the error message if the field is invalid
            return;
        }
        
        // This part is for validating all fields when the user clicks the submit button
        let allValid = true;

        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(inputField => {
            
            if(inputField.required && (inputField.value === null || inputField.value === undefined || (typeof inputField.value === 'string' && inputField.value.trim() === '') ))
            {
                inputField.setCustomValidity('This field is required');
            }
            else
            {
                inputField.setCustomValidity(''); // Clear any previous error message
            }
            
            inputField.reportValidity(); // this will show the error message if the field is invalid
            if(!inputField.checkValidity())
            {
                allValid = false;
            }

        });
        return allValid;
    }

    async createTicket()
    {
        this.isLoading = true;
        let allValid = this.validateFields();
        debugger;
        //alert('allValid: ' + allValid);
        if(!allValid)
        {
            this.fireToastEvent({title: 'Error', message: 'Please check the error messages and try again.', variant: 'error'});
            this.isLoading = false;
            return;
        }

        try
        {
            
            let resp = await createTicketInFreshdesk({ticketData: this.ticketData});
            console.log(resp);

            const { status, statusCode, response } = resp;
            const {id} = response;
            // This part will execute only when successful response is received from the backend
            
            // Empty the form fields after successful ticket creation
            this.ticketData = {
                email: null,
                subject: null,
                description: null,
                status: null,
                priority: null
            }

            // show toast message on success
            this.fireToastEvent({title: 'Success', message: `Ticket created successfully in Freshdesk with ID: ${id}`, variant: 'success'});
        
        }
        catch(e)
        {
            debugger;
            //print the complete message
            console.error('Error creating ticket in Freshdesk: ', e);
            this.fireToastEvent({title: 'Error', message: `Error creating ticket in Freshdesk: ${e.body ? e.body.message : e.message}`, variant: 'error'});
        }
        finally
        {
            this.isLoading = false;
        }
    }

    fireToastEvent({ title, message, variant })
    {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}
