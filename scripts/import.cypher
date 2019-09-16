UNWIND [655,656,657,658,659,660,661,662,711, 669, 668, 667, 666, 664] AS division
LOAD CSV FROM "https://github.com/mneedham/graphing-brexit/raw/master/data/commonsvotes/Division" + division + ".csv" AS row
// Create motion nodes
WITH division, collect(row) AS rows
MERGE (motion:Motion {division: trim(split(rows[0][0], ":")[1]) })
SET motion.name = rows[2][0], 
    motion.date = date(datetime({epochmillis:apoc.date.parse(trim(split(rows[1][0], ":")[1]), "ms", "dd/MM/yyyy")}))
// Skip the first 6 rows as they have metadata we don't need
WITH motion, rows
UNWIND rows[7..] AS row
// Create person, party, constituency, and corresponding rels
MERGE (person:Person {name: row[0]})
MERGE (party:Party {name: row[1]})
MERGE (constituency:Constituency {name: row[2]})
MERGE (person)-[:MEMBER_OF]->(party)
MERGE (person)-[:REPRESENTS]->(constituency)
WITH person, motion,  
     CASE WHEN row[3] = "Aye" THEN "FOR" 
          WHEN row[3] = "No" THEN "AGAINST" 
          ELSE "DID_NOT_VOTE" END AS vote
CALL apoc.merge.relationship(person, vote, {}, {}, motion)
YIELD rel
RETURN count(*);

match (c:Constituency)
WHERE c.name contains "Ynys M"
SET c.name = "Ynys Mon";

match (p:Person)
WHERE p.name contains "Begley"
set p.name = "Órfhlaith Begley";

match (p:Party)
WHERE p.name contains "Sinn F"
SET p.name = "Sinn Féin";

load csv with headers from "https://github.com/mneedham/graphing-brexit/raw/master/data/pageviews.csv" AS row
MATCH (p:Person {name: row.person})
SET p.pageviews = toInteger(row.pageviews);

match (p:Person)-[:MEMBER_OF]->(pa:Party)
call apoc.create.addLabels(p, [apoc.text.replace(pa.name, " ", "")]) yield node
RETURN count(*);

call apoc.load.json("https://github.com/mneedham/graphing-brexit/raw/master/data/mp_events.json")
YIELD value
MATCH (person:Person {id: value.personId})
UNWIND value.parties AS party
MERGE (pa:Party {name: party.party})
MERGE (person)-[memberOf:MEMBER_OF {start: date(party.start)}]->(pa)
SET memberOf.end = date(party.end);