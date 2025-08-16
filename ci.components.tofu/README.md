The mediawiki-quickstart project's "Application Credentials" from Horizon are needed to use Tofu to manage its VPS instances

Get them here:

https://horizon.wikimedia.org/identity/application_credentials/

Use them to set these two vars in `ci.components.tofu/.env` (but don't commit them - they are secret!):
```bash
export OS_APPLICATION_CREDENTIAL_ID=""
export OS_APPLICATION_CREDENTIAL_SECRET=""
```

Once those vars are set, you can use the `./run` script to bring up a Tofu Docker environment synced with the mediawiki-quickstart project:
```bash
cd ci.components.tofu
./run
```

After `./run`, you can use `tofu` commands, but unless you are bringing up the VPS for the first time, you will likely want to run the `./generate_imports_file` script first:
```bash
./generate_imports_file   # This should intially show items to import, but no items to be changed - something like "Plan: 4 to import, 0 to add, 0 to change, 0 to destroy."
tofu apply                # Perform the imports mentioned in the comment above

tofu show        # Now Tofu can show the detailed view of the imported items
tofu state list  # Or a summary
```

You can then run more serious commands like:
```bash
tofu destroy   # Tear down and delete the instance and storage outlined in our `main.tf` ( THIS NUKES EVERYTHING! ) - Be sure after you destroy you also delete any `imports.tf`
tofu plan      # View changes which "tofu apply" would make ( if you made tweaks to `main.tf` )
tofu apply     # Make changes. If we've run `tofu destroy`, or destroyed our instance and volume in the Horizon web UI, this would bring it all back up from scratch!
```