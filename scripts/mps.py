import json
import neo4j

driver = neo4j.GraphDatabase.driver("bolt://localhost")

with open("mps_formatted.json") as mps_file, driver.session() as session:
    data = json.load(mps_file)
    for mp in data:
        print(mp)
        result = session.run("""
        MATCH (p:Person)
        WHERE p.name = $name
        SET p.id = $personId
        RETURN p
        """, {"name": mp["name"], "personId": mp["person_id"]})
        for row in result:
            print(row)
        print("")

with open("mps_20190301_formatted.json") as mps_file, driver.session() as session:
    data = json.load(mps_file)
    for mp in data:
        print(mp)
        result = session.run("""
        MATCH (p:Person)
        WHERE p.name = $name
        SET p.id = $personId
        RETURN p
        """, {"name": mp["name"], "personId": mp["person_id"]})
        for row in result:
            print(row)
        print("")        