import requests
import json
import os

key = os.environ["KEY"]


with open("mps_formatted.json") as mps_file:
    data = json.load(mps_file)
    for mp in data:
        person_id = mp["person_id"]
        if not os.path.exists(f"data/mps/{person_id}.json"):
            response = requests.get(f"https://www.theyworkforyou.com/api/getMP?id={person_id}&output=js&key={key}")
            print(response.json())

            with open(f"data/mps/{person_id}.json", mode='wb') as localfile:     
                localfile.write(response.content)

with open("mps_20190301_formatted.json") as mps_file:
    data = json.load(mps_file)
    for mp in data:
        person_id = mp["person_id"]
        if not os.path.exists(f"data/mps/{person_id}.json"):
            response = requests.get(f"https://www.theyworkforyou.com/api/getMP?id={person_id}&output=js&key={key}")
            print(response.json())

            with open(f"data/mps/{person_id}.json", mode='wb') as localfile:     
                localfile.write(response.content)

