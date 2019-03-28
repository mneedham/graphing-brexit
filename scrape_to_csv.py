from bs4 import BeautifulSoup
from neo4j import GraphDatabase
import csv

driver = GraphDatabase.driver("bolt://localhost", auth=("neo4j", "neo"))

map = {
    "for": "FOR",
    "against": "AGAINST",
    "did-not-vote": "DID_NOT_VOTE"
}

with open("indicate-vote.html", "r") as file, \
     open("data/motions.csv", "w") as motions_file, \
     open("data/mps.csv", "w") as mps_file, \
     open("data/votes.csv", "w") as votes_file, \
     driver.session() as session:
    motions_writer = csv.writer(motions_file, delimiter=",")
    mps_writer = csv.writer(mps_file, delimiter=",")
    votes_writer = csv.writer(votes_file, delimiter=",")

    motions_writer.writerow(["id", "name"])
    mps_writer.writerow(["mp", "party"])
    votes_writer.writerow(["person", "motionId", "vote"])

    soup = BeautifulSoup(file.read(), 'html.parser')
    motions = [m.text.strip() for m in soup.find_all("div", "key-list")[1:]]

    for index, motion in enumerate(motions):
        motions_writer.writerow([index+1, motion])


    for one_mp in  soup.find_all("div", class_="int-row--mp"):
        name = one_mp.find("div", "int-cell--name").text.strip()
        party = one_mp.find("div", "int-cell--party").text.strip()

        mps_writer.writerow([name, party])

        votes = [item.get("class") for item in one_mp.find_all("div", class_="gv-vote-blob")]
        for index, vote in enumerate(votes):
            v = [item for item in vote if item != "gv-vote-blob"][0].replace("gv-", "")
            print(index, v)

            votes_writer.writerow([name, index+1, map[v]])
