run this command in terminal for loggin in to sf org using .env files

step 1 
source .env.prod ya fir source .env.dev

step 2 
sf org login jwt -f "$SF_KEY_FILE" --username "$SF_USERNAME" --instance-url "$SF_INSTANCE_URL" --client-id "$SF_CLIENT_ID" -a "$SF_ALIAS"
