
To debug or develop locally:

Ensure pwd is the `mediawiki-quickstart` dir:

```bash
cd ~/mediawiki-quickstart
```

Bring up the `ci.components` container:

```bash
docker compose -f ci.components/docker-compose.yml up
```

Create fake results (so you don't have to wait for complete runs when tweaking the UI locally):

```bash
FAKE_IT=1 ./ci.components/run_all
```

Optionally you can override where results are saved to and served from (usually not needed for local dev):

```bash
RESULTS_PATH=/var/log/selenium-results ./run_all
```

Open the results url (refresh the url if you create more fake run results to see them):

```bash
http://localhost:8088
```