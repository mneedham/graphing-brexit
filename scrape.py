from bs4 import BeautifulSoup
from neo4j import GraphDatabase

driver = GraphDatabase.driver("bolt://localhost", auth=("neo4j", "neo"))

with open("indicate-vote.html", "r") as file, driver.session() as session:
    soup = BeautifulSoup(file.read(), 'html.parser')
    motions = [m.text.strip() for m in soup.find_all("div", "key-list")[1:]]

    for index, motion in enumerate(motions):
        session.run("""
        MERGE (m:Motion {id: $id})
        SET m.name = $name
        """, {"id": index+1, "name": motion})

    for one_mp in  soup.find_all("div", class_="int-row--mp"):
        name = one_mp.find("div", "int-cell--name").text.strip()
        party = one_mp.find("div", "int-cell--party").text.strip()

        session.run("""
        MERGE (person:Person {name: $name})
        MERGE (party:Party {name: $party})
        MERGE (person)-[:MEMBER_OF]->(party)
        """, {"name": name, "party": party})

        votes = [item.get("class")
                 for item in one_mp.find_all("div", class_="gv-vote-blob")]
        for index, vote in enumerate(votes):
            v = [item for item in vote if item != "gv-vote-blob"][0].replace("gv-", "")
            print(index, v)

            if v == "for":
                session.run("""
                MATCH (person:Person {name: $name})
                MERGE (motion:Motion {id: $id})
                MERGE (person)-[:FOR]->(motion)
                """, {"name": name, "id": index+1})

            if v == "against":
                session.run("""
                MATCH (person:Person {name: $name})
                MERGE (motion:Motion {id: $id})
                MERGE (person)-[:AGAINST]->(motion)
                """, {"name": name, "id": index+1})

            if v == "did-not-vote":
                session.run("""
                MATCH (person:Person {name: $name})
                MERGE (motion:Motion {id: $id})
                MERGE (person)-[:DID_NOT_VOTE]->(motion)
                """, {"name": name, "id": index+1})
