import json
import glob
from dateutil import parser
from itertools import groupby

def aggregate_events(events):
    parties = [] 
    person_id = events[0]["person_id"]
    name = events[0]["full_name"]

    grouped_events = groupby(events, lambda row: row["party"])
    for party, events in grouped_events:
        events_list = list(events)
        event = {
            "party": party,
            "start": events_list[0]["entered_house"],            
        }

        if not events_list[-1]["left_house"].startswith("9999"):
            event["end"] = events_list[-1]["left_house"]

        parties.append(event)

    if not parties[0]["party"]:
        parties[1]["start"] = parties[0]["start"]
        parties = parties[1:]

    return {
        "personId": person_id,
        "name": name,
        "parties": parties
    }

if __name__ == '__main__':
    with open("data/mp_events.json", "w") as mp_events_file:
        for file_path in glob.glob("data/mps/*.json"):
            print(file_path)
            with open(file_path, "r", encoding = "ISO-8859-1") as mps_file:
                events = sorted(json.load(mps_file), key=lambda x: parser.parse(x["entered_house"]))
                parties = aggregate_events(events)
                print(parties)
                mp_events_file.write(f"{json.dumps(parties)}\n")

        # file_path = "data/mps/10257.json"
        # with open(file_path, "r", encoding = "ISO-8859-1") as mps_file:
        #     events = sorted(json.load(mps_file), key=lambda x: parser.parse(x["entered_house"]))
        #     print(events)
        #     parties = aggregate_events(events)
        #     print(parties)