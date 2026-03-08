# Kamal Deploy

Perform a Kamal deployment with the following steps:

## Steps

1. **Stop the running container on the remote server**
   - Read `.env` to get `KAMAL_SSH_USER` and `KAMAL_SERVER_IP`
   - SSH to the server and find the container running the `radiofreewaba/traveller` image:
     ```
     docker ps --filter "ancestor=radiofreewaba/traveller" -q
     ```
     Or use: `docker ps | grep radiofreewaba/traveller` to find the container ID
   - Stop that container with `docker stop <container_id>`
   - It's okay if no container is running

2. **Modify `.env` for deployment**
   - Comment out the `GENERATOR_SERVICE_URL` line (add `#` prefix if not already commented)
   - Uncomment the `RAILS_MASTER_KEY` line (remove `#` prefix if commented)

3. **Run the Kamal deploy**
   - Execute: `bin/kamal deploy`

4. **Restore `.env` after deployment**
   - Uncomment the `GENERATOR_SERVICE_URL` line (remove `#` prefix)
   - Comment out the `RAILS_MASTER_KEY` line (add `#` prefix)

**Important**: Always restore the `.env` file even if the deploy fails.
