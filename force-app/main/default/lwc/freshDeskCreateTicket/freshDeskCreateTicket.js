import { api, track, LightningElement } from 'lwc';
import createTicketInFreshdesk from '@salesforce/apex/FreshdeskIntegrationBackend.createTicket';
import getAllTickets from '@salesforce/apex/FreshdeskIntegrationBackend.getAllTickets';
import generateTicketDetailsFromVoiceTranscriptUsingAi from '@salesforce/apex/FreshdeskIntegrationBackend.generateTicketDetailsFromVoiceTranscriptUsingAi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import TAILWIND_CSS from '@salesforce/resourceUrl/Tailwind2';
import CHART_JS from '@salesforce/resourceUrl/ChartJS';

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
    isRendered = false;
    isLoading = false;
    @track allTickets = [];
    @api pageTitle = 'Create Case in Freshdesk/SF (Fallback If Freshdesk is down)';
    statusOptions = STATUS_OPTIONS;
    priorityOptions = PRIORITY_OPTIONS;
    pieChart = null;
    barChart = null;
    transcript = '';
    recognition;
    isListening = false;
    @track ticketData = {
        email: null,
        subject: null,
        description: null,
        status: null,
        priority: null
    }

    get allTicketsTabLabel()
    {
        return `All Tickets (${this.allTickets.length})`;
    }

    
    connectedCallback() {
        
        Promise.all([loadScript(this, CHART_JS), loadStyle(this, TAILWIND_CSS)])
        .then(() => {
            console.log('Tailwind CSS and Chart.js loaded successfully');
        })
        .catch(error => {
            console.error('Error loading Tailwind CSS or Chart.js : ', error);
        });
        this.fetchTickets();
    }


    handleInputChange(event)
    {
        //debugger;
        const { name, value } = event.target;
        const numericFields = ['status', 'priority'];
        this.ticketData[name] = numericFields.includes(name) ? parseInt(value) : (value.trim() === '' ? null: value.trim());
    }

    handleTranscriptChange(event)
    {
        this.transcript = event.target.value;
    }


    validateFields(event)
    {
        //debugger;
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

        this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea').forEach(inputField => {
            
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
        //debugger;
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
            const {id, caseNumber} = response;
            // This part will execute only when successful response is received from the backend
            
            // Empty the form fields after successful ticket creation
            this.ticketData = {
                email: null,
                subject: null,
                description: null,
                status: null,
                priority: null
            }

            if(caseNumber)
            {
                //this.fireToastEvent({title: 'Success', message: `Ticket created successfully in Salesforce with Case Number: ${caseNumber}`, variant: 'success'});
                // show toast message with clickable case number link to case record page in salesforce
                const caseLink = `/lightning/r/Case/${id}/view`;
                
                const event = new ShowToastEvent({
                                    title: "Success!",
                                    variant: "success",
                                    mode: "sticky",
                                    message: "Ticket created successfully in {0} with {1}!",
                                    messageData: [
                                        "Salesforce",
                                        {
                                            url: caseLink,
                                            label: "Case Number: " + caseNumber,
                                        },
                                    ],
                                    });
                this.dispatchEvent(event);
            }
            else
            {
                this.fireToastEvent({title: 'Success', message: `Ticket created successfully in Freshdesk with ID: ${id}`, variant: 'success'});
            }
            this.fetchTickets(); // Refresh the tickets list after successful creation
            
        }
        catch(e)
        {
            //debugger;
            //print the complete message
            console.error('Error creating ticket in Freshdesk: ', e);
            this.fireToastEvent({title: 'Error', message: `Error creating ticket in Freshdesk: ${e.body ? e.body.message : e.message}`, variant: 'error'});
        }
        finally
        {
            this.isLoading = false;
        }
    }

    fireToastEvent({ title, message, variant, mode="" })
    {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(evt);
    }


    handleAllTicketsTabActive()
    {
        setTimeout(() => {
            this.renderChart();
        }, 0);
        this.dispatchEvent(evt);
    }


    handleAllTicketsTabActive()
    {
        setTimeout(() => {
            this.renderChart();
        }, 0)
    }

    async fetchTickets()
    {
        try
        {debugger;
            this.isLoading = true;
            const result = await getAllTickets();
            console.log('Fetched tickets: ', result);
            this.allTickets = result.tickets.map(eachTicket => {
                return({...eachTicket, 
                    id: eachTicket.caseNumber ? eachTicket.caseNumber : eachTicket.id,
                    priorityClass: this.getPriorityClass(eachTicket.priority), 
                    statusClass: this.getStatusClass(eachTicket.status),
                    created_at: new Intl.DateTimeFormat('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    }).format(new Date(eachTicket.created_at))
                });
            });
            this.renderChart(); // Refresh the chart after successful creation
            console.table(this.allTickets);
        }
        catch(e)
        {
            console.error(`Error occurred while fetching tickets: ${e?.body?.message}`);
        }
        finally
        {
            this.isLoading = false;
        }
    }


    getPriorityClass(priority)
    {
        switch (priority.toLowerCase()) {
        case "urgent":
            return 'bg-red-100 text-red-700 text-xs font-semibold px-3 py-1 rounded-full';
            break;
        case "high":
            return 'bg-red-100 text-red-700 text-xs font-semibold px-3 py-1 rounded-full';
            break;
        case "medium":
            return 'bg-yellow-100 text-yellow-700 text-xs font-semibold px-3 py-1 rounded-full';
            break;    
        default:
            return 'bg-green-100 text-green-700 text-xs font-semibold px-3 py-1 rounded-full';
        }
        
    }


    getStatusClass(status)
    {
        switch (status.toLowerCase()) {
        case "open":
            return 'bg-red-100 text-red-700 text-xs font-semibold px-3 py-1 rounded-full';
            break;
        case "pending":
            return 'bg-orange-100 text-orange-700 text-xs font-semibold px-3 py-1 rounded-full';
            break;
        case "resolved":
            return 'bg-green-100 text-green-700 text-xs font-semibold px-3 py-1 rounded-full';
            break; 
        case "closed":
            return 'bg-green-100 text-green-700 text-xs font-semibold px-3 py-1 rounded-full';
            break;        
        default:
            return 'bg-green-100 text-green-700 text-xs font-semibold px-3 py-1 rounded-full';
        }
        
    }

    renderChart()
    {
        if(this.pieChart)
        {
            this.pieChart.destroy();
        }

        if(this.barChart)
        {
            this.barChart.destroy();
        }
        
        const ctx1 = this.template.querySelector('.myPieChart');
        const ctx2 = this.template.querySelector('.myBarChart');

        if(!ctx1)
        {
            console.error('ctx chart component not found with class myPieChart');
            return;
        }

        if(!ctx2)
        {
            console.error('ctx chart component not found with class myBarChart');
            return;
        }

        let chartData = this.allTickets.reduce((acc, item) => {
            if(!acc[item.status])
            {
                acc[item.status] = 1;
            }
            else
            {
                acc[item.status] += 1;
            }
            return acc;
        }, {});

        let statusList = Object.keys(chartData);
        let statusCounts = Object.values(chartData);

        
       this.barChart = new Chart(ctx2, {
            type: 'bar',
            data: {
            labels: statusList,
            datasets: [{
                label: '# of Votes',
                data: statusCounts,
                borderWidth: 1
            }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                    beginAtZero: true
                    }
                }
            }
        });
        

        const data = {
            labels: statusList,
            datasets: [{
                label: 'Ticket(s)',
                data: statusCounts,
                backgroundColor: [
                'rgb(255, 99, 132)',
                'rgb(54, 162, 235)',
                'rgb(255, 205, 86)'
                ],
                hoverOffset: 4
            }]
            };
        this.pieChart = new Chart(ctx1, {
            type: 'doughnut',
            data
        });
    }



    startListening() {

        const SpeechRecognition =
            window.SpeechRecognition ||
            window.webkitSpeechRecognition;

        if (!SpeechRecognition) {

            this.fireToastEvent({
                title: 'Error',
                message: 'Speech Recognition is not supported in this browser.',
                variant: 'error'
            });

            return;
        }

        this.recognition = new SpeechRecognition();

        this.recognition.lang = 'en-IN';

        this.recognition.continuous = true; // Set to true if you want continuous recognition for eg. for long conversations

        this.recognition.interimResults = true; // Set to true if you want to get results as the user speaks, false will give results only after the user stops speaking

        this.isListening = true;

        this.recognition.onresult = (event) => {

            let text = '';

            for (let i = 0; i < event.results.length; i++) {

                text += event.results[i][0].transcript + ' ';
            }

            this.transcript = text;

        };

        this.recognition.onerror = (event) => {

            console.error(event);

            this.isListening = false;

        };

        this.recognition.onend = () => {

            this.isListening = false;

        };

        this.recognition.start();

    }



    stopListening() {

        if (this.recognition) {

            this.recognition.stop();

        }

    }


    async generateTicketDetailsFromTranscriptUsingAi() 
    {
        if(this.transcript?.trim() === '' || this.transcript === null || this.transcript === undefined)
        {
            return;
        }
            
        this.isLoading = true;
        
        try
        {
            const aiOutput = await generateTicketDetailsFromVoiceTranscriptUsingAi({ voiceTranscript: this.transcript});
            console.log('AIoutput: ', aiOutput);
            const { subject, description, confidence } = aiOutput;
            const { level, reason } = confidence;
            
            if(level?.toLowerCase() === 'low')
            {
                this.fireToastEvent({title: 'Low Confidence', message: `Ticket details could not be generated from voice transcript using AI due to LOW confidence level and reason: ${reason}`, variant: 'error', mode: 'sticky'});
            }
            else if(level?.toLowerCase() === 'medium')
            {
                this.fireToastEvent({title: 'Medium Confidence', message: `Ticket details generated from voice transcript using AI with confidence level: ${level} and reason: ${reason}`, variant: 'warning', mode: 'sticky'});
                this.ticketData = {...this.ticketData, subject, description};
            }
            else if(level?.toLowerCase() === 'high')
            {
                this.fireToastEvent({title: 'High Confidence', message: `Ticket details generated from voice transcript using AI with confidence level: ${level} and reason: ${reason}`, variant: 'success', mode: 'sticky'});
                this.ticketData = {...this.ticketData, subject, description};
            }
        }
        catch(error)
        {
            console.error('Error generating ticket details from voice transcript using AI: ', error);
            this.fireToastEvent({title: 'Error', message: `Error generating ticket details from voice transcript using AI: ${error.body ? error.body.message : error.message}`, variant: 'error'});
        }
        finally
        {
            this.isLoading = false;
        }
        
        
    }

    get isAiButtonDisabled()
    {
        if(this.transcript?.length > 5)
        {
            return false;
        }
        return true;
    } 

}
