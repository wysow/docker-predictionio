#!/bin/bash

if [ ! -f /.dockerinit ]; then
  echo "*** NOTICE: Make sure you're running this from inside the Docker container! ***"
  exit 1
fi


echo "Step 1: Run PredictionIO"
runsvdir-start&

echo "EventServer may take a minute to start. Checking every 5s..."
while ! nc -vz localhost 7070;do sleep 5; done

pio status
echo "Step 1: Passed"


echo "Step 2. Create a new Engine from an Engine Template"

echo "Y" | pio template get PredictionIO/template-scala-parallel-similarproduct  SimilarProduct --name "none" --package "none" --email "none"
cd SimilarProduct

echo "Step 2: Passed"


echo "Step 3. Generate an App ID and Access Key"

#echo "YES" | pio app delete MyApp1
pio app new MyApp2 > log.txt
KEY=$(grep "Access Key:" log.txt | awk '{print $5}')
echo "KEY=$KEY"

pio app list
echo "Step 3: Passed"

echo "Step 4. Import Sample Data"

python data/import_eventserver.py --access_key $KEY
echo "Step 4: Passed"


echo "Step 5. Deploy the Engine as a Service"
sed -i "s|INVALID_APP_NAME|MyApp2|" /quickstartapp/SimilarProduct/engine.json

echo "Building...  It may take some time to download all the libraries."
pio build --verbose

echo "Taining..."
pio train

echo "You may now deploy engine by running cd /quickstartapp/SimilarProduct && pio deploy --ip 0.0.0.0"
